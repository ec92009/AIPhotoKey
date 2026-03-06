from __future__ import annotations

from pathlib import Path
import subprocess
import time

from fastapi.testclient import TestClient
import numpy as np
from PIL import Image


def test_scan_and_summary(tmp_path: Path, monkeypatch):
    data_dir = tmp_path / "data"
    monkeypatch.setenv("AIPHOTO_KEY_DATA_DIR", str(data_dir))
    monkeypatch.setenv("AIPHOTO_KEY_DB_PATH", str(data_dir / "catalog.db"))

    from app.main import app

    image_dir = tmp_path / "images"
    image_dir.mkdir()
    for index in range(2):
        image = Image.new("RGB", (640, 480), color=(index * 40, 100, 140))
        image.save(image_dir / f"sample-{index}.jpg")

    client = TestClient(app)
    response = client.post(
        "/api/scans",
        json={
            "source_path": str(image_dir),
            "model_id": "yolov8n",
            "min_confidence": 0.5,
            "clear_existing": True,
        },
    )
    assert response.status_code == 200
    job_id = response.json()["job_id"]

    payload = None
    for _ in range(50):
        status = client.get(f"/api/scans/{job_id}")
        assert status.status_code == 200
        payload = status.json()
        if payload["state"] == "completed":
            break
        time.sleep(0.05)

    assert payload is not None
    assert payload["result"]["imported_photos"] == 2

    summary = client.get("/api/summary")
    assert summary.status_code == 200
    assert summary.json()["photo_count"] == 2

    photos = client.get("/api/photos")
    assert photos.status_code == 200
    assert len(photos.json()) == 2


def test_pick_folder_endpoint(monkeypatch):
    from app.main import app

    def fake_run(*args, **kwargs):
        return subprocess.CompletedProcess(args=args, returncode=0, stdout="/Users/ecohen/Pictures\n", stderr="")

    monkeypatch.setattr(subprocess, "run", fake_run)

    client = TestClient(app)
    response = client.post("/api/system/pick-folder")
    assert response.status_code == 200
    assert response.json() == {"path": "/Users/ecohen/Pictures"}


def test_raw_image_loader_uses_rawpy(monkeypatch, tmp_path: Path):
    from app import image_loader

    class FakeRaw:
        def __enter__(self):
            return self

        def __exit__(self, exc_type, exc, tb):
            return False

        def postprocess(self, use_camera_wb=True):
            return np.array([
                [[255, 0, 0], [0, 255, 0]],
                [[0, 0, 255], [255, 255, 255]],
            ], dtype=np.uint8)

    class FakeRawPy:
        @staticmethod
        def imread(path: str):
            assert path.endswith(".dng")
            return FakeRaw()

    monkeypatch.setattr(image_loader, "rawpy", FakeRawPy())

    image_path = tmp_path / "sample.dng"
    image_path.write_bytes(b"fake-raw")
    image = image_loader.load_image(image_path)
    assert image.size == (2, 2)
