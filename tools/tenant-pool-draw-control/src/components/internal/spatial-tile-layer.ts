import L, {
  type Coords,
  type DoneCallback,
  type GridLayerOptions,
} from "leaflet";

import {
  decodeSpatialTile,
  type SpatialTileFailure,
} from "@/lib/spatial-tile-bytes";

import type {
  SpatialTileLoader,
  SpatialTileOutcome,
} from "../spatial-map";

export const MAX_ACTIVE_SPATIAL_TILES = 8;
export const MAX_QUEUED_SPATIAL_TILES = 64;
export const SPATIAL_TILE_LOAD_TIMEOUT_MS = 30_000;

interface TileState {
  completed: boolean;
  disposed: boolean;
  done: DoneCallback;
  generation: number;
  image: HTMLImageElement;
  imageDeadline?: number;
  job?: TileJob;
}

interface TileJob {
  run: () => Promise<void>;
  state: TileState;
  owner: SpatialTileLayer;
}

interface TileScheduler {
  active: number;
  queue: TileJob[];
  waiting: Set<() => void>;
}

const schedulers = new WeakMap<Document, TileScheduler>();

function geospatialPolicyMessage(error: unknown): string | undefined {
  if (!error || typeof error !== "object" || !("status" in error) || !("message" in error)) return;
  // SDK 0.5.11 retains status/body but drops the host's policy-code header.
  const disabled = "Maps are disabled by your organization's geospatial settings. Ask an administrator to enable Azure Maps integration, then reload the app.";
  const unavailable = "Maps are unavailable because your organization's geospatial setting could not be verified. Try again or contact an administrator.";
  if (error.status === 403 && error.message === disabled) return disabled;
  if (error.status === 503 && error.message === unavailable) {
    return "Maps are unavailable because your organization's Azure Maps setting could not be verified. Ask an administrator to check Azure Maps integration for this environment.";
  }
}

function releasePermit(scheduler: TileScheduler): void {
  scheduler.active -= 1;
  for (const wake of [...scheduler.waiting]) wake();
}

function retainPermitUntilSettlement(
  result: ReturnType<SpatialTileLoader>,
  scheduler: TileScheduler,
): void {
  // This continuation holds no layer or DOM state, even after unmount/timeout.
  void result.then(
    () => queueMicrotask(() => releasePermit(scheduler)),
    () => queueMicrotask(() => releasePermit(scheduler)),
  );
}

export class SpatialTileLayer extends L.GridLayer {
  private readonly scheduler: TileScheduler;
  private generation = 0;
  private halted = false;
  private removed = false;
  private capacityRecoveryNeeded = false;
  private queueDeadline?: number;
  private readonly loadTile: SpatialTileLoader;
  private readonly onOutcome: (outcome: SpatialTileOutcome) => void;
  private readonly onUnavailable: (message?: string) => void;
  private readonly states = new Set<TileState>();
  private readonly pending = new Set<() => void>();
  private readonly wakeScheduler = () => {
    this.pump();
    this.refreshQueueDeadline(true);
  };

  public constructor(
    loadTile: SpatialTileLoader,
    onUnavailable: (message?: string) => void,
    onOutcome: (outcome: SpatialTileOutcome) => void = () => {},
    options?: GridLayerOptions,
  ) {
    super({
      attribution: "© Microsoft",
      maxZoom: 20,
      minZoom: 1,
      tileSize: 256,
      ...options,
    });
    this.loadTile = loadTile;
    this.onUnavailable = onUnavailable;
    this.onOutcome = onOutcome;
    let scheduler = schedulers.get(document);
    if (!scheduler) {
      scheduler = { active: 0, queue: [], waiting: new Set() };
      schedulers.set(document, scheduler);
    }
    this.scheduler = scheduler;
    this.on("tileunload", (event: L.TileEvent) => {
      this.disposeTile(event.tile as HTMLImageElement);
    });
  }

