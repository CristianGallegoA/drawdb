import {
  tableFieldHeight,
  tableHeaderHeight,
  RelationshipPathStyle,
} from "../data/constants";
import { getCommentHeight, getFieldOffsetY } from "./utils";

/**
 * Vertical center of a field row, in diagram space.
 */
function anchorY(table, fieldIndex, width, showComments) {
  return (
    table.y +
    tableHeaderHeight +
    getCommentHeight(table.comment, width, showComments) +
    getFieldOffsetY(table.fields ?? [], fieldIndex, width, showComments) +
    tableFieldHeight / 2
  );
}

/**
 * Generates an SVG path string to visually represent a relationship between two fields.
 *
 * @param {{
 *   startTable: { x: number, y: number, width?: number },
 *   endTable: { x: number, y: number, width?: number },
 *   startFieldIndex: number,
 *   endFieldIndex: number
 * }} r - Relationship data.
 * @param {number} tableWidth - Fallback width for tables without an explicit one.
 * @param {number} zoom - Zoom level (used to scale vertical spacing).
 * @returns {string} SVG path "d" attribute string.
 */
export function calcPath(r, tableWidth = 200, zoom = 1, showComments = true) {
  if (!r) {
    return "";
  }

  // Tables can be resized individually, so each side has its own width.
  const startWidth = r.startTable.width ?? tableWidth;
  const endWidth = r.endTable.width ?? tableWidth;
  const w1 = startWidth * zoom;
  const w2 = endWidth * zoom;

  let x1 = r.startTable.x;
  let y1 =
    r.startTable.y +
    getFieldOffsetY(
      r.startTable.fields ?? [],
      r.startFieldIndex,
      startWidth,
      showComments,
    ) +
    tableHeaderHeight +
    getCommentHeight(r.startTable.comment, startWidth, showComments) +
    tableFieldHeight / 2;
  let x2 = r.endTable.x;
  let y2 =
    r.endTable.y +
    getFieldOffsetY(
      r.endTable.fields ?? [],
      r.endFieldIndex,
      endWidth,
      showComments,
    ) +
    getCommentHeight(r.endTable.comment, endWidth, showComments) +
    tableHeaderHeight +
    tableFieldHeight / 2;

  let radius = 10 * zoom;
  const midX = (x2 + x1 + w1) / 2;
  const endX = x2 + w2 < x1 ? x2 + w2 : x2;

  if (Math.abs(y1 - y2) <= 36 * zoom) {
    radius = Math.abs(y2 - y1) / 3;
    if (radius <= 2) {
      if (x1 + w1 <= x2) return `M ${x1 + w1} ${y1} L ${x2} ${y2 + 0.1}`;
      else if (x2 + w2 < x1) return `M ${x1} ${y1} L ${x2 + w2} ${y2 + 0.1}`;
    }
  }

  if (y1 <= y2) {
    if (x1 + w1 <= x2) {
      return `M ${x1 + w1} ${y1} L ${
        midX - radius
      } ${y1} A ${radius} ${radius} 0 0 1 ${midX} ${y1 + radius} L ${midX} ${
        y2 - radius
      } A ${radius} ${radius} 0 0 0 ${midX + radius} ${y2} L ${endX} ${y2}`;
    } else if (x2 <= x1 + w1 && x1 <= x2) {
      return `M ${x1 + w1} ${y1} L ${
        x2 + w2
      } ${y1} A ${radius} ${radius} 0 0 1 ${x2 + w2 + radius} ${
        y1 + radius
      } L ${x2 + w2 + radius} ${y2 - radius} A ${radius} ${radius} 0 0 1 ${
        x2 + w2
      } ${y2} L ${x2 + w2} ${y2}`;
    } else if (x2 + w2 >= x1 && x2 + w2 <= x1 + w1) {
      return `M ${x1} ${y1} L ${
        x2 - radius
      } ${y1} A ${radius} ${radius} 0 0 0 ${x2 - radius - radius} ${
        y1 + radius
      } L ${x2 - radius - radius} ${y2 - radius} A ${radius} ${radius} 0 0 0 ${
        x2 - radius
      } ${y2} L ${x2} ${y2}`;
    } else {
      return `M ${x1} ${y1} L ${
        midX + radius
      } ${y1} A ${radius} ${radius} 0 0 0 ${midX} ${y1 + radius} L ${midX} ${
        y2 - radius
      } A ${radius} ${radius} 0 0 1 ${midX - radius} ${y2} L ${endX} ${y2}`;
    }
  } else {
    if (x1 + w1 <= x2) {
      return `M ${x1 + w1} ${y1} L ${
        midX - radius
      } ${y1} A ${radius} ${radius} 0 0 0 ${midX} ${y1 - radius} L ${midX} ${
        y2 + radius
      } A ${radius} ${radius} 0 0 1 ${midX + radius} ${y2} L ${endX} ${y2}`;
    } else if (x1 + w1 >= x2 && x1 + w1 <= x2 + w2) {
      return `M ${x1} ${y1} L ${
        x1 - radius - radius
      } ${y1} A ${radius} ${radius} 0 0 1 ${x1 - radius - radius - radius} ${
        y1 - radius
      } L ${x1 - radius - radius - radius} ${
        y2 + radius
      } A ${radius} ${radius} 0 0 1 ${
        x1 - radius - radius
      } ${y2} L ${endX} ${y2}`;
    } else if (x1 >= x2 && x1 <= x2 + w2) {
      return `M ${x1 + w1} ${y1} L ${
        x1 + w1 + radius
      } ${y1} A ${radius} ${radius} 0 0 0 ${x1 + w1 + radius + radius} ${
        y1 - radius
      } L ${x1 + w1 + radius + radius} ${
        y2 + radius
      } A ${radius} ${radius} 0 0 0 ${x1 + w1 + radius} ${y2} L ${
        x2 + w2
      } ${y2}`;
    } else {
      return `M ${x1} ${y1} L ${
        midX + radius
      } ${y1} A ${radius} ${radius} 0 0 1 ${midX} ${y1 - radius} L ${midX} ${
        y2 + radius
      } A ${radius} ${radius} 0 0 0 ${midX - radius} ${y2} L ${endX} ${y2}`;
    }
  }
}

