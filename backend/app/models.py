from __future__ import annotations

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field


MODEL_FAMILIES = [
    {
        "prefix": "yolov8",
        "family": "YOLOv8",
        "description": "Stable compatibility baseline for Ultralytics object detection.",
        "recommended": False,
    },
    {
        "prefix": "yolo11",
        "family": "YOLO11",
        "description": "Modern production-ready family with strong detection quality and broad support.",
        "recommended": True,
    },
    {
        "prefix": "yolo26",
        "family": "YOLO26",
        "description": "Newest Ultralytics family focused on edge deployment and end-to-end inference.",
        "recommended": True,
    },
]

MODEL_SIZES = [
    ("n", "Nano", "Fastest, lowest accuracy"),
    ("s", "Small", "Balanced entry point"),
    ("m", "Medium", "Higher accuracy with more compute"),
    ("l", "Large", "Slower but stronger on harder images"),
    ("x", "XL", "Largest standard checkpoint"),
]

SUPPORTED_MODELS = [
    {
        "id": f"{family['prefix']}{size_code}",
        "label": f"{family['family']} {size_label}",
        "family": family["family"],
        "size": size_label,
        "recommended": family["recommended"],
        "description": f"{family['description']} {size_hint}.",
    }
    for family in MODEL_FAMILIES
    for size_code, size_label, size_hint in MODEL_SIZES
]

SUPPORTED_CAPTION_MODELS = [
    {
        "id": "blip-base",
        "label": "BLIP Base",
        "description": "Balanced local image captioning with concise scene descriptions.",
        "recommended": True,
        "provider": "Salesforce/blip-image-captioning-base",
    },
    {
        "id": "blip-large",
        "label": "BLIP Large",
        "description": "Higher-quality captions with slower inference and larger downloads.",
        "recommended": False,
        "provider": "Salesforce/blip-image-captioning-large",
    },
]


class ScanRequest(BaseModel):
    source_path: str = Field(..., min_length=1)
    model_id: str = "yolov8n"
    caption_model_id: Optional[str] = None
    min_confidence: float = Field(0.5, ge=0.0, le=1.0)
    clear_existing: bool = True


class CaptionRequest(BaseModel):
    source_path: str = Field(..., min_length=1)
    model_id: str = "blip-base"
    clear_existing: bool = True


class DetectionDTO(BaseModel):
    label: str
    confidence: float
    source: str


class CaptionDTO(BaseModel):
    text: str
    model_id: str
    source: str


class PhotoDTO(BaseModel):
    id: int
    relative_path: str
    absolute_path: str
    width: Optional[int]
    height: Optional[int]
    file_size: int
    modified_at: str
    detections: List[DetectionDTO]
    captions: List[CaptionDTO]


class ObjectSummaryDTO(BaseModel):
    label: str
    count: int
    max_confidence: float


class SummaryDTO(BaseModel):
    source_path: Optional[str]
    scan_count: int
    photo_count: int
    detection_count: int
    object_count: int
    caption_count: int
    last_scan_at: Optional[str]
    detector_status: str


class ScanResponse(BaseModel):
    scan_id: int
    source_path: str
    started_at: str
    completed_at: str
    scanned_files: int
    imported_photos: int
    detections: int
    captions_generated: int
    detector_status: str
    warnings: List[str]


class ScanJobResponse(BaseModel):
    job_id: str
    state: str
    source_path: str
    model_id: str
    caption_model_id: Optional[str]
    min_confidence: float
    message: str
    total_files: int
    scanned_files: int
    imported_photos: int
    detections: int
    captions_generated: int
    progress: float
    phase: str
    phase_progress: float
    current_file: Optional[str]
    started_at: str
    completed_at: Optional[str]
    result: Optional[ScanResponse]


class ScanRecord(BaseModel):
    id: int
    source_path: str
    model_id: str
    caption_model_id: Optional[str]
    min_confidence: float
    detector_status: str
    started_at: datetime
    completed_at: Optional[datetime]


class CaptionRunResponse(BaseModel):
    run_id: int
    source_path: str
    started_at: str
    completed_at: str
    processed_files: int
    imported_photos: int
    captions_generated: int
    captioner_status: str
    warnings: List[str]


class CaptionJobResponse(BaseModel):
    job_id: str
    state: str
    source_path: str
    model_id: str
    message: str
    total_files: int
    processed_files: int
    imported_photos: int
    captions_generated: int
    progress: float
    phase: str
    phase_progress: float
    current_file: Optional[str]
    started_at: str
    completed_at: Optional[str]
    result: Optional[CaptionRunResponse]
