import { useEffect, useLayoutEffect, useRef, useState } from "react";
import L from "leaflet";
import "leaflet/dist/leaflet.css";

import { SpatialTileLayer } from "./internal/spatial-tile-layer";

export interface SpatialMapCenter {
  latitude: number;
  longitude: number;
}

export interface SpatialMapMarker extends SpatialMapCenter {
  id: string;
  label: string;
}

export interface SpatialMapBounds {
  south: number;
  west: number;
  north: number;
  east: number;
}

export interface SpatialTileRequest {
  x: number;
  y: number;
  zoom: number;
}

export interface SpatialTileLoadResult {
  success: boolean;
  data: unknown;
  error?: unknown;
}

export type SpatialTileLoader = (
  request: SpatialTileRequest,
) => Promise<SpatialTileLoadResult>;

export type SpatialTileOutcome =
  | "accepted"
  | "capacity_exceeded"
  | "disposed"
  | "invalid_dimensions"
  | "render_error"
  | "invalid_signature"
  | "oversized"
  | "unsupported_shape";

export type SpatialMapInputRejectionReason =
  | "too_many_markers"
  | "invalid_marker_id"
  | "duplicate_marker_id"
  | "invalid_marker_label"
  | "invalid_marker_coordinate"
  | "invalid_selected_id"
  | "invalid_center"
  | "invalid_zoom"
  | "invalid_bounds";

export interface SpatialMapViewportChange {
  center: SpatialMapCenter;
  zoom: number;
  bounds: SpatialMapBounds;
}

export interface SpatialMapProps {
  loadTile: SpatialTileLoader;
  markers?: readonly SpatialMapMarker[];
  selectedId?: string | null;
  center?: SpatialMapCenter | null;
  zoom?: number | null;
  bounds?: SpatialMapBounds | null;
  onLocationSelect?: (marker: SpatialMapMarker) => void;
  onViewportChange?: (event: SpatialMapViewportChange) => void;
  onInputRejected?: (reason: SpatialMapInputRejectionReason) => void;
  onTileOutcome?: (outcome: SpatialTileOutcome) => void;
  onUnavailable?: () => void;
}

const EMPTY_MARKERS: readonly SpatialMapMarker[] = [];
const MAX_MARKERS = 500;
const MAX_MARKER_ID_CODE_POINTS = 128;
const MAX_MARKER_LABEL_CODE_POINTS = 200;

interface MarkerRecord {
  data: SpatialMapMarker;
  marker: L.CircleMarker;
  keydown: EventListener;
}

function isCoordinate(latitude: unknown, longitude: unknown): boolean {
  return (
    typeof latitude === "number" &&
    Number.isFinite(latitude) &&
    latitude >= -90 &&
    latitude <= 90 &&
    typeof longitude === "number" &&
    Number.isFinite(longitude) &&
    longitude >= -180 &&
    longitude <= 180
  );
}

function boundedText(value: unknown, limit: number): value is string {
  return (
    typeof value === "string" &&
    value.length <= limit * 2 &&
    [...value].length <= limit &&
    /\S/u.test(value)
  );
}

function validateInput(
  props: SpatialMapProps,
): SpatialMapInputRejectionReason | null {
  const { markers = EMPTY_MARKERS, selectedId, center, zoom, bounds } = props;
  if (!Array.isArray(markers)) return "invalid_marker_id";
  if (markers.length > MAX_MARKERS) return "too_many_markers";
  const ids = new Set<string>();
  for (const marker of markers) {
    if (
      !marker ||
      !boundedText(marker.id, MAX_MARKER_ID_CODE_POINTS) ||
      marker.id !== marker.id.trim()
    ) return "invalid_marker_id";
    if (ids.has(marker.id)) return "duplicate_marker_id";
    ids.add(marker.id);
    if (!boundedText(marker.label, MAX_MARKER_LABEL_CODE_POINTS)) return "invalid_marker_label";
    if (!isCoordinate(marker.latitude, marker.longitude)) {
      return "invalid_marker_coordinate";
    }
  }
  if (selectedId != null && typeof selectedId !== "string") {
    return "invalid_selected_id";
  }
  if (center != null && !isCoordinate(center.latitude, center.longitude)) {
    return "invalid_center";
  }
  if (zoom != null && (!Number.isInteger(zoom) || zoom < 1 || zoom > 20)) {
    return "invalid_zoom";
  }
  if (
    bounds != null &&
    (!isCoordinate(bounds.south, bounds.west) ||
      !isCoordinate(bounds.north, bounds.east) ||
      bounds.south > bounds.north)
  ) return "invalid_bounds";
  return null;
}

function copyMarker({ id, label, latitude, longitude }: SpatialMapMarker): SpatialMapMarker {
  return { id, label, latitude, longitude };
}

