"""
Kids Coloring Image Browser - Backend API
FastAPI server that serves coloring images from the images/ directory.
"""

import json
import os
import httpx
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional
from fastapi import FastAPI, HTTPException, Query
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
METADATA_FILE = IMAGES_DIR / "metadata.json"
THUMBNAIL_SIZE = (400, 400)
SUPPORTED_EXTENSIONS = {".png", ".jpg", ".jpeg", ".pdf"}


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


def migrate_legacy_images(metadata: dict) -> dict:
    """Add any images on disk that aren't in metadata (legacy migration)."""
    if not IMAGES_DIR.exists():
        return metadata

    changed = False
    for file_path in IMAGES_DIR.iterdir():
        if file_path.is_file() and file_path.suffix.lower() in SUPPORTED_EXTENSIONS:
            image_id = file_path.stem
            if image_id not in metadata:
                # Legacy image without metadata - create entry from filename
                legacy_title = image_id.replace("-", " ").replace("_", " ").title()
                metadata[image_id] = {
                    "filename": file_path.name,
                    "prompt": legacy_title,  # Use title as prompt for legacy images
                    "title": legacy_title,
                    "created": datetime.fromtimestamp(
                        file_path.stat().st_mtime, tz=timezone.utc
                    ).isoformat()
                }
                changed = True

    if changed:
        save_metadata(metadata)

    return metadata


def build_coloring_image(image_id: str, meta: dict) -> Optional[ColoringImage]:
    """Build a ColoringImage from metadata, ensuring file exists."""
    file_path = IMAGES_DIR / meta["filename"]
    if not file_path.exists():
        return None

    thumbnail_url = ensure_thumbnail(file_path)
    return ColoringImage(
        id=image_id,
        filename=meta["filename"],
        title=meta.get("title", meta.get("prompt", image_id)),
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
    metadata = migrate_legacy_images(metadata)

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
        f"A children's coloring book illustration of {request.prompt}. "
        "Black line art only on solid white background. "
        "Clean simple outlines, no shading, no gradients, no gray tones, no colors. "
        "Vector style, flat 2D illustration, not a photograph. "
        "Do not show the page on a table, do not include pencils, crayons, hands, "
        "or any background elements. Just the line drawing itself, filling the frame."
    )

    try:
        # Generate image with DALL-E 3
        response = openai_client.images.generate(
            model="gpt-image-1.5",
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