  public override createTile(
    coords: Coords,
    done: DoneCallback,
  ): HTMLElement {
    const image = document.createElement("img");
    image.alt = "";
    image.height = 256;
    image.setAttribute("role", "presentation");
    image.width = 256;

    const state: TileState = {
      completed: false,
      disposed: false,
      done,
      generation: this.generation,
      image,
    };
    this.states.add(state);

    const job: TileJob = {
      state,
      owner: this,
      run: async () => {
        const disposed = Symbol();
        let cancel!: () => void;
        const disposal = new Promise<typeof disposed>((resolve) => {
          cancel = () => resolve(disposed);
        });
        this.pending.add(cancel);
        let timeout: number | undefined;
        let timedOut = false;
        const timeoutResult = new Promise<never>((_resolve, reject) => {
          timeout = window.setTimeout(() => {
            timedOut = true;
            reject(new Error("Map tile request timed out."));
          }, SPATIAL_TILE_LOAD_TIMEOUT_MS);
        });
        let loadResult: ReturnType<SpatialTileLoader> | undefined;
        let result: Awaited<ReturnType<SpatialTileLoader>> | typeof disposed;
        try {
          loadResult = this.loadTile({
            x: coords.x,
            y: coords.y,
            zoom: coords.z,
          });
          const raced = Promise.race([loadResult, timeoutResult, disposal]);
          retainPermitUntilSettlement(loadResult, this.scheduler);
          result = await raced;
        } catch (error) {
          try {
            if (state.generation === this.generation) {
              this.failLayer("render_error", geospatialPolicyMessage(error));
            } else if (!timedOut) {
              this.reportOutcome("disposed");
            }
          } finally {
            if (!loadResult) releasePermit(this.scheduler);
          }
          return;
        } finally {
          if (timeout !== undefined) window.clearTimeout(timeout);
          this.pending.delete(cancel);
        }
        if (this.removed || result === disposed) return;
        if (state.generation !== this.generation) {
          this.reportOutcome("disposed");
          return;
        }
        if (!result.success) {
          this.failLayer("render_error", geospatialPolicyMessage(result.error));
          return;
        }

        const decoded = decodeSpatialTile(result.data);
        if (!decoded.ok) {
          this.failLayer(decoded.reason);
          return;
        }
        if (state.disposed || this.halted) {
          this.reportOutcome("disposed");
          return;
        }

        image.onload = () => {
          this.clearImageHandlers(state);
          if (
            state.generation !== this.generation ||
            state.disposed ||
            this.halted
          ) {
            this.reportOutcome("disposed");
            return;
          }
          if (image.naturalWidth !== 256 || image.naturalHeight !== 256) {
            this.failLayer("invalid_dimensions");
            return;
          }
          this.finish(state);
          this.reportOutcome("accepted");
        };
        image.onerror = () => {
          this.clearImageHandlers(state);
          if (
            state.generation === this.generation &&
            !state.disposed
          ) {
            this.failLayer("render_error");
          }
        };
        state.imageDeadline = window.setTimeout(() => {
          if (
            state.generation === this.generation &&
            !state.disposed &&
            !state.completed &&
            !this.halted
          ) {
            this.failLayer("render_error");
          }
        }, SPATIAL_TILE_LOAD_TIMEOUT_MS);
        image.src = decoded.dataUrl;
      },
    };
    state.job = job;
    this.schedule(job);
    return image;
  }

  public retry(): boolean {
    if (!this.halted || this.removed) return false;
    this.generation += 1;
    this.halted = false;
    return true;
  }

  public override onRemove(map: L.Map): this {
    this.removed = true;
    this.halted = true;
    this.clearQueueDeadline();
    for (const cancel of this.pending) cancel();
    this.pending.clear();
    for (const state of [...this.states]) {
      this.disposeState(state);
    }
    this.scheduler.waiting.delete(this.wakeScheduler);
    return super.onRemove(map);
  }

  private clearImageHandlers(state: TileState): void {
    if (state.imageDeadline !== undefined) {
      window.clearTimeout(state.imageDeadline);
      state.imageDeadline = undefined;
    }
    state.image.onload = null;
    state.image.onerror = null;
  }

  private disposeState(state: TileState): void {
    if (state.disposed) return;
    state.disposed = true;
    this.clearImageHandlers(state);
    const queuedIndex = state.job ? this.scheduler.queue.indexOf(state.job) : -1;
    if (queuedIndex >= 0) {
      this.scheduler.queue.splice(queuedIndex, 1);
      this.refreshQueueDeadline();
    }
    state.image.removeAttribute("src");
    this.states.delete(state);
  }

  private disposeTile(image: HTMLImageElement): void {
    const state = [...this.states].find(
      (candidate) => candidate.image === image,
    );
    if (state) {
      this.disposeState(state);
    }
    this.refreshQueueDeadline();
  }

  private failLayer(outcome: SpatialTileOutcome | SpatialTileFailure, message?: string): void {
    if (this.halted || this.removed) return;
    this.halted = true;
    this.clearQueueDeadline();
    for (const state of [...this.states]) {
      if (!state.completed && !state.disposed) {
        this.finish(state, new Error("Map tiles are unavailable."));
      }
      this.disposeState(state);
    }
    this.scheduler.waiting.delete(this.wakeScheduler);
    try {
      this.onUnavailable(message);
    } finally {
      this.reportOutcome(outcome);
    }
  }

  private reportOutcome(outcome: SpatialTileOutcome): void {
    if (this.removed) return;
    try {
      this.onOutcome(outcome);
    } catch {
      return;
    }
  }