function normalizeLongitude(value: number): number {
  const normalized = ((((value + 180) % 360) + 360) % 360) - 180;
  return normalized === -180 && value > 0 ? 180 : normalized;
}

function nearestWorldLongitude(longitude: number, reference: number): number {
  return longitude + 360 * Math.round((reference - longitude) / 360);
}

function viewportFromMap(map: L.Map): SpatialMapViewportChange {
  const center = map.getCenter();
  const bounds = map.getBounds();
  const wholeWorld = bounds.getEast() - bounds.getWest() >= 360;
  return {
    center: {
      latitude: center.lat,
      longitude: normalizeLongitude(center.lng),
    },
    zoom: map.getZoom(),
    bounds: {
      south: bounds.getSouth(),
      north: bounds.getNorth(),
      west: wholeWorld ? -180 : normalizeLongitude(bounds.getWest()),
      east: wholeWorld ? 180 : normalizeLongitude(bounds.getEast()),
    },
  };
}

export function SpatialMap(props: SpatialMapProps) {
  const {
    markers = EMPTY_MARKERS,
    selectedId = null,
    center,
    zoom,
    bounds,
  } = props;
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<L.Map | null>(null);
  const tileLayerRef = useRef<SpatialTileLayer | null>(null);
  const recordsRef = useRef(new Map<string, MarkerRecord>());
  const committedProps = useRef(props);
  const [tileUnavailable, setTileUnavailable] = useState<string | null>(null);
  const [retryStatus, setRetryStatus] = useState<"idle" | "pending" | "failed">("idle");
  const rejection = validateInput(props);
  const valid = rejection === null;

  useLayoutEffect(() => {
    committedProps.current = props;
  });

  useEffect(() => {
    if (rejection) {
      committedProps.current.onInputRejected?.(rejection);
      committedProps.current.onUnavailable?.();
    }
  }, [rejection]);

  useEffect(() => {
    if (!valid || !containerRef.current) return;
    const initial = committedProps.current;
    const map = L.map(containerRef.current, {
      center: initial.center
        ? [initial.center.latitude, initial.center.longitude]
        : [20, 0],
      zoom: initial.zoom ?? 2,
      minZoom: 1,
      maxZoom: 20,
      keyboard: true,
      zoomControl: true,
    });
    map.attributionControl.setPrefix(false);
    mapRef.current = map;
    if (initial.bounds) {
      const { south, west, north, east } = initial.bounds;
      map.fitBounds(
        [[south, west], [north, east < west ? east + 360 : east]],
        { animate: false, maxZoom: 20 },
      );
    }
    setTileUnavailable(null);
    setRetryStatus("idle");
    const tiles = new SpatialTileLayer(
      (request) => committedProps.current.loadTile(request),
      (message) => {
        setTileUnavailable(message ?? "Map tiles are unavailable. Check the Spatial Services connection and try again.");
        setRetryStatus((current) => current === "pending" ? "failed" : current);
        committedProps.current.onUnavailable?.();
      },
      (outcome) => {
        if (outcome === "accepted") {
          setTileUnavailable(null);
          setRetryStatus("idle");
        }
        committedProps.current.onTileOutcome?.(outcome);
      },
    ).addTo(map);
    tileLayerRef.current = tiles;
    const records = recordsRef.current;
    const reportViewport = () => {
      for (const record of records.values()) {
        record.marker.setLatLng([
          record.data.latitude,
          nearestWorldLongitude(record.data.longitude, map.getCenter().lng),
        ]);
      }
      committedProps.current.onViewportChange?.(viewportFromMap(map));
    };
    map.on("moveend", reportViewport);
    let resizeTimer: number | undefined;
    const invalidateSize = () => {
      if (mapRef.current !== map || resizeTimer !== undefined) return;
      resizeTimer = window.setTimeout(() => {
        resizeTimer = undefined;
        if (mapRef.current === map) map.invalidateSize({ animate: false });
      }, 0);
    };
    const observer = typeof window.ResizeObserver === "undefined"
      ? undefined
      : new window.ResizeObserver(invalidateSize);
    observer?.observe(containerRef.current);
    invalidateSize();
    reportViewport();
    return () => {
      observer?.disconnect();
      if (resizeTimer !== undefined) window.clearTimeout(resizeTimer);
      for (const record of records.values()) {
        record.marker.getElement()?.removeEventListener("keydown", record.keydown);
      }
      records.clear();
      map.remove();
      mapRef.current = null;
      tileLayerRef.current = null;
    };
  }, [valid]);

  useEffect(() => {
    const map = mapRef.current;
    if (!valid || !map) return;
    const records = recordsRef.current;
    const ids = new Set(markers.map(({ id }) => id));
    for (const [id, record] of records) {
      if (ids.has(id)) continue;
      record.marker.getElement()?.removeEventListener("keydown", record.keydown);
      record.marker.remove();
      records.delete(id);
    }
    for (const marker of markers) {
      let record = records.get(marker.id);
      if (!record) {
        const layer = L.circleMarker([marker.latitude, marker.longitude], {
          className:
            "spatial-location-marker focus-visible:outline-solid focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring",
          color: "var(--primary)",
          fillColor: "var(--primary)",
        }).addTo(map);
        const activate = () => {
          const current = records.get(marker.id);
          if (current) {
            committedProps.current.onLocationSelect?.(copyMarker(current.data));
          }
        };
        const keydown: EventListener = (event) => {
          if (!(event instanceof window.KeyboardEvent)) return;
          if (event.key !== "Enter" && event.key !== " ") return;
          event.preventDefault();
          activate();
        };
        layer.on("click", activate);
        record = { data: copyMarker(marker), marker: layer, keydown };
        records.set(marker.id, record);
        const element = layer.getElement();
        element?.setAttribute("role", "button");
        element?.setAttribute("tabindex", "0");
        element?.addEventListener("keydown", keydown);
      }
      record.data = copyMarker(marker);
      record.marker.setLatLng([
        marker.latitude,
        nearestWorldLongitude(marker.longitude, map.getCenter().lng),
      ]);
      const label = document.createElement("span");
      label.textContent = marker.label;
      record.marker.unbindTooltip().bindTooltip(label, { direction: "top" });
      record.marker.getElement()?.setAttribute("aria-label", marker.label);
    }
    for (const [id, record] of records) {
      const selected = id === selectedId;
      record.marker.setStyle({
        radius: selected ? 11 : 9,
        weight: selected ? 5 : 2,
        fillOpacity: selected ? 0.55 : 0.3,
        dashArray: selected ? "2 2" : undefined,
      });
      const element = record.marker.getElement();
      element?.classList.toggle("selected-location-marker", selected);
      if (selected) element?.setAttribute("aria-current", "location");
      else element?.removeAttribute("aria-current");
      if (selected && element?.nextElementSibling) {
        const focused = document.activeElement;
        record.marker.bringToFront();
        if (focused instanceof SVGElement && focused.isConnected) {
          focused.focus({ preventScroll: true });
        }
      }
    }
  }, [valid, markers, selectedId]);

  const latitude = center?.latitude;
  const longitude = center?.longitude;
  const south = bounds?.south;
  const west = bounds?.west;
  const north = bounds?.north;
  const east = bounds?.east;
  useEffect(() => {
    const map = mapRef.current;
    if (!valid || !map) return;
    if (south != null && west != null && north != null && east != null) {
      const current = viewportFromMap(map).bounds;
      if (
        current.south !== south || current.west !== west ||
        current.north !== north || current.east !== east
      ) {
        map.fitBounds(
          [[south, west], [north, east < west ? east + 360 : east]],
          { animate: false, maxZoom: 20 },
        );
      }
    } else {
      const current = map.getCenter();
      const target = latitude != null && longitude != null
        ? L.latLng(latitude, nearestWorldLongitude(longitude, current.lng))
        : current;
      // Leaflet rounds projected positions; an unchanged pixel needs no new move.
      if (!map.project(current).round().equals(map.project(target).round()) ||
        (zoom != null && zoom !== map.getZoom())) {
        map.setView(target, zoom ?? map.getZoom(), { animate: false });
      }
    }
  }, [valid, latitude, longitude, zoom, south, west, north, east]);

  const unavailable = !valid || tileUnavailable;
  return (
    <div data-slot="spatial-map" className="relative isolate h-[56dvh] min-h-[28rem] w-full overflow-hidden bg-muted lg:h-[calc(100dvh-12rem)] lg:min-h-[38rem]">
      <div
        ref={containerRef}
        aria-hidden={unavailable ? true : undefined}
        inert={unavailable ? true : undefined}
        className="h-full w-full"
        role="region"
        aria-label="Interactive location map. Use arrow keys to pan and plus or minus to zoom."
      />
      {unavailable ? (
        <div
          className="absolute inset-0 z-[1100] flex items-center justify-center bg-background/90 p-6 text-center text-sm text-muted-foreground"
          role="status"
        >
          {!valid
            ? "The map configuration is invalid. Check its locations and camera settings."
            : <>
                <span>
                  {tileUnavailable}
                  {retryStatus === "failed" ? " Still unavailable after retry." : ""}
                </span>
                <button
                  className="ml-2 underline underline-offset-2"
                  disabled={retryStatus === "pending"}
                  onClick={() => {
                    if (tileLayerRef.current?.retry()) {
                      setRetryStatus("pending");
                      tileLayerRef.current.redraw();
                    }
                  }}
                  type="button"
                >
                  {retryStatus === "pending" ? "Retrying..." : "Try again"}
                </button>
              </>}
        </div>
      ) : null}
    </div>
  );
}
