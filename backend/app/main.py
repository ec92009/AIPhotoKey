from __future__ import annotations

import subprocess
from typing import Any, Optional

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response

from .catalog import CatalogService
from .catalog import ScanManager
from .captioning import CaptionManager
from .config import settings
from .database import initialize
from .models import SUPPORTED_CAPTION_MODELS, SUPPORTED_MODELS, CaptionRequest, ScanRequest


initialize(settings.database_path)
app = FastAPI(title=settings.app_name)
app.add_middleware(
    CORSMiddleware,
    allow_origins=list(settings.allowed_origins),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

catalog = CatalogService()
scan_manager = ScanManager(catalog)
caption_manager = CaptionManager(catalog)


@app.get("/api/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/api/system/pick-folder")
def pick_folder() -> dict[str, str]:
    script = 'POSIX path of (choose folder with prompt "Select the photo library folder")'
    try:
        result = subprocess.run(
            ["osascript", "-e", script],
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as exc:
        error_message = (exc.stderr or exc.stdout or "").strip().lower()
        if "user canceled" in error_message:
            raise HTTPException(status_code=409, detail="Folder selection canceled.") from exc
        raise HTTPException(status_code=500, detail="Unable to open the macOS folder picker.") from exc

    selected_path = result.stdout.strip()
    if not selected_path:
        raise HTTPException(status_code=500, detail="Folder picker returned an empty path.")
    return {"path": selected_path}


@app.get("/api/models")
def list_models() -> list[dict[str, Any]]:
    return SUPPORTED_MODELS


@app.get("/api/caption-models")
def list_caption_models() -> list[dict[str, Any]]:
    return SUPPORTED_CAPTION_MODELS


@app.get("/api/summary")
def summary():
    return catalog.summary()


@app.get("/api/objects")
def objects():
    return catalog.list_objects()


@app.get("/api/photos")
def photos(
    object_label: Optional[str] = Query(default=None),
    limit: int = Query(default=120, ge=1, le=1000),
):
    return catalog.list_photos(object_label=object_label, limit=limit)


@app.get("/api/photos/{photo_id}/thumbnail")
def thumbnail(photo_id: int, size: int = Query(default=settings.thumbnail_size, ge=64, le=1024)):
    try:
        payload = catalog.thumbnail_bytes(photo_id, size=size)
    except FileNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return Response(content=payload, media_type="image/jpeg")


@app.post("/api/scans")
def start_scan(request: ScanRequest):
    return scan_manager.start_scan(request)


@app.get("/api/scans/{job_id}")
def get_scan(job_id: str):
    try:
        return scan_manager.get_job(job_id)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="Scan job not found.") from exc


@app.post("/api/scans/{job_id}/cancel")
def cancel_scan(job_id: str):
    try:
        return scan_manager.cancel_job(job_id)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="Scan job not found.") from exc


@app.post("/api/captions")
def start_caption_run(request: CaptionRequest):
    return caption_manager.start_caption_run(request)


@app.get("/api/captions/{job_id}")
def get_caption_job(job_id: str):
    try:
        return caption_manager.get_job(job_id)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="Caption job not found.") from exc


@app.post("/api/captions/{job_id}/cancel")
def cancel_caption_job(job_id: str):
    try:
        return caption_manager.cancel_job(job_id)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="Caption job not found.") from exc


@app.delete("/api/catalog", status_code=204)
def clear_catalog():
    catalog.clear_catalog()
    return Response(status_code=204)
