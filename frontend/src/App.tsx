import { FormEvent, useEffect, useState } from "react";
import packageJson from "../package.json";
import {
  cancelScan,
  clearCatalog,
  fetchCaptionModels,
  fetchHealth,
  fetchModels,
  fetchObjects,
  fetchPhotos,
  fetchScanJob,
  fetchSummary,
  pickSourceFolder,
  runScan,
  thumbnailUrl,
} from "./api";
import type {
  CaptionModelOption,
  CatalogSummary,
  ModelOption,
  ObjectSummary,
  Photo,
  ScanJob,
} from "./types";

const defaultSummary: CatalogSummary = {
  source_path: null,
  scan_count: 0,
  photo_count: 0,
  detection_count: 0,
  object_count: 0,
  caption_count: 0,
  last_scan_at: null,
  detector_status: "idle",
};

function formatNumber(value: number): string {
  return new Intl.NumberFormat().format(value);
}

function formatDate(value: string | null): string {
  if (!value) return "Never";
  return new Date(value).toLocaleString();
}

function formatAppVersion(version: string): string {
  const [major = "0", minor = "0"] = version.split(".");
  return `v${major}.${minor}`;
}

function selectedModelSummary(models: ModelOption[], modelId: string): string {
  const selected = models.find((model) => model.id === modelId);
  return selected ? selected.description : "Choose the keyword model for the next scan.";
}

function selectedCaptionModelSummary(models: CaptionModelOption[], modelId: string): string {
  const selected = models.find((model) => model.id === modelId);
  return selected ? selected.description : "Choose the caption model for the next scan.";
}

function ProgressBlock({
  label,
  current,
  total,
  progress,
  detail,
}: {
  label: string;
  current: number;
  total: number;
  progress: number;
  detail: string;
}) {
  return (
    <div className="progress-block">
      <p className="status-subtle">{label}</p>
      <div className="progress-copy">
        <span>
          {current} / {total || "?"} files
        </span>
        <span>{Math.round(progress * 100)}%</span>
      </div>
      <div className="progress-bar">
        <div className="progress-fill" style={{ width: `${Math.round(progress * 100)}%` }} />
      </div>
      <p className="status-subtle">{detail}</p>
    </div>
  );
}

function ModelProgressBlock({
  progress,
  message,
}: {
  progress: number;
  message: string;
}) {
  return (
    <div className="progress-block">
      <p className="status-subtle">Model download / load</p>
      <div className="progress-copy">
        <span>Preparing runtime</span>
        <span>{Math.round(progress * 100)}%</span>
      </div>
      <div className="progress-bar">
        <div className="progress-fill" style={{ width: `${Math.round(progress * 100)}%` }} />
      </div>
      <p className="status-subtle">{message}</p>
    </div>
  );
}

