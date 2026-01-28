"""
Kids Coloring Image Browser - Backend API
FastAPI server that serves coloring images from the images/ directory.
"""

import os
from pathlib import Path
from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

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
# Use COLORINGBOOK_IMAGES_DIR env var for production, fallback to ./images for development
IMAGES_DIR = Path(os.environ.get("COLORINGBOOK_IMAGES_DIR", Path(__file__).parent / "images"))
SUPPORTED_EXTENSIONS = {".png", ".jpg", ".jpeg", ".pdf"}


class ColoringImage(BaseModel):
    id: str
    filename: str
    title: str
    url: str


class ImagesResponse(BaseModel):
    images: list[ColoringImage]


class HealthResponse(BaseModel):
    status: str
    images_count: int


def get_image_title(filename: str) -> str:
    """Convert filename to display title."""
    name = Path(filename).stem
    # Replace hyphens/underscores with spaces and title case
    return name.replace("-", " ").replace("_", " ").title()


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
        if file_path.suffix.lower() in SUPPORTED_EXTENSIONS:
            image_id = file_path.stem
            images.append(ColoringImage(
                id=image_id,
                filename=file_path.name,
                title=get_image_title(file_path.name),
                url=f"/images/{file_path.name}"
            ))

    return ImagesResponse(images=images)


# Mount static files for serving images
# This must be after the API routes
if not IMAGES_DIR.exists():
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)

app.mount("/images", StaticFiles(directory=str(IMAGES_DIR)), name="images")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
