from __future__ import annotations

from pathlib import Path
from typing import List

from .base import Detection


class FallbackDetector:
    status = "metadata-only"
    load_message = "Ultralytics unavailable. Falling back to metadata-only scan."
    ready_message = "Metadata-only mode ready. Starting file-by-file scan."
    phase_progress = 1.0

    def detect(self, image_path: Path, min_confidence: float) -> List[Detection]:
        return []
