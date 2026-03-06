export type ModelOption = {
  id: string;
  label: string;
  description: string;
  family: string;
  size: string;
  recommended: boolean;
};

export type Detection = {
  label: string;
  confidence: number;
  source: string;
};

export type Photo = {
  id: number;
  relative_path: string;
  absolute_path: string;
  width: number | null;
  height: number | null;
  file_size: number;
  modified_at: string;
  detections: Detection[];
  captions: Caption[];
};

export type Caption = {
  text: string;
  model_id: string;
  source: string;
};

export type ObjectSummary = {
  label: string;
  count: number;
  max_confidence: number;
};

export type CatalogSummary = {
  source_path: string | null;
  scan_count: number;
  photo_count: number;
  detection_count: number;
  object_count: number;
  caption_count: number;
  last_scan_at: string | null;
  detector_status: string;
};

export type ScanResponse = {
  scan_id: number;
  source_path: string;
  started_at: string;
  completed_at: string;
  scanned_files: number;
  imported_photos: number;
  detections: number;
  detector_status: string;
  warnings: string[];
};

export type ScanJob = {
  job_id: string;
  state: "queued" | "starting" | "running" | "completed" | "failed" | "canceled";
  source_path: string;
  model_id: string;
  min_confidence: number;
  message: string;
  total_files: number;
  scanned_files: number;
  imported_photos: number;
  detections: number;
  progress: number;
  phase: string;
  phase_progress: number;
  current_file: string | null;
  started_at: string;
  completed_at: string | null;
  result: ScanResponse | null;
};

export type CaptionModelOption = {
  id: string;
  label: string;
  description: string;
  recommended: boolean;
  provider: string;
};

export type CaptionRunResponse = {
  run_id: number;
  source_path: string;
  started_at: string;
  completed_at: string;
  processed_files: number;
  imported_photos: number;
  captions_generated: number;
  captioner_status: string;
  warnings: string[];
};

export type CaptionJob = {
  job_id: string;
  state: "queued" | "starting" | "running" | "completed" | "failed" | "canceled";
  source_path: string;
  model_id: string;
  message: string;
  total_files: number;
  processed_files: number;
  imported_photos: number;
  captions_generated: number;
  progress: number;
  phase: string;
  phase_progress: number;
  current_file: string | null;
  started_at: string;
  completed_at: string | null;
  result: CaptionRunResponse | null;
};
