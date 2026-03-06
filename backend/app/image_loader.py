from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageOps

try:
    import rawpy
except ImportError:  # pragma: no cover
    rawpy = None


STANDARD_EXTENSIONS = {
    ".jpg",
    ".jpeg",
    ".png",
    ".heic",
    ".heif",
    ".gif",
    ".tiff",
    ".tif",
    ".bmp",
    ".webp",
}

RAW_EXTENSIONS = {
    ".raw",
    ".cr2",
    ".cr3",
    ".nef",
    ".arw",
    ".dng",
    ".orf",
    ".rw2",
    ".pef",
    ".srw",
    ".raf",
    ".x3f",
}

SUPPORTED_EXTENSIONS = STANDARD_EXTENSIONS | RAW_EXTENSIONS


def _normalize_error_message(error: Exception) -> str:
    if not error.args:
        return str(error)
    first = error.args[0]
    if isinstance(first, bytes):
        return first.decode("utf-8", errors="replace")
    return str(first)


def is_supported_image(path: Path) -> bool:
    return path.suffix.lower() in SUPPORTED_EXTENSIONS


def load_image(image_path: Path) -> Image.Image:
    suffix = image_path.suffix.lower()
    if suffix in RAW_EXTENSIONS:
        if rawpy is None:
            raise RuntimeError("rawpy is not installed; RAW images are unavailable.")
        try:
            with rawpy.imread(str(image_path)) as raw:
                rgb = raw.postprocess(use_camera_wb=True)
        except Exception as exc:  # pragma: no cover
            raise ValueError(_normalize_error_message(exc)) from exc
        return Image.fromarray(rgb)

    try:
        with Image.open(image_path) as image:
            return ImageOps.exif_transpose(image).copy()
    except Exception as exc:
        raise ValueError(_normalize_error_message(exc)) from exc
