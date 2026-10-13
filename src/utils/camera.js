/**
 * The transform that frames a rectangle in the canvas. Pan is the center of the
 * view (see CanvasContext, which builds the viewBox around transform.pan) and
 * zoom snaps to 5%, matching fit-to-window.
 */
export function cameraFor(rect, { padding = 48, maxZoom = 1 } = {}) {
  const screen = document.getElementById("canvas")?.getBoundingClientRect();
  if (!rect || !screen || rect.width <= 0 || rect.height <= 0) return null;

  const zoom = Math.min(
    (screen.width - padding * 2) / rect.width,
    (screen.height - padding * 2) / rect.height,
    maxZoom,
  );
  return {
    zoom: Math.max(0.05, Math.floor(zoom * 20) / 20),
    pan: { x: rect.x + rect.width / 2, y: rect.y + rect.height / 2 },
  };
}