export default function App() {
  const appVersion = formatAppVersion(packageJson.version);
  const [health, setHealth] = useState("checking");
  const [models, setModels] = useState<ModelOption[]>([]);
  const [captionModels, setCaptionModels] = useState<CaptionModelOption[]>([]);
  const [summary, setSummary] = useState<CatalogSummary>(defaultSummary);
  const [objects, setObjects] = useState<ObjectSummary[]>([]);
  const [photos, setPhotos] = useState<Photo[]>([]);
  const [selectedObject, setSelectedObject] = useState("");
  const [sourcePath, setSourcePath] = useState("~/Pictures");
  const [modelId, setModelId] = useState("yolov8n");
  const [captionModelId, setCaptionModelId] = useState("blip-base");
  const [minConfidence, setMinConfidence] = useState(0.5);
  const [status, setStatus] = useState("Ready");
  const [busy, setBusy] = useState(false);
  const [scanJob, setScanJob] = useState<ScanJob | null>(null);

  async function refreshCatalog(objectLabel = selectedObject) {
    const [summaryData, objectData, photoData] = await Promise.all([
      fetchSummary(),
      fetchObjects(),
      fetchPhotos(objectLabel || undefined),
    ]);
    setSummary(summaryData);
    setObjects(objectData);
    setPhotos(photoData);
  }

  useEffect(() => {
    async function bootstrap() {
      try {
        const [healthData, modelData, captionModelData] = await Promise.all([
          fetchHealth(),
          fetchModels(),
          fetchCaptionModels(),
        ]);
        setHealth(healthData.status);
        setModels(modelData);
        setCaptionModels(captionModelData);
        if (modelData.length > 0) {
          setModelId(modelData[0].id);
        }
        if (captionModelData.length > 0) {
          setCaptionModelId(captionModelData[0].id);
        }
        await refreshCatalog("");
      } catch (error) {
        setHealth("offline");
        setStatus(error instanceof Error ? error.message : "Failed to connect to backend");
      }
    }

    void bootstrap();
  }, []);

  useEffect(() => {
    void refreshCatalog(selectedObject);
  }, [selectedObject]);

  useEffect(() => {
    if (!scanJob || !["starting", "running", "queued"].includes(scanJob.state)) {
      return;
    }

    const timer = window.setInterval(async () => {
      try {
        const next = await fetchScanJob(scanJob.job_id);
        setScanJob(next);
        setStatus(next.message);
        if (["queued", "starting", "running"].includes(next.state)) {
          await refreshCatalog("");
        }
        if (next.state === "completed") {
          setBusy(false);
          setSelectedObject("");
          await refreshCatalog("");
          const finalMessage =
            next.result?.warnings.length
              ? next.result.warnings.join(" ")
              : `Imported ${next.imported_photos} photos with ${next.detections} keywords and ${next.captions_generated} captions.`;
          setStatus(finalMessage);
        } else if (next.state === "canceled") {
          setBusy(false);
          await refreshCatalog("");
          setStatus("Scan canceled.");
        } else if (next.state === "failed") {
          setBusy(false);
          setStatus(next.message || "Scan failed");
        }
      } catch (error) {
        setBusy(false);
        setStatus(error instanceof Error ? error.message : "Lost scan status");
      }
    }, 750);

    return () => window.clearInterval(timer);
  }, [scanJob?.job_id, scanJob?.state]);

  async function onRunScan(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setSelectedObject("");
    setObjects([]);
    setPhotos([]);
    setSummary({
      ...defaultSummary,
      source_path: sourcePath,
      detector_status: "starting",
    });
    setStatus("Starting unified scan...");
    try {
      const job = await runScan({
        source_path: sourcePath,
        model_id: modelId,
        caption_model_id: captionModelId,
        min_confidence: minConfidence,
        clear_existing: true,
      });
      setScanJob(job);
      setStatus(job.message);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "Scan failed");
      setBusy(false);
    }
  }

  async function onClear() {
    setBusy(true);
    try {
      await clearCatalog();
      setSelectedObject("");
      setScanJob(null);
      await refreshCatalog("");
      setStatus("Catalog cleared.");
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "Clear failed");
    } finally {
      setBusy(false);
    }
  }

  async function onBrowseFolder() {
    setBusy(true);
    try {
      const path = await pickSourceFolder();
      setSourcePath(path);
      setStatus(`Selected source folder: ${path}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : "Folder selection failed";
      if (!message.includes("Folder selection canceled")) {
        setStatus(message);
      }
    } finally {
      setBusy(false);
    }
  }

  async function onCancelScan() {
    if (!scanJob) return;
    try {
      const next = await cancelScan(scanJob.job_id);
      setScanJob(next);
      setStatus("Stopping after current image...");
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "Unable to cancel scan");
    }
  }

  return (
    <main className="shell">
      <section className="hero">
        <div>
          <p className="eyebrow">AIPhotoKey</p>
          <h1>Photo intelligence for your library.</h1>
          <p className="lede">Each photo gets keywords from the detector and a caption in one pass.</p>
        </div>
        <div className="hero-meta">
          <span className="badge">{appVersion}</span>
          <span className={`badge badge-${health}`}>API {health}</span>
          <span className="badge">Mode {summary.detector_status}</span>
        </div>
      </section>

      <section className="controls-panel">
        <form className="controls" onSubmit={onRunScan}>
          <label>
            Source folder
            <div className="path-row">
              <input value={sourcePath} onChange={(event) => setSourcePath(event.target.value)} />
              <button type="button" className="ghost browse-button" disabled={busy} onClick={onBrowseFolder}>
                Browse…
              </button>
            </div>
            <small className="field-help">Pick a local folder to scan.</small>
          </label>
          <label>
            Keyword model
            <select value={modelId} onChange={(event) => setModelId(event.target.value)}>
              {models.map((model) => (
                <option key={model.id} value={model.id}>
                  {model.label}{model.recommended ? " • Recommended" : ""}
                </option>
              ))}
            </select>
            <small className="field-help">{selectedModelSummary(models, modelId)}</small>
          </label>
          <label>
            Caption model
            <select value={captionModelId} onChange={(event) => setCaptionModelId(event.target.value)}>
              {captionModels.map((model) => (
                <option key={model.id} value={model.id}>
                  {model.label}{model.recommended ? " • Recommended" : ""}
                </option>
              ))}
            </select>
            <small className="field-help">{selectedCaptionModelSummary(captionModels, captionModelId)}</small>
          </label>
          <label>
            Confidence
            <div className="slider-row">
              <input
                type="range"
                min={0}
                max={1}
                step={0.01}
                value={minConfidence}
                onChange={(event) => setMinConfidence(Number(event.target.value))}
              />
              <span>{Math.round(minConfidence * 100)}%</span>
            </div>
            <small className="field-help">Applies to keyword detections.</small>
          </label>
          <div className="button-row">
            <button type="submit" disabled={busy}>
              {busy ? "Working..." : "Scan library"}
            </button>
            <button
              type="button"
              className="ghost"
              disabled={!scanJob || !["queued", "starting", "running"].includes(scanJob.state)}
              onClick={onCancelScan}
            >
              Cancel scan
            </button>
            <button type="button" className="ghost" disabled={busy} onClick={onClear}>
              Clear catalog
            </button>
          </div>
        </form>

        <aside className="status-card">
          <p className="status-label">Status</p>
          <p className="status-value">{status}</p>
          {scanJob && ["queued", "starting", "running", "canceled", "completed", "failed"].includes(scanJob.state) ? (
            <>
              {scanJob.phase === "model" ? (
                <ModelProgressBlock progress={scanJob.phase_progress} message={scanJob.message} />
              ) : null}
              <ProgressBlock
                label="Unified scan"
                current={scanJob.scanned_files}
                total={scanJob.total_files}
                progress={scanJob.progress}
                detail={scanJob.current_file ?? "Waiting for next file..."}
              />
            </>
          ) : null}
          <p className="status-subtle">
            Last scan: {formatDate(summary.last_scan_at)}
            <br />
            Source: {summary.source_path ?? "Not set"}
          </p>
        </aside>
      </section>

      <section className="summary-grid">
        <article>
          <span>Scans</span>
          <strong>{formatNumber(summary.scan_count)}</strong>
        </article>
        <article>
          <span>Photos</span>
          <strong>{formatNumber(summary.photo_count)}</strong>
        </article>
        <article>
          <span>Keywords</span>
          <strong>{formatNumber(summary.object_count)}</strong>
        </article>
        <article>
          <span>Detections</span>
          <strong>{formatNumber(summary.detection_count)}</strong>
        </article>
        <article>
          <span>Captions</span>
          <strong>{formatNumber(summary.caption_count)}</strong>
        </article>
      </section>

      <section className="content-grid">
        <aside className="object-panel">
          <div className="panel-head">
            <h2>Keywords</h2>
            <button className={!selectedObject ? "active-filter" : ""} onClick={() => setSelectedObject("")}>
              All
            </button>
          </div>
          <div className="object-list">
            {objects.length === 0 ? (
              <p className="empty">No keywords yet.</p>
            ) : (
              objects.map((item) => (
                <button
                  key={item.label}
                  className={selectedObject === item.label ? "object-chip selected" : "object-chip"}
                  onClick={() => setSelectedObject(item.label)}
                >
                  <span>{item.label}</span>
                  <span>
                    {item.count} · {Math.round(item.max_confidence * 100)}%
                  </span>
                </button>
              ))
            )}
          </div>
        </aside>

        <section className="photo-panel">
          <div className="panel-head">
            <h2>{selectedObject || "Library"}</h2>
            <p>{photos.length} items</p>
          </div>
          <p className="model-note">
            Keyword families: {Array.from(new Set(models.map((model) => model.family))).join(", ")} · Captions: local BLIP
          </p>
          <div className="photo-grid">
            {photos.length === 0 ? (
              <div className="empty-card">No photos yet.</div>
            ) : (
              photos.map((photo) => (
                <article key={photo.id} className="photo-card">
                  <img src={thumbnailUrl(photo.id)} alt={photo.relative_path} loading="lazy" />
                  <div className="photo-copy">
                    <h3>{photo.relative_path}</h3>
                    <p>
                      {photo.width ?? "?"} × {photo.height ?? "?"} · {Math.round(photo.file_size / 1024)} KB
                    </p>
                    <p className="caption-text">{photo.captions[0]?.text ?? "Caption pending."}</p>
                    <div className="tag-row">
                      {photo.detections.length === 0 ? (
                        <span className="tag muted">No keywords</span>
                      ) : (
                        photo.detections.slice(0, 6).map((detection) => (
                          <span className="tag" key={`${photo.id}-${detection.label}-${detection.source}`}>
                            {detection.label}
                          </span>
                        ))
                      )}
                    </div>
                  </div>
                </article>
              ))
            )}
          </div>
        </section>
      </section>
    </main>
  );
}
