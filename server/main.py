"""
Kids Coloring Image Browser - Backend API
FastAPI server that serves coloring images from the images/ directory.
"""

import os
import re
import httpx
from pathlib import Path
from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from openai import OpenAI
from PIL import Image

# OpenAI configuration - reads OPENAI_API_KEY from environment automatically
openai_client = OpenAI()

app = FastAPI(
    title="Coloring Book API",
    description="API for browsing and serving coloring images",
    version="1.0.0"
)

# CORS middleware for iOS app access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration
# Priority: 1) /var/lib/coloringbook/images, 2) COLORINGBOOK_IMAGES_DIR env var, 3) ./images for development
_PRODUCTION_PATH = Path("/var/lib/coloringbook/images")
if _PRODUCTION_PATH.exists():
    IMAGES_DIR = _PRODUCTION_PATH
elif os.environ.get("COLORINGBOOK_IMAGES_DIR"):
    IMAGES_DIR = Path(os.environ["COLORINGBOOK_IMAGES_DIR"])
else:
    IMAGES_DIR = Path(__file__).parent / "images"
THUMBNAILS_DIR = IMAGES_DIR / "thumbnails"
THUMBNAIL_SIZE = (400, 400)
SUPPORTED_EXTENSIONS = {".png", ".jpg", ".jpeg", ".pdf"}


class ColoringImage(BaseModel):
    id: str
    filename: str
    title: str
    url: str
    thumbnailUrl: str | None = None


class ImagesResponse(BaseModel):
    images: list[ColoringImage]


class HealthResponse(BaseModel):
    status: str
    images_count: int


class GenerateImageRequest(BaseModel):
    prompt: str


class GenerateImageResponse(BaseModel):
    image: ColoringImage


def get_image_title(filename: str) -> str:
    """Convert filename to display title."""
    name = Path(filename).stem
    # Replace hyphens/underscores with spaces and title case
    return name.replace("-", " ").replace("_", " ").title()


def ensure_thumbnail(image_path: Path) -> str | None:
    """Generate thumbnail if needed, return thumbnail URL or None."""
    if image_path.suffix.lower() == ".pdf":
        return None  # Skip PDFs for now

    THUMBNAILS_DIR.mkdir(parents=True, exist_ok=True)
    thumbnail_path = THUMBNAILS_DIR / image_path.name

    # Check if thumbnail needs to be (re)generated
    needs_generation = (
        not thumbnail_path.exists() or
        thumbnail_path.stat().st_mtime < image_path.stat().st_mtime
    )

    if needs_generation:
        try:
            with Image.open(image_path) as img:
                # Handle RGBA/transparency by compositing on white background
                if img.mode in ("RGBA", "LA", "P"):
                    background = Image.new("RGB", img.size, (255, 255, 255))
                    if img.mode == "P":
                        img = img.convert("RGBA")
                    background.paste(img, mask=img.split()[-1] if img.mode == "RGBA" else None)
                    img = background
                elif img.mode != "RGB":
                    img = img.convert("RGB")

                img.thumbnail(THUMBNAIL_SIZE, Image.Resampling.LANCZOS)
                img.save(thumbnail_path, "PNG", optimize=True)
        except Exception as e:
            print(f"Failed to generate thumbnail for {image_path}: {e}")
            return None

    return f"/thumbnails/{image_path.name}"


@app.get("/api/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint."""
    images = list(IMAGES_DIR.glob("*"))
    image_count = sum(1 for f in images if f.suffix.lower() in SUPPORTED_EXTENSIONS)
    return HealthResponse(status="healthy", images_count=image_count)


@app.get("/api/images", response_model=ImagesResponse)
async def list_images(request_host: str = None):
    """List all available coloring images."""
    from starlette.requests import Request
    images = []

    if not IMAGES_DIR.exists():
        IMAGES_DIR.mkdir(parents=True, exist_ok=True)

    for file_path in sorted(IMAGES_DIR.iterdir()):
        if file_path.is_file() and file_path.suffix.lower() in SUPPORTED_EXTENSIONS:
            image_id = file_path.stem
            thumbnail_url = ensure_thumbnail(file_path)
            images.append(ColoringImage(
                id=image_id,
                filename=file_path.name,
                title=get_image_title(file_path.name),
                url=f"/images/{file_path.name}",
                thumbnailUrl=thumbnail_url
            ))

    return ImagesResponse(images=images)


def sanitize_filename(prompt: str) -> str:
    """Convert prompt to a safe filename."""
    # Take first 50 chars, lowercase, replace spaces with hyphens
    name = prompt[:50].lower().strip()
    # Remove non-alphanumeric characters except spaces and hyphens
    name = re.sub(r'[^a-z0-9\s-]', '', name)
    # Replace spaces with hyphens
    name = re.sub(r'\s+', '-', name)
    # Remove multiple consecutive hyphens
    name = re.sub(r'-+', '-', name)
    return name.strip('-')


@app.post("/api/generate", response_model=GenerateImageResponse)
async def generate_image(request: GenerateImageRequest):
    """Generate a new coloring image using DALL-E 3."""
    if not request.prompt.strip():
        raise HTTPException(status_code=400, detail="Prompt cannot be empty")

    # Enhance prompt for coloring book style
    enhanced_prompt = (
        f"A simple children's coloring book page of {request.prompt}. "
        "Black line art on pure white background. Clean outlines, no shading, "
        "no gray tones, no colors. Simple shapes suitable for kids to color in."
    )

    try:
        # Generate image with DALL-E 3
        response = openai_client.images.generate(
            model="dall-e-3",
            prompt=enhanced_prompt,
            size="1024x1024",
            quality="standard",
            n=1,
        )

        image_url = response.data[0].url

        # Download the generated image
        async with httpx.AsyncClient() as client:
            image_response = await client.get(image_url)
            image_response.raise_for_status()
            image_data = image_response.content

        # Save to images directory
        base_filename = sanitize_filename(request.prompt)
        filename = f"{base_filename}.png"
        file_path = IMAGES_DIR / filename

        # Handle duplicates by appending a number
        counter = 1
        while file_path.exists():
            filename = f"{base_filename}-{counter}.png"
            file_path = IMAGES_DIR / filename
            counter += 1

        file_path.write_bytes(image_data)

        # Generate thumbnail for the new image
        thumbnail_url = ensure_thumbnail(file_path)

        # Return the new image metadata
        image_id = file_path.stem
        new_image = ColoringImage(
            id=image_id,
            filename=filename,
            title=get_image_title(filename),
            url=f"/images/{filename}",
            thumbnailUrl=thumbnail_url
        )

        return GenerateImageResponse(image=new_image)

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate image: {str(e)}")


# Mount static files for serving images and thumbnails
# This must be after the API routes
if not IMAGES_DIR.exists():
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)
if not THUMBNAILS_DIR.exists():
    THUMBNAILS_DIR.mkdir(parents=True, exist_ok=True)

app.mount("/thumbnails", StaticFiles(directory=str(THUMBNAILS_DIR)), name="thumbnails")
app.mount("/images", StaticFiles(directory=str(IMAGES_DIR)), name="images")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
