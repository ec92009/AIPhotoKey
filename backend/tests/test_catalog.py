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
    from app import catalog as catalog_module

    image_dir = tmp_path / "images"
    image_dir.mkdir()
    for index in range(2):
        image = Image.new("RGB", (640, 480), color=(index * 40, 100, 140))
        image.save(image_dir / f"sample-{index}.jpg")

    class StubDetector:
        status = "metadata-only"
        ready_message = "Metadata-only mode ready. Starting file-by-file scan."

        def detect(self, image_path: Path, min_confidence: float):
            return []

    monkeypatch.setattr(catalog_module, "create_detector", lambda *args, **kwargs: StubDetector())

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


def test_caption_generator_retries_for_broken_english(monkeypatch):
    from app import captioning
    from app.captioning import CaptionGenerator

    generator = CaptionGenerator()
    attempts = iter([
        "arafed woman walking down a narrow street with a backpack",
        "a woman walking down a narrow street with a backpack",
    ])

    monkeypatch.setattr(captioning, "load_image", lambda path: Image.new("RGB", (16, 16), color=(0, 0, 0)))
    monkeypatch.setattr(generator, "_get_model", lambda model_id: (object(), object(), "cpu"))
    monkeypatch.setattr(generator, "_generate_once", lambda *args, **kwargs: next(attempts))

    caption, retried, issues = generator.generate(Path("sample.jpg"), "blip-base")

    assert caption == "a woman walking down a narrow street with a backpack"
    assert retried is True
    assert issues == []


def test_caption_generator_accepts_clean_caption_without_retry(monkeypatch):
    from app import captioning
    from app.captioning import CaptionGenerator

    generator = CaptionGenerator()
    monkeypatch.setattr(captioning, "load_image", lambda path: Image.new("RGB", (16, 16), color=(0, 0, 0)))
    monkeypatch.setattr(generator, "_get_model", lambda model_id: (object(), object(), "cpu"))
    monkeypatch.setattr(
        generator,
        "_generate_once",
        lambda *args, **kwargs: "a man riding a bike down a city street",
    )

    caption, retried, issues = generator.generate(Path("sample.jpg"), "blip-base")

    assert caption == "a man riding a bike down a city street"
    assert retried is False
    assert issues == []


def test_caption_generator_stops_retrying_when_canceled(monkeypatch):
    from app import captioning
    from app.captioning import CaptionGenerator

    generator = CaptionGenerator()
    monkeypatch.setattr(captioning, "load_image", lambda path: Image.new("RGB", (16, 16), color=(0, 0, 0)))
    monkeypatch.setattr(generator, "_get_model", lambda model_id: (object(), object(), "cpu"))
    monkeypatch.setattr(
        generator,
        "_generate_once",
        lambda *args, **kwargs: "arafed woman walking down a narrow street with a backpack",
    )

    cancel_state = {"count": 0}

    def cancel_callback():
        cancel_state["count"] += 1
        return cancel_state["count"] > 1

    try:
        generator.generate(Path("sample.jpg"), "blip-base", cancel_callback=cancel_callback)
        assert False, "Expected caption generation to be interrupted"
    except InterruptedError as exc:
        assert str(exc) == "Caption run canceled."
