from __future__ import annotations

from pathlib import Path
import shutil
import subprocess
import tempfile

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


def _load_raw_with_sips(image_path: Path) -> Image.Image:
    with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as temp_file:
        temp_path = Path(temp_file.name)
    try:
        subprocess.run(
            ["sips", "-s", "format", "jpeg", str(image_path), "--out", str(temp_path)],
            check=True,
            capture_output=True,
            text=True,
        )
        with Image.open(temp_path) as image:
            return ImageOps.exif_transpose(image).copy()
    except subprocess.CalledProcessError as exc:
        raise ValueError(_normalize_error_message(exc)) from exc
    finally:
        temp_path.unlink(missing_ok=True)


def load_image(image_path: Path) -> Image.Image:
    suffix = image_path.suffix.lower()
    if suffix in RAW_EXTENSIONS:
        raw_error: Exception | None = None
        if rawpy is not None:
            try:
                with rawpy.imread(str(image_path)) as raw:
                    rgb = raw.postprocess(use_camera_wb=True)
                return Image.fromarray(rgb)
            except Exception as exc:  # pragma: no cover
                raw_error = exc

        if shutil.which("sips"):
            try:
                return _load_raw_with_sips(image_path)
            except Exception as exc:  # pragma: no cover
                if raw_error is not None:
                    raise ValueError(
                        f"RAW decode failed in rawpy ({_normalize_error_message(raw_error)}) and sips "
                        f"({_normalize_error_message(exc)})"
                    ) from exc
                raise ValueError(_normalize_error_message(exc)) from exc

        if raw_error is not None:
            raise ValueError(_normalize_error_message(raw_error)) from raw_error
        raise RuntimeError("No RAW decoder is available. Install rawpy or use macOS with sips.")

    try:
        with Image.open(image_path) as image:
            return ImageOps.exif_transpose(image).copy()
    except Exception as exc:
        raise ValueError(_normalize_error_message(exc)) from exc
