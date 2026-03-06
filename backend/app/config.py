from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Settings:
    app_name: str = "AIPhotoKey API"
    data_dir: Path = Path(os.getenv("AIPHOTO_KEY_DATA_DIR", Path(__file__).resolve().parents[1] / "data"))
    database_path: Path = Path(
        os.getenv("AIPHOTO_KEY_DB_PATH", Path(__file__).resolve().parents[1] / "data" / "catalog.db")
    )
    weights_dir: Path = Path(
        os.getenv("AIPHOTO_KEY_WEIGHTS_DIR", Path(__file__).resolve().parents[2] / "weights")
    )
    thumbnail_size: int = int(os.getenv("AIPHOTO_KEY_THUMBNAIL_SIZE", "320"))
    allowed_origins: tuple[str, ...] = (
        "http://127.0.0.1:5173",
        "http://localhost:5173",
    )


settings = Settings()
settings.data_dir.mkdir(parents=True, exist_ok=True)
settings.weights_dir.mkdir(parents=True, exist_ok=True)
