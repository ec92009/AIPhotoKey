import { FormEvent, useEffect, useState } from "react";
import packageJson from "../package.json";
import {
  cancelCaptionJob,
  cancelScan,
  clearCatalog,
  fetchCaptionJob,
  fetchCaptionModels,
  fetchHealth,
  fetchModels,
  fetchObjects,
  fetchPhotos,
  fetchScanJob,
  fetchSummary,
  pickSourceFolder,
  runCaptionJob,
  runScan,
  thumbnailUrl,
} from "./api";
import type {
  CaptionJob,
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

type WorkspaceMode = "detection" | "captioning";

function formatNumber(value: number): string {
  return new Intl.NumberFormat().format(value);
}

function formatDate(value: string | null): string {
  if (!value) return "Never";
  return new Date(value).toLocaleString();
}

function selectedModelSummary(models: ModelOption[], modelId: string): string {
  const selected = models.find((model) => model.id === modelId);
  return selected ? selected.description : "Choose the detector checkpoint for the next scan.";
}

function selectedCaptionModelSummary(models: CaptionModelOption[], modelId: string): string {
  const selected = models.find((model) => model.id === modelId);
  return selected ? selected.description : "Choose the caption model for the next run.";
}

function formatAppVersion(version: string): string {
  const [major = "0", minor = "0"] = version.split(".");
  return `v${major}.${minor}`;
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
  const [mode, setMode] = useState<WorkspaceMode>("detection");
  const [models, setModels] = useState<ModelOption[]>([]);
  const [captionModels, setCaptionModels] = useState<CaptionModelOption[]>([]);
  const [summary, setSummary] = useState<CatalogSummary>(defaultSummary);
  const [objects, setObjects] = useState<ObjectSummary[]>([]);
  const [photos, setPhotos] = useState<Photo[]>([]);
  const [selectedObject, setSelectedObject] = useState<string>("");
  const [sourcePath, setSourcePath] = useState("~/Pictures");
  const [modelId, setModelId] = useState("yolov8n");
  const [captionModelId, setCaptionModelId] = useState("blip-base");
  const [minConfidence, setMinConfidence] = useState(0.5);
  const [status, setStatus] = useState("Ready");
  const [busy, setBusy] = useState(false);
  const [scanJob, setScanJob] = useState<ScanJob | null>(null);
  const [captionJob, setCaptionJob] = useState<CaptionJob | null>(null);

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
    if (mode === "detection") {
      void refreshCatalog(selectedObject);
    }
  }, [selectedObject, mode]);

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
              : `Imported ${next.imported_photos} photos with ${next.detections} detections.`;
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

  useEffect(() => {
    if (!captionJob || !["starting", "running", "queued"].includes(captionJob.state)) {
      return;
    }

    const timer = window.setInterval(async () => {
      try {
        const next = await fetchCaptionJob(captionJob.job_id);
        setCaptionJob(next);
        setStatus(next.message);
        if (["queued", "starting", "running"].includes(next.state)) {
          await refreshCatalog("");
        }
        if (next.state === "completed") {
          setBusy(false);
          await refreshCatalog("");
          const finalMessage =
            next.result?.warnings.length
              ? next.result.warnings.join(" ")
              : `Generated ${next.captions_generated} captions across ${next.imported_photos} photos.`;
          setStatus(finalMessage);
        } else if (next.state === "canceled") {
          setBusy(false);
          await refreshCatalog("");
          setStatus("Caption run canceled.");
        } else if (next.state === "failed") {
          setBusy(false);
          setStatus(next.message || "Caption run failed");
        }
      } catch (error) {
        setBusy(false);
        setStatus(error instanceof Error ? error.message : "Lost caption status");
      }
    }, 750);

    return () => window.clearInterval(timer);
  }, [captionJob?.job_id, captionJob?.state]);

  async function onRunDetection(event: FormEvent<HTMLFormElement>) {
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
    setStatus("Starting new scan...");
    try {
      const job = await runScan({
        source_path: sourcePath,
        model_id: modelId,
        min_confidence: minConfidence,
        clear_existing: true,
      });
      setScanJob(job);
      setCaptionJob(null);
      setStatus(job.message);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "Scan failed");
      setBusy(false);
    }
  }

  async function onRunCaptions() {
    setBusy(true);
    setObjects([]);
    setPhotos([]);
    setSummary({
      ...defaultSummary,
      source_path: sourcePath,
      detector_status: "captioning",
    });
    setStatus("Starting caption run...");
    try {
      const job = await runCaptionJob({
        source_path: sourcePath,
        model_id: captionModelId,
        clear_existing: true,
      });
      setCaptionJob(job);
      setScanJob(null);
      setStatus(job.message);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "Caption run failed");
      setBusy(false);
    }
  }

  async function onClear() {
    setBusy(true);
    try {
      await clearCatalog();
      setSelectedObject("");
      setScanJob(null);
      setCaptionJob(null);
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

  async function onCancelDetection() {
    if (!scanJob) return;
    try {
      const next = await cancelScan(scanJob.job_id);
      setScanJob(next);
      setStatus("Stopping after current image...");
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "Unable to cancel scan");
    }
  }

  async function onCancelCaptioning() {
    if (!captionJob) return;
    try {
      const next = await cancelCaptionJob(captionJob.job_id);
      setCaptionJob(next);
      setStatus("Stopping after current image...");
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "Unable to cancel caption run");
    }
  }

  return (
    <main className="shell">
      <section className="hero">
        <div>
          <p className="eyebrow">AIPhotoKey</p>
          <h1>Photo intelligence for your library.</h1>
          <p className="lede">Scan folders, detect objects, and generate captions as the catalog builds.</p>
        </div>
        <div className="hero-meta">
          <span className="badge">{appVersion}</span>
          <span className={`badge badge-${health}`}>API {health}</span>
          <span className="badge">Mode {summary.detector_status}</span>
        </div>
      </section>

      <section className="mode-switch">
        <button
          type="button"
          className={mode === "detection" ? "mode-chip active" : "mode-chip"}
          onClick={() => setMode("detection")}
        >
          Object Detection
        </button>
        <button
          type="button"
          className={mode === "captioning" ? "mode-chip active" : "mode-chip"}
          onClick={() => setMode("captioning")}
        >
          Captioning
        </button>
      </section>

      <section className="controls-panel">
        <form className="controls" onSubmit={mode === "detection" ? onRunDetection : undefined}>
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
          {mode === "detection" ? (
            <>
              <label>
                Model
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
              </label>
            </>
          ) : (
            <>
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
                Caption output
                <div className="caption-field">Writes one caption per photo into the catalog.</div>
                <small className="field-help">This mode focuses on scene descriptions instead of object tags.</small>
              </label>
            </>
          )}
          <div className="button-row">
            {mode === "detection" ? (
              <button type="submit" disabled={busy}>
                {busy ? "Working..." : "Scan library"}
              </button>
            ) : (
              <button type="button" disabled={busy} onClick={onRunCaptions}>
                {busy ? "Working..." : "Generate captions"}
              </button>
            )}
            <button
              type="button"
              className="ghost"
              disabled={
                mode === "detection"
                  ? !scanJob || !["queued", "starting", "running"].includes(scanJob.state)
                  : !captionJob || !["queued", "starting", "running"].includes(captionJob.state)
              }
              onClick={mode === "detection" ? onCancelDetection : onCancelCaptioning}
            >
              {mode === "detection" ? "Cancel scan" : "Cancel caption run"}
            </button>
            <button type="button" className="ghost" disabled={busy} onClick={onClear}>
              Clear catalog
            </button>
          </div>
        </form>

        <aside className="status-card">
          <p className="status-label">Status</p>
          <p className="status-value">{status}</p>
          {mode === "detection" && scanJob && ["queued", "starting", "running", "canceled", "completed", "failed"].includes(scanJob.state) ? (
            <>
              {scanJob.phase === "model" ? (
                <ModelProgressBlock progress={scanJob.phase_progress} message={scanJob.message} />
              ) : null}
              <ProgressBlock
                label="Library scan"
                current={scanJob.scanned_files}
                total={scanJob.total_files}
                progress={scanJob.progress}
                detail={scanJob.current_file ?? "Waiting for next file..."}
              />
            </>
          ) : null}
          {mode === "captioning" && captionJob && ["queued", "starting", "running", "canceled", "completed", "failed"].includes(captionJob.state) ? (
            <>
              {captionJob.phase === "model" ? (
                <ModelProgressBlock progress={captionJob.phase_progress} message={captionJob.message} />
              ) : null}
              <ProgressBlock
                label="Caption pass"
                current={captionJob.processed_files}
                total={captionJob.total_files}
                progress={captionJob.progress}
                detail={captionJob.current_file ?? "Waiting for next file..."}
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

      {mode === "detection" ? (
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
            <span>Detections</span>
            <strong>{formatNumber(summary.detection_count)}</strong>
          </article>
          <article>
            <span>Objects</span>
            <strong>{formatNumber(summary.object_count)}</strong>
          </article>
        </section>
      ) : (
        <section className="caption-summary">
          <article className="caption-card">
            <span>Captioning Mode</span>
            <strong>{formatNumber(summary.photo_count)} photos</strong>
            <p>Stored photos available for captioning in the current catalog.</p>
          </article>
          <article className="caption-card">
            <span>Caption coverage</span>
            <strong>{formatNumber(summary.caption_count)} captions</strong>
            <p>Natural-language descriptions generated with the selected caption model.</p>
          </article>
        </section>
      )}

      {mode === "detection" ? (
        <section className="content-grid">
          <aside className="object-panel">
            <div className="panel-head">
              <h2>Objects</h2>
              <button className={!selectedObject ? "active-filter" : ""} onClick={() => setSelectedObject("")}>
                All
              </button>
            </div>
            <div className="object-list">
              {objects.length === 0 ? (
                <p className="empty">No detections yet.</p>
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
              <h2>{selectedObject || "Recent photos"}</h2>
              <p>{photos.length} items</p>
            </div>
            <p className="model-note">
              Available detector families: {Array.from(new Set(models.map((model) => model.family))).join(", ")}
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
                      <div className="tag-row">
                        {photo.detections.length === 0 ? (
                          <span className="tag muted">No detections</span>
                        ) : (
                          photo.detections.slice(0, 4).map((detection) => (
                            <span className="tag" key={`${photo.id}-${detection.label}`}>
                              {detection.label} {Math.round(detection.confidence * 100)}%
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
      ) : (
        <section className="caption-layout">
          <article className="caption-card">
            <h2>Captioning Workspace</h2>
            <p>Each photo card shows a caption instead of detection tags.</p>
            <p>Choose a caption model, run the folder, and review results as they arrive.</p>
          </article>
          <article className="caption-card">
            <h2>Generated Captions</h2>
            <div className="caption-photo-list">
              {photos.length === 0 ? (
                <p className="empty">No captions yet.</p>
              ) : (
                photos.map((photo) => (
                  <article key={photo.id} className="caption-photo-card">
                    <img src={thumbnailUrl(photo.id)} alt={photo.relative_path} loading="lazy" />
                    <div className="caption-photo-copy">
                      <h3>{photo.relative_path}</h3>
                      <p className="caption-text">
                        {photo.captions[0]?.text ?? "No caption stored for this photo yet."}
                      </p>
                    </div>
                  </article>
                ))
              )}
            </div>
          </article>
        </section>
      )}
    </main>
  );
}
