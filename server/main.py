"""
Kids Coloring Image Browser - Backend API
FastAPI server that serves coloring images from the images/ directory.
"""

import base64
import json
import os
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional
from fastapi import FastAPI, HTTPException, Query
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
from openai import AsyncOpenAI
from PIL import Image

# OpenAI configuration - reads OPENAI_API_KEY from environment automatically
# Use AsyncOpenAI to avoid blocking the event loop during image generation
openai_client = AsyncOpenAI()

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
METADATA_FILE = IMAGES_DIR / "metadata.json"
THUMBNAIL_SIZE = (400, 400)


class ColoringImage(BaseModel):
    id: str
    filename: str
    title: str
    prompt: Optional[str] = None
    url: str
    thumbnailUrl: Optional[str] = None
    created: Optional[str] = None


class ImagesResponse(BaseModel):
    images: list[ColoringImage]


class HealthResponse(BaseModel):
    status: str
    images_count: int


class GenerateImageRequest(BaseModel):
    prompt: str


class GenerateImageResponse(BaseModel):
    image: ColoringImage


class SearchResponse(BaseModel):
    images: list[ColoringImage]
    query: str
    total: int


def load_metadata() -> dict:
    """Load metadata from JSON file."""
    if METADATA_FILE.exists():
        try:
            with open(METADATA_FILE, "r") as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return {}
    return {}


def save_metadata(metadata: dict) -> None:
    """Save metadata to JSON file."""
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)
    with open(METADATA_FILE, "w") as f:
        json.dump(metadata, f, indent=2)


def get_image_title(prompt: str) -> str:
    """Convert prompt to display title."""
    return prompt.strip().title()


def ensure_thumbnail(image_path: Path) -> Optional[str]:
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


def build_coloring_image(image_id: str, meta: dict) -> Optional[ColoringImage]:
    """Build a ColoringImage from metadata, ensuring file exists."""
    file_path = IMAGES_DIR / meta["filename"]
    if not file_path.exists():
        return None

    thumbnail_url = ensure_thumbnail(file_path)
    return ColoringImage(
        id=image_id,
        filename=meta["filename"],
        title=meta["title"],
        prompt=meta.get("prompt"),
        url=f"/images/{meta['filename']}",
        thumbnailUrl=thumbnail_url,
        created=meta.get("created")
    )


@app.get("/api/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint."""
    metadata = load_metadata()
    return HealthResponse(status="healthy", images_count=len(metadata))


@app.get("/api/images", response_model=ImagesResponse)
async def list_images():
    """List all available coloring images."""
    if not IMAGES_DIR.exists():
        IMAGES_DIR.mkdir(parents=True, exist_ok=True)

    metadata = load_metadata()

    images = []
    for image_id, meta in sorted(metadata.items(), key=lambda x: x[1].get("created", ""), reverse=True):
        image = build_coloring_image(image_id, meta)
        if image:
            images.append(image)

    return ImagesResponse(images=images)


@app.get("/api/search", response_model=SearchResponse)
async def search_images(q: str = Query(..., min_length=1, description="Search query")):
    """Search images by prompt/title."""
    metadata = load_metadata()
    query_lower = q.lower()

    images = []
    for image_id, meta in metadata.items():
        prompt = meta.get("prompt", "").lower()
        title = meta.get("title", "").lower()

        if query_lower in prompt or query_lower in title:
            image = build_coloring_image(image_id, meta)
            if image:
                images.append(image)

    # Sort by created date, newest first
    images.sort(key=lambda x: x.created or "", reverse=True)

    return SearchResponse(images=images, query=q, total=len(images))


@app.post("/api/generate", response_model=GenerateImageResponse)
async def generate_image(request: GenerateImageRequest):
    """Generate a new coloring image using DALL-E 3."""
    if not request.prompt.strip():
        raise HTTPException(status_code=400, detail="Prompt cannot be empty")

    # Enhance prompt for coloring book style
    enhanced_prompt = (
        f"Create a children's coloring-book page illustration of: {request.prompt}.\n"
        "Style: black ink line art only, pure white background, simple clean outlines, "
        "vector-like flat 2D, not photorealistic.\n"
        "Coloring-book constraints: no shading, no hatching, no stippling, no gradients, "
        "no gray, no color.\n"
        "Line quality: smooth continuous strokes, medium-thick consistent line weight, "
        "closed shapes where appropriate, minimal tiny details (easy to color).\n"
        "Composition: single page, portrait, centered subject, fills most of the frame, "
        "clear silhouette, ample white space inside shapes for coloring.\n"
        "Exclusions: no background scene, no setting props, no table, no frame/border, "
        "no text, no watermark, no pencils/crayons/hands, no shadows."
    )

    try:
        # Generate image with gpt-image-1.5
        # Using low quality for cost savings - sufficient for line art coloring pages
        response = await openai_client.images.generate(
            model="gpt-image-1.5",
            prompt=enhanced_prompt,
            size="1024x1024",  # Square format for cost savings
            quality="low",
            output_format="png",
            n=1,
        )

        # gpt-image-1.5 always returns base64
        image_data = base64.b64decode(response.data[0].b64_json)

        # Generate UUID-based filename
        image_id = uuid.uuid4().hex[:12]
        filename = f"{image_id}.png"
        file_path = IMAGES_DIR / filename

        # Ensure directory exists and save image
        IMAGES_DIR.mkdir(parents=True, exist_ok=True)
        file_path.write_bytes(image_data)

        # Generate thumbnail
        thumbnail_url = ensure_thumbnail(file_path)

        # Create metadata entry
        created = datetime.now(timezone.utc).isoformat()
        title = get_image_title(request.prompt)

        metadata = load_metadata()
        metadata[image_id] = {
            "filename": filename,
            "prompt": request.prompt.strip(),
            "title": title,
            "created": created
        }
        save_metadata(metadata)

        # Return the new image
        new_image = ColoringImage(
            id=image_id,
            filename=filename,
            title=title,
            prompt=request.prompt.strip(),
            url=f"/images/{filename}",
            thumbnailUrl=thumbnail_url,
            created=created
        )

        return GenerateImageResponse(image=new_image)

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate image: {str(e)}")


@app.get("/privacy", response_class=HTMLResponse)
async def privacy_policy():
    """Serve the privacy policy page."""
    privacy_file = Path(__file__).parent / "privacy.html"
    return privacy_file.read_text()


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
