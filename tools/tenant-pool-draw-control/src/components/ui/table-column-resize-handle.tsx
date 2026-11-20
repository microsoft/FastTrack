import type { MouseEventHandler, TouchEventHandler } from "react";

export function TableColumnResizeHandle({
  label,
  size,
  minSize,
  maxSize,
  resizing,
  onResizeStart,
  onResize,
  onReset,
}: {
  label: string;
  size: number;
  minSize: number;
  maxSize: number;
  resizing: boolean;
  onResizeStart: MouseEventHandler<HTMLDivElement> &
    TouchEventHandler<HTMLDivElement>;
  onResize: (size: number) => void;
  onReset: () => void;
}) {
  return (
    <div
      role="separator"
      aria-label={label}
      aria-orientation="vertical"
      aria-valuemin={minSize}
      aria-valuemax={maxSize}
      aria-valuenow={size}
      tabIndex={0}
      title="Drag to resize; use arrow keys when focused. Double-click to reset."
      className={`absolute inset-y-0 right-0 z-10 w-2 touch-none cursor-col-resize select-none border-r-2 hover:border-primary focus-visible:border-primary focus-visible:outline-none ${resizing ? "border-primary" : "border-border"}`}
      onMouseDown={onResizeStart}
      onTouchStart={onResizeStart}
      onDoubleClick={onReset}
      onKeyDown={(event) => {
        let next: number;
        switch (event.key) {
          case "ArrowLeft":
            next = size - 10;
            break;
          case "ArrowRight":
            next = size + 10;
            break;
          case "Home":
            next = minSize;
            break;
          case "End":
            next = maxSize;
            break;
          default:
            return;
        }
        event.preventDefault();
        event.stopPropagation();
        onResize(Math.min(maxSize, Math.max(minSize, next)));
      }}
    />
  );
}
