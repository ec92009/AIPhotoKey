from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import List, Protocol


@dataclass
class Detection:
    label: str
    confidence: float
    source: str


class Detector(Protocol):
    @property
    def status(self) -> str:
        ...

    def detect(self, image_path: Path, min_confidence: float) -> List[Detection]:
        ...
