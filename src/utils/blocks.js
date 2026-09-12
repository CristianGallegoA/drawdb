import { defaultBlue } from "../data/constants";
import {
  getTableHeight,
  getTableWidth,
  isTableVisible,
  UNCATEGORIZED,
} from "./utils";

// Breathing room between the tables of a category and the block around them.
const BLOCK_PADDING = 36;
// Extra room at the top so the block name and description never sit on a table.
const BLOCK_HEADER_ROOM = 44;

/**
 * Bounding box of a set of tables, grown so the block reads as a container
 * rather than a tight outline.
 */
function boundsOf(tables, { tableWidth, showComments, relationships }) {
  let minX = Infinity;
  let minY = Infinity;
  let maxX = -Infinity;
  let maxY = -Infinity;

  for (const table of tables) {
    const width = getTableWidth(table, tableWidth);
    const height = getTableHeight(table, width, showComments, relationships);
    minX = Math.min(minX, table.x);
    minY = Math.min(minY, table.y);
    maxX = Math.max(maxX, table.x + width);
    maxY = Math.max(maxY, table.y + height);
  }

  if (!Number.isFinite(minX)) return null;

  return {
    x: Math.round(minX - BLOCK_PADDING),
    y: Math.round(minY - BLOCK_PADDING - BLOCK_HEADER_ROOM),
    width: Math.round(maxX - minX + BLOCK_PADDING * 2),
    height: Math.round(maxY - minY + BLOCK_PADDING * 2 + BLOCK_HEADER_ROOM),
  };
}

/**
 * One business block per table category, sized to wrap that category's tables.
 *
 * Blocks are ordinary subject areas tagged with the category they came from, so
 * regenerating refits the ones that already exist instead of piling up
 * duplicates, and any name, color or description the user wrote is preserved.
 * Nothing is ever deleted.
 *
 * @returns {{ areas: Array, created: number, refitted: number }}
 */
export function blocksFromCategories(tables, areas, options = {}) {
  const {
    tableWidth = 220,
    showComments = false,
    relationships = [],
  } = options;

  const byCategory = new Map();
  for (const table of tables) {
    const category = table?.category ?? UNCATEGORIZED;
    // A block for "no category" would just be a box around the leftovers.
    if (category === UNCATEGORIZED) continue;
    if (!byCategory.has(category)) byCategory.set(category, []);
    byCategory.get(category).push(table);
  }

  const next = areas.map((area) => ({ ...area }));
  let created = 0;
  let refitted = 0;

  for (const [category, members] of byCategory) {
    const bounds = boundsOf(members, {
      tableWidth,
      showComments,
      relationships,
    });
    if (!bounds) continue;

    const existing = next.find((area) => area.category === category);

    if (existing) {
      Object.assign(existing, bounds);
      refitted++;
      continue;
    }

    next.push({
      id: next.length,
      name: category.toUpperCase(),
      category,
      description: "",
      color: members[0]?.color ?? defaultBlue,
      locked: false,
      ...bounds,
    });
    created++;
  }

  // Area ids are array indices everywhere else in the app.
  return {
    areas: next.map((area, i) => ({ ...area, id: i })),
    created,
    refitted,
  };
}

const centerOf = (rect) => ({
  x: rect.x + rect.width / 2,
  y: rect.y + rect.height / 2,
});

/**
 * Where the line between two blocks meets this block's border. Starting at the
 * border instead of the center keeps the link out from under the block body.
 */
function edgePoint(rect, towards) {
  const center = centerOf(rect);
  const dx = towards.x - center.x;
  const dy = towards.y - center.y;
  if (dx === 0 && dy === 0) return center;

  const scaleX = dx === 0 ? Infinity : rect.width / 2 / Math.abs(dx);
  const scaleY = dy === 0 ? Infinity : rect.height / 2 / Math.abs(dy);
  const scale = Math.min(scaleX, scaleY);

  return { x: center.x + dx * scale, y: center.y + dy * scale };
}

/**
 * Relationships collapsed to block level: one link per pair of categories that
 * have any relationship between them, carrying how many there are. This is what
 * turns thirty tables into five boxes and a handful of lines.
 */
export function aggregateBlockLinks(tables, relationships, areas) {
  const categoryOf = new Map(
    tables.map((table) => [table.id, table?.category ?? UNCATEGORIZED]),
  );
  const blockOf = new Map();
  for (const area of areas) {
    if (area.category) blockOf.set(area.category, area);
  }

  const links = new Map();

  for (const relationship of relationships) {
    const from = categoryOf.get(relationship.startTableId);
    const to = categoryOf.get(relationship.endTableId);
    if (!from || !to || from === to) continue;

    const a = blockOf.get(from);
    const b = blockOf.get(to);
    if (!a || !b) continue;

    // Undirected: one link per pair regardless of which side declared the FK.
    const key = from < to ? `${from} ${to}` : `${to} ${from}`;
    const existing = links.get(key);
    if (existing) {
      existing.count++;
      continue;
    }
    links.set(key, { from: a, to: b, count: 1 });
  }

  return [...links.values()].map(({ from, to, count }) => {
    const start = edgePoint(from, centerOf(to));
    const end = edgePoint(to, centerOf(from));
    return {
      id: `${from.category}-${to.category}`,
      count,
      start,
      end,
      label: { x: (start.x + end.x) / 2, y: (start.y + end.y) / 2 },
    };
  });
}

/**
 * The tables a block covers, used to report what is inside it.
 */
export function tablesInBlock(tables, area, hiddenCategories = []) {
  if (!area?.category) return [];
  return tables.filter(
    (table) =>
      (table.category ?? UNCATEGORIZED) === area.category &&
      isTableVisible(table, hiddenCategories),
  );
}
