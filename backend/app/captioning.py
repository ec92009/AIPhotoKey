from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
import threading
from typing import Dict, List, Optional
from uuid import uuid4

import torch

from .catalog import CatalogService
from .database import get_connection
from .image_loader import load_image
from .models import CaptionJobResponse, CaptionRequest, CaptionRunResponse, SUPPORTED_CAPTION_MODELS

try:
    from transformers import BlipForConditionalGeneration, BlipProcessor
except ImportError:  # pragma: no cover
    BlipForConditionalGeneration = None
    BlipProcessor = None


CAPTION_MODEL_MAP = {model["id"]: model for model in SUPPORTED_CAPTION_MODELS}


class CaptionGenerator:
    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._cache: Dict[str, tuple[object, object, str]] = {}

    def generate(self, image_path: Path, model_id: str) -> str:
        if BlipProcessor is None or BlipForConditionalGeneration is None:
            raise RuntimeError("Captioning dependencies are not installed. Run `uv sync --extra caption`.")

        processor, model, device = self._get_model(model_id)
        image = load_image(image_path).convert("RGB")
        inputs = processor(images=image, return_tensors="pt")
        if device != "cpu":
            inputs = {key: value.to(device) for key, value in inputs.items()}
        output = model.generate(**inputs, max_new_tokens=48)
        return processor.decode(output[0], skip_special_tokens=True).strip()

    def prepare_model(self, model_id: str, progress_callback=None) -> bool:
        if BlipProcessor is None or BlipForConditionalGeneration is None:
            raise RuntimeError("Captioning dependencies are not installed. Run `uv sync --extra caption`.")
        with self._lock:
            cached = self._cache.get(model_id)
        if cached:
            if progress_callback:
                progress_callback("Caption model already cached.", 1.0)
            return False
        self._get_model(model_id, progress_callback=progress_callback)
        return True

    def _get_model(self, model_id: str, progress_callback=None):
        if model_id not in CAPTION_MODEL_MAP:
            raise RuntimeError(f"Unknown caption model: {model_id}")

        with self._lock:
            cached = self._cache.get(model_id)
            if cached:
                return cached

            provider = CAPTION_MODEL_MAP[model_id]["provider"]
            if progress_callback:
                progress_callback("Preparing caption processor...", 0.1)
            processor = BlipProcessor.from_pretrained(provider)
            if progress_callback:
                progress_callback("Preparing tokenizer/config...", 0.25)
                progress_callback("Downloading/loading caption model weights...", 0.45)
            model = BlipForConditionalGeneration.from_pretrained(provider)

            device = "cpu"
            if torch.backends.mps.is_available():
                device = "mps"
            elif torch.cuda.is_available():
                device = "cuda"

            model = model.to(device)
            model.eval()
            if progress_callback:
                progress_callback("Caption model ready.", 1.0)
            payload = (processor, model, device)
            self._cache[model_id] = payload
            return payload


@dataclass
class CaptionJob:
    job_id: str
    source_path: str
    model_id: str
    state: str = "queued"
    message: str = "Queued"
    total_files: int = 0
    processed_files: int = 0
    imported_photos: int = 0
    captions_generated: int = 0
    progress: float = 0.0
    phase: str = "scan"
    phase_progress: float = 0.0
    current_file: Optional[str] = None
    started_at: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    completed_at: Optional[str] = None
    result: Optional[CaptionRunResponse] = None
    cancel_event: threading.Event = field(default_factory=threading.Event, repr=False)

    def to_response(self) -> CaptionJobResponse:
        return CaptionJobResponse(
            job_id=self.job_id,
            state=self.state,
            source_path=self.source_path,
            model_id=self.model_id,
            message=self.message,
            total_files=self.total_files,
            processed_files=self.processed_files,
            imported_photos=self.imported_photos,
            captions_generated=self.captions_generated,
            progress=self.progress,
            phase=self.phase,
            phase_progress=self.phase_progress,
            current_file=self.current_file,
            started_at=self.started_at,
            completed_at=self.completed_at,
            result=self.result,
        )


