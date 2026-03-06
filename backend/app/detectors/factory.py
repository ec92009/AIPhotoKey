from __future__ import annotations

from .fallback import FallbackDetector
from .ultralytics_detector import UltralyticsDetector


def create_detector(model_id: str, progress_callback=None):
    try:
        return UltralyticsDetector(model_id, progress_callback=progress_callback)
    except Exception:
        return FallbackDetector()
