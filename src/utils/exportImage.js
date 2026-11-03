import { toJpeg, toPng, toSvg } from "html-to-image";

// Browsers refuse canvases past these limits (Safari is the strictest), and a
// refused canvas exports as a blank image, so the scale is clamped to fit.
const MAX_CANVAS_SIDE = 16384;
const MAX_CANVAS_AREA = 120_000_000;
// Room around the drawing so nothing touches the image edge.
const EXPORT_PADDING = 40;

export const EXPORT_SCALES = [1, 2, 3, 4, 6];
export const DEFAULT_EXPORT_SCALE = 3;

/**
 * Area of the diagram worth exporting: everything drawn in the current view,
 * whatever part of it is on screen and at whatever zoom.
 */
function contentBounds(svg) {
  const content = svg.querySelector("#diagram-content");
  const box = content?.getBBox();
  if (!box || box.width === 0 || box.height === 0) return null;
  return {
    x: Math.floor(box.x - EXPORT_PADDING),
    y: Math.floor(box.y - EXPORT_PADDING),
    width: Math.ceil(box.width + EXPORT_PADDING * 2),
    height: Math.ceil(box.height + EXPORT_PADDING * 2),
  };
}

/** The scale actually used, after the browser's canvas limits. */
export function effectiveScale(bounds, requested) {
  if (!bounds) return requested;
  return Math.min(
    requested,
    MAX_CANVAS_SIDE / bounds.width,
    MAX_CANVAS_SIDE / bounds.height,
    Math.sqrt(MAX_CANVAS_AREA / (bounds.width * bounds.height)),
  );
}

/**
 * Renders the diagram alone (no toolbars, no grid, no hover chrome) at a fixed
 * zoom of 1 × `scale`, framed to its content instead of to the viewport.
 *
 * It works on a detached-from-React copy of the SVG mounted off screen: the
 * copy keeps the page stylesheets and theme, and the live canvas never moves.
 *
 * @param {"png"|"jpeg"|"svg"} format
 * @returns {Promise<{ dataUrl: string, width: number, height: number, scale: number }>}
 */
export async function exportDiagramImage(
  format,
  { scale = DEFAULT_EXPORT_SCALE, background = "white" } = {},
) {
  const svg = document.getElementById("diagram");
  if (!svg) throw new Error("Diagram not found");

  const bounds = contentBounds(svg) ?? {
    x: 0,
    y: 0,
    width: svg.clientWidth || 800,
    height: svg.clientHeight || 600,
  };
  const pixelRatio = effectiveScale(bounds, scale);

  const clone = svg.cloneNode(true);
  clone.removeAttribute("id");
  clone.querySelectorAll("[data-export-ignore]").forEach((n) => n.remove());
  clone.setAttribute(
    "viewBox",
    `${bounds.x} ${bounds.y} ${bounds.width} ${bounds.height}`,
  );
  clone.setAttribute("width", bounds.width);
  clone.setAttribute("height", bounds.height);
  clone.setAttribute("class", "");
  Object.assign(clone.style, {
    width: `${bounds.width}px`,
    height: `${bounds.height}px`,
    backgroundColor: background,
  });

  const host = document.createElement("div");
  Object.assign(host.style, {
    position: "fixed",
    left: `${-bounds.width - 1000}px`,
    top: "0",
    width: `${bounds.width}px`,
    height: `${bounds.height}px`,
    pointerEvents: "none",
  });
  host.appendChild(clone);
  document.body.appendChild(host);

  const options = {
    width: bounds.width,
    height: bounds.height,
    backgroundColor: background,
    pixelRatio,
  };

  try {
    let dataUrl;
    if (format === "svg") {
      dataUrl = await toSvg(clone, options);
    } else if (format === "jpeg") {
      dataUrl = await toJpeg(clone, { ...options, quality: 0.95 });
    } else {
      dataUrl = await toPng(clone, options);
    }
    return {
      dataUrl,
      width: Math.round(bounds.width * pixelRatio),
      height: Math.round(bounds.height * pixelRatio),
      scale: pixelRatio,
      bounds,
    };
  } finally {
    host.remove();
  }
}