/**
 * Builds a "fork" path for a composite (multi-column) foreign key: a short
 * stub from every column on each table converges to a vertical collector,
 * the two collectors are joined by a single orthogonal trunk, and the trunk
 * forks back out to the columns on the other table.
 *
 * @param {{
 *   startTable: { x: number, y: number, comment?: string, fields?: any[], width?: number },
 *   endTable: { x: number, y: number, comment?: string, fields?: any[], width?: number },
 *   startFieldIndices: number[],
 *   endFieldIndices: number[],
 * }} r
 * @returns {{
 *   path: string,
 *   labelPoint: { x: number, y: number },
 *   startCardinality: { x: number, y: number },
 *   endCardinality: { x: number, y: number },
 * } | null}
 */
export function calcCompositePath(
  r,
  tableWidth = 200,
  zoom = 1,
  showComments = true,
) {
  if (!r || !r.startFieldIndices?.length || !r.endFieldIndices?.length) {
    return null;
  }

  const startWidth = r.startTable.width ?? tableWidth;
  const endWidth = r.endTable.width ?? tableWidth;
  const w1 = startWidth * zoom;
  const w2 = endWidth * zoom;
  const anchorOf = (table, index, width) =>
    anchorY(table, index, width, showComments);

  const startYs = r.startFieldIndices.map((i) =>
    anchorOf(r.startTable, i, startWidth),
  );
  const endYs = r.endFieldIndices.map((i) => anchorOf(r.endTable, i, endWidth));

  // Connect each table on the edge facing the other table.
  const startCenter = r.startTable.x + w1 / 2;
  const endCenter = r.endTable.x + w2 / 2;
  const startIsLeft = startCenter <= endCenter;
  const startX = startIsLeft ? r.startTable.x + w1 : r.startTable.x;
  const endX = startIsLeft ? r.endTable.x : r.endTable.x + w2;
  const dir = startIsLeft ? 1 : -1;
  const fork = 24 * zoom;
  const mergeStartX = startX + dir * fork;
  const mergeEndX = endX - dir * fork;

  const minS = Math.min(...startYs);
  const maxS = Math.max(...startYs);
  const minE = Math.min(...endYs);
  const maxE = Math.max(...endYs);
  const trunkStartY = (minS + maxS) / 2;
  const trunkEndY = (minE + maxE) / 2;
  const midX = (mergeStartX + mergeEndX) / 2;

  const radius = 10 * zoom;

  // A column branch: horizontal stub from the table edge to the collector x,
  // a rounded corner, then a vertical run down to the trunk level. Branches
  // overlap on the collector x, reading as a single fork that converges into
  // the trunk.
  const branch = (fromX, fromY, cornerX, toY) => {
    if (Math.abs(fromY - toY) < 0.5) {
      return `M ${fromX} ${fromY} L ${cornerX} ${toY}`;
    }
    const dx = Math.sign(cornerX - fromX);
    const dy = Math.sign(toY - fromY);
    const r = Math.min(radius, Math.abs(toY - fromY), Math.abs(cornerX - fromX));
    return `M ${fromX} ${fromY} L ${cornerX - dx * r} ${fromY} Q ${cornerX} ${fromY} ${cornerX} ${fromY + dy * r} L ${cornerX} ${toY}`;
  };

  // The trunk: a rounded orthogonal connector between the two collectors.
  const trunk = (sx, sy, ex, ey) => {
    if (Math.abs(sy - ey) < 0.5) {
      return `M ${sx} ${sy} L ${ex} ${ey}`;
    }
    const mx = (sx + ex) / 2;
    const dxs = Math.sign(mx - sx);
    const dxe = Math.sign(ex - mx);
    const dy = Math.sign(ey - sy);
    const r = Math.min(
      radius,
      Math.abs(ey - sy) / 2,
      Math.abs(mx - sx) || radius,
    );
    return `M ${sx} ${sy} L ${mx - dxs * r} ${sy} Q ${mx} ${sy} ${mx} ${sy + dy * r} L ${mx} ${ey - dy * r} Q ${mx} ${ey} ${mx + dxe * r} ${ey} L ${ex} ${ey}`;
  };

  const segs = [];
  // Each start column forks into the trunk.
  startYs.forEach((y) => segs.push(branch(startX, y, mergeStartX, trunkStartY)));
  // Single trunk between the two collectors.
  segs.push(trunk(mergeStartX, trunkStartY, mergeEndX, trunkEndY));
  // Each end column forks out of the trunk.
  endYs.forEach((y) => segs.push(branch(endX, y, mergeEndX, trunkEndY)));

  return {
    path: segs.join(" "),
    labelPoint: { x: midX, y: (trunkStartY + trunkEndY) / 2 },
    startCardinality: { x: mergeStartX, y: trunkStartY },
    endCardinality: { x: mergeEndX, y: trunkEndY },
  };
}