  private finish(state: TileState, error?: Error): void {
    if (state.completed || state.disposed) return;
    state.completed = true;
    state.done(error, state.image);
  }

  private clearQueueDeadline(): void {
    if (this.queueDeadline !== undefined) {
      window.clearTimeout(this.queueDeadline);
      this.queueDeadline = undefined;
    }
  }

  private refreshQueueDeadline(progress = false): void {
    if (this.capacityRecoveryNeeded && !this.hasCapacityWaiters()) {
      this.recoverCapacity(false);
    }
    if (this.halted || (
      !this.capacityRecoveryNeeded &&
      !this.scheduler.queue.some((job) => job.owner === this)
    )) {
      this.clearQueueDeadline();
      if (this.halted || !this.capacityRecoveryNeeded) {
        this.scheduler.waiting.delete(this.wakeScheduler);
      }
      return;
    }
    if (this.queueDeadline !== undefined && !progress) return;
    this.clearQueueDeadline();
    const generation = this.generation;
    const deadline = window.setTimeout(() => {
      if (
        this.queueDeadline === deadline &&
        generation === this.generation &&
        !this.halted &&
        (this.hasCapacityWaiters() ||
          this.scheduler.queue.some((job) => job.owner === this))
      ) {
        this.failLayer("render_error");
      } else if (this.queueDeadline === deadline) {
        this.refreshQueueDeadline();
      }
    }, SPATIAL_TILE_LOAD_TIMEOUT_MS);
    this.queueDeadline = deadline;
  }

  private pump(): void {
    while (
      !this.halted &&
      this.scheduler.active < MAX_ACTIVE_SPATIAL_TILES &&
      this.scheduler.queue.length > 0
    ) {
      const job = this.scheduler.queue.shift();
      if (!job || job.state.disposed) continue;
      this.scheduler.active += 1;
      void job
        .run()
        .catch(() => {
          if (job.state.generation === job.owner.generation) {
            job.owner.failLayer("render_error");
          } else {
            job.owner.reportOutcome("disposed");
          }
        })
        .finally(() => {
          job.owner.refreshQueueDeadline();
        });
    }
    if (!this.halted && this.scheduler.active < MAX_ACTIVE_SPATIAL_TILES && this.scheduler.queue.length === 0) {
      this.recoverCapacity();
    }
    this.refreshQueueDeadline();
  }

  private hasCapacityWaiters(): boolean {
    if (!this.capacityRecoveryNeeded) return false;
    const grid = this as unknown as {
      _map?: L.Map;
      _tiles?: Record<string, { el: HTMLElement; coords: Coords }>;
    };
    if (!grid._map) return false;
    const viewport = grid._map.getPixelBounds();
    const zoom = Math.round(grid._map.getZoom());
    const size = this.getTileSize();
    return Object.values(grid._tiles ?? {}).some(({ el, coords }) =>
      el.dataset.spatialCapacityRejected === "true" &&
      coords.z === zoom &&
      viewport.overlaps(L.bounds(
        [coords.x * size.x, coords.y * size.y],
        [(coords.x + 1) * size.x, (coords.y + 1) * size.y],
      )),
    );
  }

  private recoverCapacity(refreshViewport = true): void {
    if (!this.capacityRecoveryNeeded) return;
    // Leaflet 1.9 marks errored tiles loaded and will not request them again.
    // Use its existing tile registry, not an unbounded deferred request queue.
    const grid = this as unknown as {
      _map?: L.Map;
      _tiles?: Record<string, { el: HTMLElement }>;
      _removeTile: (key: string) => void;
      _update: () => void;
    };
    this.capacityRecoveryNeeded = false;
    if (!grid._map || !grid._tiles) return;
    for (const [key, tile] of Object.entries(grid._tiles)) {
      if (tile.el.dataset.spatialCapacityRejected === "true") {
        grid._removeTile(key);
      }
    }
    if (refreshViewport) grid._update();
  }

  private schedule(job: TileJob): void {
    if (this.halted) {
      queueMicrotask(() => {
        this.finish(job.state, new Error("Map tiles are unavailable."));
        this.disposeState(job.state);
      });
      return;
    }
    if (this.scheduler.queue.length >= MAX_QUEUED_SPATIAL_TILES) {
      this.capacityRecoveryNeeded = true;
      this.scheduler.waiting.add(this.wakeScheduler);
      job.state.image.dataset.spatialCapacityRejected = "true";
      this.reportOutcome("capacity_exceeded");
      queueMicrotask(() => {
        this.finish(job.state, new Error("Map tile capacity exceeded."));
        this.disposeState(job.state);
        this.refreshQueueDeadline();
      });
      return;
    }
    this.scheduler.queue.push(job);
    this.scheduler.waiting.add(this.wakeScheduler);
    this.pump();
  }
}
