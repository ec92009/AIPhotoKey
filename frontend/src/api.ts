import type {
  CatalogSummary,
  CaptionJob,
  CaptionModelOption,
  ModelOption,
  ObjectSummary,
  Photo,
  ScanJob,
  ScanResponse,
} from "./types";

async function parseJson<T>(response: Response): Promise<T> {
  if (!response.ok) {
    const body = await response.text();
    throw new Error(body || `Request failed with status ${response.status}`);
  }
  return response.json() as Promise<T>;
}

export async function fetchHealth(): Promise<{ status: string }> {
  return parseJson(await fetch("/api/health"));
}

export async function fetchModels(): Promise<ModelOption[]> {
  return parseJson(await fetch("/api/models"));
}

export async function fetchCaptionModels(): Promise<CaptionModelOption[]> {
  return parseJson(await fetch("/api/caption-models"));
}

export async function fetchSummary(): Promise<CatalogSummary> {
  return parseJson(await fetch("/api/summary"));
}

export async function fetchObjects(): Promise<ObjectSummary[]> {
  return parseJson(await fetch("/api/objects"));
}

export async function fetchPhotos(objectLabel?: string): Promise<Photo[]> {
  const query = objectLabel ? `?object_label=${encodeURIComponent(objectLabel)}` : "";
  return parseJson(await fetch(`/api/photos${query}`));
}

export async function runScan(payload: {
  source_path: string;
  model_id: string;
  min_confidence: number;
  clear_existing: boolean;
}): Promise<ScanJob> {
  return parseJson(
    await fetch("/api/scans", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    }),
  );
}

export async function fetchScanJob(jobId: string): Promise<ScanJob> {
  return parseJson(await fetch(`/api/scans/${jobId}`));
}

export async function cancelScan(jobId: string): Promise<ScanJob> {
  return parseJson(
    await fetch(`/api/scans/${jobId}/cancel`, {
      method: "POST",
    }),
  );
}

export async function runCaptionJob(payload: {
  source_path: string;
  model_id: string;
  clear_existing: boolean;
}): Promise<CaptionJob> {
  return parseJson(
    await fetch("/api/captions", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    }),
  );
}

export async function fetchCaptionJob(jobId: string): Promise<CaptionJob> {
  return parseJson(await fetch(`/api/captions/${jobId}`));
}

export async function cancelCaptionJob(jobId: string): Promise<CaptionJob> {
  return parseJson(
    await fetch(`/api/captions/${jobId}/cancel`, {
      method: "POST",
    }),
  );
}

export async function clearCatalog(): Promise<void> {
  const response = await fetch("/api/catalog", { method: "DELETE" });
  if (!response.ok) {
    throw new Error(`Failed to clear catalog: ${response.status}`);
  }
}

export async function pickSourceFolder(): Promise<string> {
  const payload = await parseJson<{ path: string }>(
    await fetch("/api/system/pick-folder", {
      method: "POST",
    }),
  );
  return payload.path;
}

export function thumbnailUrl(photoId: number): string {
  return `/api/photos/${photoId}/thumbnail`;
}