const CORNER_RADIUS = 10;
const CURVE_TENSION = 0.5;
const MIN_CURVE_HANDLE = 40;

/**
 * The full polyline a routed relationship runs through: the anchor on the
 * start table, every user waypoint, and the anchor on the end table. The side
 * each anchor sits on is decided by the neighbouring waypoint, so dragging a
 * line around a table makes it leave from the sensible edge.
 */
export function getRoutedPoints(
  r,
  tableWidth = 200,
  showComments = true,
  waypoints = [],
) {
  if (!r) return [];

  const startWidth = r.startTable.width ?? tableWidth;
  const endWidth = r.endTable.width ?? tableWidth;

  const y1 = anchorY(r.startTable, r.startFieldIndex, startWidth, showComments);
  const y2 = anchorY(r.endTable, r.endFieldIndex, endWidth, showComments);

  // With no waypoints each anchor faces the other table.
  const head = waypoints[0] ?? { x: r.endTable.x + endWidth / 2, y: y2 };
  const tail = waypoints[waypoints.length - 1] ?? {
    x: r.startTable.x + startWidth / 2,
    y: y1,
  };

  const startOnRight = head.x >= r.startTable.x + startWidth / 2;
  const endOnRight = tail.x >= r.endTable.x + endWidth / 2;

  return [
    {
      x: startOnRight ? r.startTable.x + startWidth : r.startTable.x,
      y: y1,
      side: startOnRight ? 1 : -1,
    },
    ...waypoints.map((p) => ({ x: p.x, y: p.y })),
    {
      x: endOnRight ? r.endTable.x + endWidth : r.endTable.x,
      y: y2,
      side: endOnRight ? 1 : -1,
    },
  ];
}

// Inserts an elbow between points that are neither vertically nor horizontally
// aligned, turning an arbitrary polyline into an orthogonal one.
function expandToOrthogonal(points) {
  const out = [points[0]];
  for (let i = 1; i < points.length; i++) {
    const a = out[out.length - 1];
    const b = points[i];
    if (Math.abs(a.x - b.x) > 0.5 && Math.abs(a.y - b.y) > 0.5) {
      const mx = (a.x + b.x) / 2;
      out.push({ x: mx, y: a.y }, { x: mx, y: b.y });
    }
    out.push(b);
  }
  return out;
}

