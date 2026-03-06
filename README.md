# AIPhotoKey

AIPhotoKey now targets a `Python + TypeScript` architecture instead of Swift. The repository contains a FastAPI backend for scanning and indexing photo libraries and a React/Vite frontend for browsing the resulting catalog.

## Stack

- `backend/`: FastAPI, SQLite, Pillow
- `frontend/`: React, TypeScript, Vite
- `AIPhotoKey/`, `Sources/`, `AIPhotoKey.xcodeproj`: legacy Swift implementation kept as reference while the new stack is built out

## Current Capabilities

- Recursive photo-library scans into SQLite
- Standard image support: `jpg`, `jpeg`, `png`, `heic`, `heif`, `gif`, `tiff`, `tif`, `bmp`, `webp`
- RAW image support: `raw`, `cr2`, `cr3`, `nef`, `arw`, `dng`, `orf`, `rw2`, `pef`, `srw`, `raf`, `x3f`
- Multiple model families exposed in the UI and API: `YOLOv8`, `YOLO11`, and `YOLO26` in `n/s/m/l/x` sizes
- Confidence-threshold control
- Object summary view grouped from detections
- Photo grid with on-demand thumbnails
- Optional Ultralytics integration when installed

The backend works without AI dependencies. In that mode it still indexes photos and metadata but records no detections. Installing the optional AI extra enables YOLO-based tagging.

## Quick Start

### Backend

```bash
cd backend
uv sync --extra dev
uv run uvicorn app.main:app --reload
```

The API starts on `http://127.0.0.1:8000`.

### Frontend

```bash
cd frontend
npm install
npm run dev
```

The app starts on `http://127.0.0.1:5173` and proxies API requests to the backend.

## Optional AI Setup

Install the backend with the `ai` extra:

```bash
cd backend
uv sync --extra dev --extra ai
```

This enables the Ultralytics detector. If the dependency is absent, scans complete with photo metadata only.

## API Overview

- `GET /api/health`
- `GET /api/models`
- `GET /api/summary`
- `GET /api/objects`
- `GET /api/photos`
- `GET /api/photos/{photo_id}/thumbnail`
- `POST /api/scans`
- `DELETE /api/catalog`

## Testing

```bash
cd backend
uv run pytest

cd ../frontend
npm run build
```

## Notes

- The catalog database defaults to `backend/data/catalog.db`.
- Downloaded Ultralytics weights live in `weights/`.
- The new app accepts direct filesystem paths such as `~/Pictures`.
- Legacy Swift sources remain in the repo for behavior reference only and are no longer the active implementation path.
