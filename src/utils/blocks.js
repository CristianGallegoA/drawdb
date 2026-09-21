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

export const CARD = "card";
export const LAYER = "layer";

export const isCard = (area) => area?.kind === CARD;
export const isLayer = (area) => area?.kind === LAYER;

// A card written from scratch, before the designer resizes it.
const CARD_WIDTH = 320;
// Vertical budget of a card's chrome: badge, title, padding.
const CARD_CHROME_HEIGHT = 74;
const CARD_LINE_HEIGHT = 18;
const CARD_DESCRIPTION_LINE_HEIGHT = 17;
const CARD_PADDING_X = 28;

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
    const tableIds = members.map((table) => table.id);

    if (existing) {
      Object.assign(existing, bounds, { kind: CARD, tableIds });
      refitted++;
      continue;
    }

    next.push({
      id: next.length,
      kind: CARD,
      name: category.toUpperCase(),
      category,
      tableIds,
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

/**
 * The tables a card lists, resolved fresh from the model on every read. That is
 * the whole point of the card: adding a table to the diagram makes it show up
 * here on its own, instead of rotting like a hand typed list.
 *
 * Ids of tables that no longer exist are skipped rather than rendered blank.
 */
export function tablesOfCard(tables, card) {
  const ids = card?.tableIds;
  if (!Array.isArray(ids) || ids.length === 0) return [];

  const byId = new Map(tables.map((table) => [table.id, table]));
  return ids.map((id) => byId.get(id)).filter(Boolean);
}

/**
 * Height a card's content asks for: badge and title, the wrapped description,
 * and one row per table. The stored height is only a floor, so a card never
 * clips what it is supposed to communicate.
 */
export function cardContentHeight(card, tables, measureLines) {
  const rows = tablesOfCard(tables, card).length;
  const width = Math.max(card?.width ?? CARD_WIDTH, 120) - CARD_PADDING_X;

  const descriptionLines = card?.description
    ? typeof measureLines === "function"
      ? measureLines(card.description, width)
      : card.description.split("\n").length
    : 0;

  return Math.round(
    CARD_CHROME_HEIGHT +
      descriptionLines * CARD_DESCRIPTION_LINE_HEIGHT +
      rows * CARD_LINE_HEIGHT,
  );
}

/**
 * A new card built from whatever tables are selected on the canvas.
 *
 * A table belongs to exactly one card, so the selection is taken away from any
 * card that already held it. That single rule is what makes splitting a
 * category into two cards a one gesture operation.
 */
export function cardFromSelection(tables, areas, tableIds, options = {}) {
  const { name = "", description = "", at } = options;

  const members = tables.filter((table) => tableIds.includes(table.id));
  if (members.length === 0) return { areas, card: null };

  const memberIds = new Set(members.map((table) => table.id));

  // Take the selection away from every other card.
  const next = areas.map((area) =>
    isCard(area) && Array.isArray(area.tableIds)
      ? {
          ...area,
          tableIds: area.tableIds.filter((id) => !memberIds.has(id)),
        }
      : { ...area },
  );

  const categories = new Set(
    members.map((table) => table.category ?? UNCATEGORIZED),
  );
  const category = categories.size === 1 ? [...categories][0] : "";

  const card = {
    id: next.length,
    kind: CARD,
    name: name || category.toUpperCase() || "",
    category,
    tableIds: members.map((table) => table.id),
    description,
    color: members[0]?.color ?? defaultBlue,
    locked: false,
    x: Math.round(at?.x ?? Math.min(...members.map((t) => t.x))),
    y: Math.round(at?.y ?? Math.min(...members.map((t) => t.y))),
    width: CARD_WIDTH,
    height: 0,
  };
  card.height = cardContentHeight(card, tables);

  next.push(card);

  return {
    areas: next.map((area, i) => ({ ...area, id: i })),
    card,
  };
}

/**
 * The cards sitting inside a layer. Geometric containment is enough here: the
 * designer places the layer around the cards, so what looks inside is inside.
 */
export function layerMembers(areas, layer) {
  if (!isLayer(layer)) return [];

  return areas.filter((area) => {
    if (!isCard(area)) return false;
    const center = centerOf(area);
    return (
      center.x >= layer.x &&
      center.x <= layer.x + layer.width &&
      center.y >= layer.y &&
      center.y <= layer.y + layer.height
    );
  });
}

/**
 * How many tables a layer covers, for the "— 14 tablas" label. Counted through
 * a set so a table listed twice by mistake is not counted twice.
 */
export function layerTableCount(tables, areas, layer) {
  const ids = new Set();
  for (const card of layerMembers(areas, layer)) {
    for (const table of tablesOfCard(tables, card)) ids.add(table.id);
  }
  return ids.size;
}

/**
 * Tables no card lists. The safety net of explicit membership: without it a
 * table added later would quietly never appear in the business view.
 */
export function tablesWithoutCard(tables, areas) {
  const covered = new Set();
  for (const area of areas) {
    if (!isCard(area)) continue;
    for (const id of area.tableIds ?? []) covered.add(id);
  }
  return tables.filter((table) => !covered.has(table.id));
}