const distance = (a, b) => Math.hypot(b.x - a.x, b.y - a.y);

const towards = (from, to, d) => {
  const length = distance(from, to) || 1;
  return {
    x: from.x + ((to.x - from.x) * d) / length,
    y: from.y + ((to.y - from.y) * d) / length,
  };
};

// Rounds every vertex of a polyline with a quadratic, matching the look of the
// automatic paths.
export function roundedPolyline(points, radius) {
  let d = `M ${points[0].x} ${points[0].y}`;
  for (let i = 1; i < points.length - 1; i++) {
    const p = points[i];
    const r = Math.min(
      radius,
      distance(points[i - 1], p) / 2,
      distance(p, points[i + 1]) / 2,
    );
    const a = towards(p, points[i - 1], r);
    const b = towards(p, points[i + 1], r);
    d += ` L ${a.x} ${a.y} Q ${p.x} ${p.y} ${b.x} ${b.y}`;
  }
  const last = points[points.length - 1];
  return `${d} L ${last.x} ${last.y}`;
}

// A single cubic leaving both tables horizontally, so the curve reads as a
// connector and not as a diagonal.
function curveThroughTwoPoints(start, end) {
  const handle = Math.max(MIN_CURVE_HANDLE, Math.abs(end.x - start.x) / 2);
  const c1 = { x: start.x + (start.side ?? 1) * handle, y: start.y };
  const c2 = { x: end.x + (end.side ?? -1) * handle, y: end.y };
  return `M ${start.x} ${start.y} C ${c1.x} ${c1.y} ${c2.x} ${c2.y} ${end.x} ${end.y}`;
}

// Catmull-Rom converted to cubic beziers: a smooth curve that passes exactly
// through every waypoint.
function catmullRomPath(points) {
  if (points.length < 3) {
    return curveThroughTwoPoints(points[0], points[points.length - 1]);
  }

  let d = `M ${points[0].x} ${points[0].y}`;
  for (let i = 0; i < points.length - 1; i++) {
    const p0 = points[i - 1] ?? points[i];
    const p1 = points[i];
    const p2 = points[i + 1];
    const p3 = points[i + 2] ?? p2;
    const c1 = {
      x: p1.x + ((p2.x - p0.x) * CURVE_TENSION) / 3,
      y: p1.y + ((p2.y - p0.y) * CURVE_TENSION) / 3,
    };
    const c2 = {
      x: p2.x - ((p3.x - p1.x) * CURVE_TENSION) / 3,
      y: p2.y - ((p3.y - p1.y) * CURVE_TENSION) / 3,
    };
    d += ` C ${c1.x} ${c1.y} ${c2.x} ${c2.y} ${p2.x} ${p2.y}`;
  }
  return d;
}

/**
 * Path for a relationship the user has taken control of: it runs through the
 * given waypoints in the requested shape.
 */
export function calcRoutedPath(
  r,
  tableWidth = 200,
  showComments = true,
  waypoints = [],
  style = RelationshipPathStyle.ORTHOGONAL,
) {
  const points = getRoutedPoints(r, tableWidth, showComments, waypoints);
  if (points.length < 2) return "";

  if (style === RelationshipPathStyle.STRAIGHT) {
    return points.map((p, i) => `${i ? "L" : "M"} ${p.x} ${p.y}`).join(" ");
  }

  if (style === RelationshipPathStyle.CURVED) {
    return catmullRomPath(points);
  }

  return roundedPolyline(expandToOrthogonal(points), CORNER_RADIUS);
}

function squaredDistanceToSegment(p, a, b) {
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  const lengthSq = dx * dx + dy * dy;
  const t =
    lengthSq === 0
      ? 0
      : Math.max(
          0,
          Math.min(1, ((p.x - a.x) * dx + (p.y - a.y) * dy) / lengthSq),
        );
  const projX = a.x + t * dx;
  const projY = a.y + t * dy;
  return (p.x - projX) ** 2 + (p.y - projY) ** 2;
}

/**
 * Index of the polyline segment closest to a point. Used to decide where a new
 * waypoint belongs when the user grabs the line.
 */
export function nearestSegmentIndex(point, points) {
  let best = 0;
  let bestDistance = Infinity;
  for (let i = 0; i < points.length - 1; i++) {
    const d = squaredDistanceToSegment(point, points[i], points[i + 1]);
    if (d < bestDistance) {
      bestDistance = d;
      best = i;
    }
  }
  return best;
}
