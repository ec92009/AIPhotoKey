from __future__ import annotations

from pathlib import Path
import shutil
from typing import List

from app.config import settings
from app.image_loader import load_image

from .base import Detection

try:
    from ultralytics import YOLO
except ImportError:  # pragma: no cover
    YOLO = None


class UltralyticsDetector:
    def __init__(self, model_id: str, progress_callback=None) -> None:
        if YOLO is None:
            raise RuntimeError("Ultralytics is not installed.")
        self._model_path = settings.weights_dir / f"{model_id}.pt"
        self.was_cached = self._model_path.exists()
        if progress_callback:
            progress_callback("Preparing detection model...", 0.1)
        model_source = str(self._model_path) if self.was_cached else f"{model_id}.pt"
        if progress_callback:
            progress_callback(
                "Using cached detection model." if self.was_cached else "Downloading/loading detection model weights...",
                0.35,
            )
        self._model = YOLO(model_source)
        if not self.was_cached:
            downloaded_path = Path(f"{model_id}.pt")
            if downloaded_path.exists() and downloaded_path.resolve() != self._model_path.resolve():
                shutil.move(str(downloaded_path), str(self._model_path))
        self.status = "ultralytics"
        self.load_message = "Downloading/loading detection model. First run may download hundreds of MB and take a while..."
        self.ready_message = (
            "Detection model already cached. Starting file-by-file scan..."
            if self.was_cached
            else "Detection model ready. Starting file-by-file scan..."
        )
        self.phase_progress = 1.0
        if progress_callback:
            progress_callback(self.ready_message, 1.0)

    def detect(self, image_path: Path, min_confidence: float) -> List[Detection]:
        image = load_image(image_path)
        results = self._model.predict(image, conf=min_confidence, verbose=False)
        detections: List[Detection] = []

        for result in results:
            if result.boxes is None:
                continue
            names = result.names
            for box in result.boxes:
                confidence = float(box.conf[0])
                class_id = int(box.cls[0])
                label = str(names[class_id])
                detections.append(Detection(label=label, confidence=confidence, source="ultralytics"))

        return detections