class CaptionManager:
    def __init__(self, catalog: CatalogService, generator: Optional[CaptionGenerator] = None) -> None:
        self.catalog = catalog
        self.generator = generator or CaptionGenerator()
        self._lock = threading.Lock()
        self._jobs: Dict[str, CaptionJob] = {}

    def start_caption_run(self, request: CaptionRequest) -> CaptionJobResponse:
        job = CaptionJob(
            job_id=str(uuid4()),
            source_path=request.source_path,
            model_id=request.model_id,
            state="starting",
            message="Preparing caption run...",
        )
        with self._lock:
            self._jobs[job.job_id] = job

        thread = threading.Thread(target=self._run_job, args=(job.job_id, request), daemon=True)
        thread.start()
        return job.to_response()

    def get_job(self, job_id: str) -> CaptionJobResponse:
        with self._lock:
            job = self._jobs.get(job_id)
            if not job:
                raise KeyError(job_id)
            return job.to_response()

    def cancel_job(self, job_id: str) -> CaptionJobResponse:
        with self._lock:
            job = self._jobs.get(job_id)
            if not job:
                raise KeyError(job_id)
            job.cancel_event.set()
            if job.state in {"queued", "starting", "running"}:
                job.message = "Cancel requested..."
            return job.to_response()

    def _run_job(self, job_id: str, request: CaptionRequest) -> None:
        def update(**changes):
            with self._lock:
                job = self._jobs[job_id]
                for key, value in changes.items():
                    if key == "result" and value is None:
                        continue
                    setattr(job, key, value)
                total_files = max(job.total_files, 0)
                job.progress = 0.0 if total_files == 0 else min(job.processed_files / total_files, 1.0)
                if job.state in {"completed", "failed", "canceled"}:
                    job.completed_at = datetime.now(timezone.utc).isoformat()

        try:
            response = self._run_caption_pass(request, self._jobs[job_id].cancel_event, update)
            if self._jobs[job_id].state not in {"completed", "canceled"}:
                update(state="completed", message="Captioning completed.", result=response)
        except Exception as exc:
            update(state="failed", message=str(exc))

    def _run_caption_pass(self, request: CaptionRequest, cancel_event: threading.Event, progress_callback) -> CaptionRunResponse:
        source_path = Path(request.source_path).expanduser().resolve()
        if not source_path.exists() or not source_path.is_dir():
            raise FileNotFoundError(f"Directory not found: {source_path}")

        image_paths = list(self.catalog._iter_images(source_path))
        total_files = len(image_paths)
        warnings: List[str] = []
        started_at = datetime.now(timezone.utc)

        progress_callback(
            state="running",
            message="Starting caption run...",
            total_files=total_files,
            processed_files=0,
            imported_photos=0,
            captions_generated=0,
            phase="scan",
            phase_progress=0.0,
            current_file=None,
        )

        downloaded_now = False
        try:
            progress_callback(
                state="running",
                message="Downloading/loading caption model. First run can be about 1 GB and may take a while...",
                total_files=total_files,
                processed_files=0,
                imported_photos=0,
                captions_generated=0,
                phase="model",
                phase_progress=0.05,
                current_file=None,
            )
            downloaded_now = self.generator.prepare_model(
                request.model_id,
                progress_callback=lambda message, amount: progress_callback(
                    state="running",
                    message=message,
                    total_files=total_files,
                    processed_files=0,
                    imported_photos=0,
                    captions_generated=0,
                    phase="model",
                    phase_progress=amount,
                    current_file=None,
                ),
            )
            progress_callback(
                state="running",
                message=(
                    "Caption model ready. Starting file-by-file captions..."
                    if downloaded_now
                    else "Caption model already cached. Starting file-by-file captions..."
                ),
                total_files=total_files,
                processed_files=0,
                imported_photos=0,
                captions_generated=0,
                phase="scan",
                phase_progress=1.0,
                current_file=None,
            )
        except Exception as exc:
            raise RuntimeError(f"Unable to prepare caption model: {exc}") from exc

        with get_connection(self.catalog.database_path) as connection:
            if request.clear_existing:
                connection.execute("DELETE FROM detections")
                connection.execute("DELETE FROM photos")
                connection.execute("DELETE FROM scans")

            cursor = connection.execute(
                """
                INSERT INTO scans (source_path, model_id, min_confidence, detector_status, started_at)
                VALUES (?, ?, ?, ?, ?)
                """,
                (
                    str(source_path),
                    request.model_id,
                    0.0,
                    "captioning",
                    started_at.isoformat(),
                ),
            )
            run_id = int(cursor.lastrowid)
            processed_files = 0
            imported_photos = 0
            captions_generated = 0

            for image_path in image_paths:
                if cancel_event.is_set():
                    completed_at = datetime.now(timezone.utc)
                    connection.execute(
                        "UPDATE scans SET completed_at = ? WHERE id = ?",
                        (completed_at.isoformat(), run_id),
                    )
                    progress_callback(
                        state="canceled",
                        message="Caption run canceled.",
                        total_files=total_files,
                        processed_files=processed_files,
                        imported_photos=imported_photos,
                        captions_generated=captions_generated,
                        phase="scan",
                        phase_progress=1.0,
                        current_file=None,
                    )
                    return CaptionRunResponse(
                        run_id=run_id,
                        source_path=str(source_path),
                        started_at=started_at.isoformat(),
                        completed_at=completed_at.isoformat(),
                        processed_files=processed_files,
                        imported_photos=imported_photos,
                        captions_generated=captions_generated,
                        captioner_status="canceled",
                        warnings=warnings + ["Caption run canceled by user."],
                    )

                processed_files += 1
                relative_path = str(image_path.relative_to(source_path))
                progress_callback(
                    state="running",
                    message=f"Captioning {relative_path}",
                    total_files=total_files,
                    processed_files=processed_files,
                    imported_photos=imported_photos,
                    captions_generated=captions_generated,
                    phase="scan",
                    phase_progress=1.0,
                    current_file=relative_path,
                )
                try:
                    metadata = self.catalog._extract_metadata(image_path)
                    caption_text = self.generator.generate(image_path, request.model_id)
                except Exception as exc:
                    warnings.append(f"Skipped caption for {image_path.name}: {exc}")
                    continue

                photo_cursor = connection.execute(
                    """
                    INSERT INTO photos (scan_id, absolute_path, relative_path, width, height, file_size, modified_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        run_id,
                        str(image_path),
                        relative_path,
                        metadata["width"],
                        metadata["height"],
                        metadata["file_size"],
                        metadata["modified_at"],
                    ),
                )
                photo_id = int(photo_cursor.lastrowid)
                imported_photos += 1

                connection.execute(
                    """
                    INSERT INTO captions (photo_id, model_id, caption, source, created_at)
                    VALUES (?, ?, ?, ?, ?)
                    """,
                    (
                        photo_id,
                        request.model_id,
                        caption_text,
                        "captioning",
                        datetime.now(timezone.utc).isoformat(),
                    ),
                )
                captions_generated += 1
                connection.commit()
                progress_callback(
                    state="running",
                    message=f"Captioned {relative_path}",
                    total_files=total_files,
                    processed_files=processed_files,
                    imported_photos=imported_photos,
                    captions_generated=captions_generated,
                    phase="scan",
                    phase_progress=1.0,
                    current_file=relative_path,
                )

            completed_at = datetime.now(timezone.utc)
            connection.execute(
                "UPDATE scans SET completed_at = ? WHERE id = ?",
                (completed_at.isoformat(), run_id),
            )

        result = CaptionRunResponse(
            run_id=run_id,
            source_path=str(source_path),
            started_at=started_at.isoformat(),
            completed_at=completed_at.isoformat(),
            processed_files=processed_files,
            imported_photos=imported_photos,
            captions_generated=captions_generated,
            captioner_status="ready",
            warnings=warnings,
        )
        progress_callback(
            state="completed",
            message="Captioning completed.",
            total_files=total_files,
            processed_files=processed_files,
            imported_photos=imported_photos,
            captions_generated=captions_generated,
            phase="scan",
            phase_progress=1.0,
            current_file=None,
            result=result,
        )
        return result
