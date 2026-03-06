from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
import threading
from uuid import uuid4
from typing import Dict, Iterator, List, Optional

from PIL import ImageOps, UnidentifiedImageError

from .config import settings
from .database import get_connection
from .detectors.base import Detection
from .detectors.factory import create_detector
from .image_loader import is_supported_image, load_image
from .models import PhotoDTO, ScanJobResponse, ScanRequest, ScanResponse, SummaryDTO


class CatalogService:
    def __init__(self) -> None:
        self.database_path = settings.database_path

    def run_scan(
        self,
        request: ScanRequest,
        cancel_event: Optional[threading.Event] = None,
        progress_callback=None,
    ) -> ScanResponse:
        source_path = Path(request.source_path).expanduser().resolve()
        if not source_path.exists() or not source_path.is_dir():
            raise FileNotFoundError(f"Directory not found: {source_path}")

        image_paths = list(self._iter_images(source_path))
        started_at = datetime.now(timezone.utc)
        warnings: List[str] = []
        total_files = len(image_paths)

        if progress_callback:
            progress_callback(
                state="running",
                message="Starting scan...",
                total_files=total_files,
                scanned_files=0,
                imported_photos=0,
                detections=0,
                phase="scan",
                phase_progress=0.0,
                current_file=None,
            )
            progress_callback(
                state="running",
                message="Downloading/loading detection model. First run may download hundreds of MB and take a while...",
                total_files=total_files,
                scanned_files=0,
                imported_photos=0,
                detections=0,
                phase="model",
                phase_progress=0.05,
                current_file=None,
            )

        def on_model_progress(message: str, amount: float) -> None:
            if progress_callback:
                progress_callback(
                    state="running",
                    message=message,
                    total_files=total_files,
                    scanned_files=0,
                    imported_photos=0,
                    detections=0,
                    phase="model",
                    phase_progress=amount,
                    current_file=None,
                )

        detector = create_detector(request.model_id, progress_callback=on_model_progress)

        if progress_callback:
            progress_callback(
                state="running",
                message=getattr(detector, "ready_message", "Detection model ready. Starting file-by-file scan..."),
                total_files=total_files,
                scanned_files=0,
                imported_photos=0,
                detections=0,
                phase="scan",
                phase_progress=1.0,
                current_file=None,
            )

        with get_connection(self.database_path) as connection:
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
                    request.min_confidence,
                    detector.status,
                    started_at.isoformat(),
                ),
            )
            scan_id = int(cursor.lastrowid)

            scanned_files = 0
            imported_photos = 0
            detection_count = 0

            for image_path in image_paths:
                if cancel_event and cancel_event.is_set():
                    completed_at = datetime.now(timezone.utc)
                    connection.execute(
                        "UPDATE scans SET completed_at = ? WHERE id = ?",
                        (completed_at.isoformat(), scan_id),
                    )
                    if progress_callback:
                        progress_callback(
                            state="canceled",
                            message="Scan canceled.",
                            total_files=total_files,
                            scanned_files=scanned_files,
                            imported_photos=imported_photos,
                            detections=detection_count,
                            phase="scan",
                            phase_progress=1.0,
                            current_file=str(image_path.relative_to(source_path)) if scanned_files < total_files else None,
                        )
                    return ScanResponse(
                        scan_id=scan_id,
                        source_path=str(source_path),
                        started_at=started_at.isoformat(),
                        completed_at=completed_at.isoformat(),
                        scanned_files=scanned_files,
                        imported_photos=imported_photos,
                        detections=detection_count,
                        detector_status=detector.status,
                        warnings=warnings + ["Scan canceled by user."],
                    )

                scanned_files += 1
                relative_path = str(image_path.relative_to(source_path))
                if progress_callback:
                    progress_callback(
                        state="running",
                        message=f"Scanning {relative_path}",
                        total_files=total_files,
                        scanned_files=scanned_files,
                        imported_photos=imported_photos,
                        detections=detection_count,
                        phase="scan",
                        phase_progress=1.0,
                        current_file=relative_path,
                    )
                try:
                    metadata = self._extract_metadata(image_path)
                except (UnidentifiedImageError, RuntimeError, ValueError):
                    warnings.append(f"Skipped unreadable image: {image_path.name}")
                    continue

                photo_cursor = connection.execute(
                    """
                    INSERT INTO photos (scan_id, absolute_path, relative_path, width, height, file_size, modified_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        scan_id,
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

                try:
                    detections = detector.detect(image_path, request.min_confidence)
                except Exception as exc:
                    warnings.append(f"Skipped detections for {image_path.name}: {exc}")
                    detections = []
                detection_count += len(detections)
                self._insert_detections(connection, photo_id, detections)
                connection.commit()
                if progress_callback:
                    progress_callback(
                        state="running",
                        message=f"Processed {relative_path}",
                        total_files=total_files,
                        scanned_files=scanned_files,
                        imported_photos=imported_photos,
                        detections=detection_count,
                        phase="scan",
                        phase_progress=1.0,
                        current_file=relative_path,
                    )

            completed_at = datetime.now(timezone.utc)
            connection.execute(
                "UPDATE scans SET completed_at = ? WHERE id = ?",
                (completed_at.isoformat(), scan_id),
            )

        if detector.status == "metadata-only":
            warnings.append("Ultralytics not installed; scan completed without AI detections.")

        response = ScanResponse(
            scan_id=scan_id,
            source_path=str(source_path),
            started_at=started_at.isoformat(),
            completed_at=completed_at.isoformat(),
            scanned_files=scanned_files,
            imported_photos=imported_photos,
            detections=detection_count,
            detector_status=detector.status,
            warnings=warnings,
        )
        if progress_callback:
            progress_callback(
                state="completed",
                message="Scan completed.",
                total_files=total_files,
                scanned_files=scanned_files,
                imported_photos=imported_photos,
                detections=detection_count,
                phase="scan",
                phase_progress=1.0,
                current_file=None,
                result=response,
            )
        return response

    def clear_catalog(self) -> None:
        with get_connection(self.database_path) as connection:
            connection.execute("DELETE FROM detections")
            connection.execute("DELETE FROM photos")
            connection.execute("DELETE FROM scans")

    def summary(self) -> SummaryDTO:
        with get_connection(self.database_path) as connection:
            counts = connection.execute(
                """
                SELECT
                    (SELECT COUNT(*) FROM scans) AS scan_count,
                    (SELECT COUNT(*) FROM photos) AS photo_count,
                    (SELECT COUNT(*) FROM detections) AS detection_count,
                    (SELECT COUNT(DISTINCT label) FROM detections) AS object_count,
                    (SELECT COUNT(*) FROM captions) AS caption_count,
                    (SELECT source_path FROM scans ORDER BY id DESC LIMIT 1) AS source_path,
                    (SELECT completed_at FROM scans ORDER BY id DESC LIMIT 1) AS last_scan_at,
                    (SELECT detector_status FROM scans ORDER BY id DESC LIMIT 1) AS detector_status
                """
            ).fetchone()

        return SummaryDTO(
            source_path=counts["source_path"],
            scan_count=counts["scan_count"],
            photo_count=counts["photo_count"],
            detection_count=counts["detection_count"],
            object_count=counts["object_count"],
            caption_count=counts["caption_count"],
            last_scan_at=counts["last_scan_at"],
            detector_status=counts["detector_status"] or "idle",
        )

    def list_objects(self) -> List[Dict[str, object]]:
        with get_connection(self.database_path) as connection:
            rows = connection.execute(
                """
                SELECT label, COUNT(*) AS count, MAX(confidence) AS max_confidence
                FROM detections
                GROUP BY label
                ORDER BY count DESC, label ASC
                """
            ).fetchall()
        return [dict(row) for row in rows]

    def list_photos(self, object_label: Optional[str] = None, limit: int = 120) -> List[PhotoDTO]:
        params: List[object] = []
        where_clause = ""
        if object_label:
            where_clause = "WHERE d.label = ?"
            params.append(object_label)

        params.extend([limit])

        with get_connection(self.database_path) as connection:
            rows = connection.execute(
                f"""
                SELECT DISTINCT
                    p.id,
                    p.relative_path,
                    p.absolute_path,
                    p.width,
                    p.height,
                    p.file_size,
                    p.modified_at
                FROM photos p
                LEFT JOIN detections d ON d.photo_id = p.id
                {where_clause}
                ORDER BY p.id DESC
                LIMIT ?
                """,
                params,
            ).fetchall()

            photos: List[PhotoDTO] = []
            for row in rows:
                detections = connection.execute(
                    """
                    SELECT label, confidence, source
                    FROM detections
                    WHERE photo_id = ?
                    ORDER BY confidence DESC, label ASC
                    """,
                    (row["id"],),
                ).fetchall()
                captions = connection.execute(
                    """
                    SELECT caption AS text, model_id, source
                    FROM captions
                    WHERE photo_id = ?
                    ORDER BY id DESC
                    """,
                    (row["id"],),
                ).fetchall()
                photos.append(
                    PhotoDTO(
                        id=row["id"],
                        relative_path=row["relative_path"],
                        absolute_path=row["absolute_path"],
                        width=row["width"],
                        height=row["height"],
                        file_size=row["file_size"],
                        modified_at=row["modified_at"],
                        detections=[dict(item) for item in detections],
                        captions=[dict(item) for item in captions],
                    )
                )
        return photos

    def thumbnail_bytes(self, photo_id: int, size: Optional[int] = None) -> bytes:
        with get_connection(self.database_path) as connection:
            row = connection.execute(
                "SELECT absolute_path FROM photos WHERE id = ?",
                (photo_id,),
            ).fetchone()
        if row is None:
            raise FileNotFoundError(f"Photo not found: {photo_id}")

        target_size = size or settings.thumbnail_size
        image_path = Path(row["absolute_path"])
        with load_image(image_path) as image:
            thumbnail = ImageOps.exif_transpose(image)
            thumbnail.thumbnail((target_size, target_size))
            from io import BytesIO

            output = BytesIO()
            thumbnail.convert("RGB").save(output, format="JPEG", quality=88)
            return output.getvalue()

    def _iter_images(self, source_path: Path) -> Iterator[Path]:
        for path in source_path.rglob("*"):
            if path.is_file() and is_supported_image(path):
                yield path

    def _extract_metadata(self, image_path: Path) -> Dict[str, object]:
        stat = image_path.stat()
        with load_image(image_path) as image:
            width, height = image.size
        return {
            "width": width,
            "height": height,
            "file_size": stat.st_size,
            "modified_at": datetime.fromtimestamp(stat.st_mtime, tz=timezone.utc).isoformat(),
        }

    def _insert_detections(self, connection, photo_id: int, detections: List[Detection]) -> None:
        if not detections:
            return
        connection.executemany(
            """
            INSERT INTO detections (photo_id, label, confidence, source)
            VALUES (?, ?, ?, ?)
            """,
            [(photo_id, item.label, item.confidence, item.source) for item in detections],
        )


@dataclass
class ScanJob:
    job_id: str
    source_path: str
    model_id: str
    min_confidence: float
    state: str = "queued"
    message: str = "Queued"
    total_files: int = 0
    scanned_files: int = 0
    imported_photos: int = 0
    detections: int = 0
    progress: float = 0.0
    phase: str = "scan"
    phase_progress: float = 0.0
    current_file: Optional[str] = None
    started_at: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    completed_at: Optional[str] = None
    result: Optional[ScanResponse] = None
    cancel_event: threading.Event = field(default_factory=threading.Event, repr=False)

    def to_response(self) -> ScanJobResponse:
        return ScanJobResponse(
            job_id=self.job_id,
            state=self.state,
            source_path=self.source_path,
            model_id=self.model_id,
            min_confidence=self.min_confidence,
            message=self.message,
            total_files=self.total_files,
            scanned_files=self.scanned_files,
            imported_photos=self.imported_photos,
            detections=self.detections,
            progress=self.progress,
            phase=self.phase,
            phase_progress=self.phase_progress,
            current_file=self.current_file,
            started_at=self.started_at,
            completed_at=self.completed_at,
            result=self.result,
        )


class ScanManager:
    def __init__(self, catalog: CatalogService) -> None:
        self.catalog = catalog
        self._lock = threading.Lock()
        self._jobs: Dict[str, ScanJob] = {}

    def start_scan(self, request: ScanRequest) -> ScanJobResponse:
        job = ScanJob(
            job_id=str(uuid4()),
            source_path=request.source_path,
            model_id=request.model_id,
            min_confidence=request.min_confidence,
            state="starting",
            message="Preparing scan...",
        )
        with self._lock:
            self._jobs[job.job_id] = job

        thread = threading.Thread(target=self._run_job, args=(job.job_id, request), daemon=True)
        thread.start()
        return job.to_response()

    def get_job(self, job_id: str) -> ScanJobResponse:
        with self._lock:
            job = self._jobs.get(job_id)
            if not job:
                raise KeyError(job_id)
            return job.to_response()

    def cancel_job(self, job_id: str) -> ScanJobResponse:
        with self._lock:
            job = self._jobs.get(job_id)
            if not job:
                raise KeyError(job_id)
            job.cancel_event.set()
            if job.state in {"queued", "starting", "running"}:
                job.message = "Cancel requested..."
            return job.to_response()

    def _run_job(self, job_id: str, request: ScanRequest) -> None:
        def update(**changes):
            with self._lock:
                job = self._jobs[job_id]
                for key, value in changes.items():
                    if key == "result" and value is None:
                        continue
                    setattr(job, key, value)
                total_files = max(job.total_files, 0)
                job.progress = 0.0 if total_files == 0 else min(job.scanned_files / total_files, 1.0)
                if job.state in {"completed", "failed", "canceled"}:
                    job.completed_at = datetime.now(timezone.utc).isoformat()

        try:
            response = self.catalog.run_scan(
                request,
                cancel_event=self._jobs[job_id].cancel_event,
                progress_callback=update,
            )
            if self._jobs[job_id].state not in {"completed", "canceled"}:
                update(state="completed", message="Scan completed.", result=response)
        except Exception as exc:
            update(state="failed", message=str(exc))
