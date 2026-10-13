import { nanoid } from "nanoid";
import { Cardinality, defaultBlue } from "../data/constants";
import { getTableHeight, getTableWidth, UNCATEGORIZED } from "./utils";
import { autoArrange } from "./autoArrange";

// Breathing room between the tables of a category and the block around them.
const BLOCK_PADDING = 36;
// Extra room at the top so the block name and description never sit on a table.
const BLOCK_HEADER_ROOM = 44;

export const CARD = "card";
export const LAYER = "layer";

export const isCard = (area) => area?.kind === CARD;
export const isLayer = (area) => area?.kind === LAYER;
// Cards and blocks live in the overview; a plain area lives in the detail.
export const isOverviewArea = (area) => isCard(area) || isLayer(area);

// A card written from scratch, before the designer resizes it.
const CARD_WIDTH = 320;
// Vertical budget of a card's chrome: badge, title, padding.
const CARD_CHROME_HEIGHT = 74;
const CARD_LINE_HEIGHT = 18;
const CARD_DESCRIPTION_LINE_HEIGHT = 17;
const CARD_PADDING_X = 28;

// First-draft overview layout: one row of cards per block, blocks stacked. It
// only has to be readable; composing it is the designer's job.
const OVERVIEW_CARD_WIDTH = 320;
const OVERVIEW_GAP = 32;
const LAYER_PADDING = 24;
const LAYER_HEADER = 48;

const centerOf = (rect) => ({
  x: rect.x + rect.width / 2,
  y: rect.y + rect.height / 2,
});

/**
 * Bounding box of a set of tables, grown so a block reads as a container
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
 * Height a card or block is drawn at. For a card the stored height is only a
 * floor: it grows rather than clipping the very thing it exists to show.
 */
export const renderedHeight = (area, tables) =>
  isCard(area)
    ? Math.max(area.height, cardContentHeight(area, tables))
    : area.height;

const containsPoint = (rect, point) =>
  point.x >= rect.x &&
  point.x <= rect.x + rect.width &&
  point.y >= rect.y &&
  point.y <= rect.y + rect.height;

// "2 · MONCORREOS · 8 tablas" → "2 · MONCORREOS": the block header counts its
// tables live, so a count typed into the name would only go stale.
const withoutTableCount = (name = "") =>
  name.replace(/\s*[—·-]\s*\d+\s+tablas?\s*$/i, "").trim();

/**
 * First draft of the overview, read from what the model already says: every
 * detail area holding tables becomes a block, every category inside it a card.
 * Tables outside all areas get one block per category.
 *
 * Detail areas are kept as they are; a previous overview is replaced.
 *
 * @returns {{ areas: Array, blocks: number, cards: number }}
 */
export function generateOverview(tables, areas, options = {}) {
  const { origin = { x: 0, y: 0 }, uncategorized = "General" } = options;
  const detailAreas = areas.filter((area) => !isOverviewArea(area));

  const blocks = new Map();
  for (const table of tables) {
    // A table belongs to the detail area its header sits in.
    const home = detailAreas.find((area) => containsPoint(area, table));
    const category = table.category ?? UNCATEGORIZED;
    const blockId = home ? `area:${home.id}` : `category:${category}`;
    if (!blocks.has(blockId)) blocks.set(blockId, { home, cards: new Map() });
    const { cards } = blocks.get(blockId);
    if (!cards.has(category)) cards.set(category, []);
    cards.get(category).push(table);
  }

  // Blocks follow the order of the areas they come from.
  const ordered = [...blocks.values()].sort(
    (a, b) => (a.home?.id ?? areas.length) - (b.home?.id ?? areas.length),
  );

  const next = [...detailAreas];
  let cardCount = 0;
  let y = origin.y;

  for (const { home, cards } of ordered) {
    let x = origin.x + LAYER_PADDING;
    let tallest = 0;

    for (const [category, members] of cards) {
      const card = {
        kind: CARD,
        key: nanoid(8),
        name: (category || uncategorized).toUpperCase(),
        category,
        description: "",
        tableIds: members.map((table) => table.id),
        links: [],
        color: members[0].color ?? home?.color ?? defaultBlue,
        locked: false,
        x,
        y: y + LAYER_HEADER,
        width: OVERVIEW_CARD_WIDTH,
        height: 0,
      };
      card.height = cardContentHeight(card, tables);
      tallest = Math.max(tallest, card.height);
      next.push(card);
      cardCount++;
      x += OVERVIEW_CARD_WIDTH + OVERVIEW_GAP;
    }

    const firstEntry = [...cards][0];
    const firstCategory = firstEntry[0];
    const firstMembers = firstEntry[1];
    const height = LAYER_HEADER + tallest + LAYER_PADDING;
    next.push({
      kind: LAYER,
      key: nanoid(8),
      name:
        withoutTableCount(home?.name) ||
        (firstCategory || uncategorized).toUpperCase(),
      color: home?.color ?? firstMembers[0].color ?? defaultBlue,
      locked: false,
      x: origin.x,
      y,
      width: x - OVERVIEW_GAP + LAYER_PADDING - origin.x,
      height,
    });
    y += height + OVERVIEW_GAP * 2;
  }

  return {
    // Area ids are array indices everywhere else in the app.
    areas: next.map((area, i) => ({ ...area, id: i })),
    blocks: ordered.length,
    cards: cardCount,
  };
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
    key: nanoid(8),
    name: name || category.toUpperCase() || "",
    category,
    tableIds: members.map((table) => table.id),
    links: [],
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
 * Gives a card exactly these tables and takes them off every other card: a
 * table lives in one card, so moving it is a single gesture from either side.
 */
export function assignTables(areas, cardId, tableIds) {
  const moving = new Set(tableIds);
  return areas.map((area) => {
    if (!isCard(area)) return { ...area };
    if (area.id === cardId) return { ...area, tableIds: [...tableIds] };
    return {
      ...area,
      tableIds: (area.tableIds ?? []).filter((id) => !moving.has(id)),
    };
  });
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
 * table added later would quietly never appear in the overview.
 */
export function tablesWithoutCard(tables, areas) {
  const covered = new Set();
  for (const area of areas) {
    if (!isCard(area)) continue;
    for (const id of area.tableIds ?? []) covered.add(id);
  }
  return tables.filter((table) => !covered.has(table.id));
}

/**
 * A card one level down: only its tables, arranged on their own by the same
 * engine as auto-arrange. Nothing is written back, so drilling in works on any
 * detail layout and never disturbs one someone arranged by hand.
 */
export function focusScene(tables, relationships, card, settings) {
  const members = tablesOfCard(tables, card);
  // autoArrange leaves locked tables where they are; here every member moves.
  const placed = new Map(
    autoArrange(
      members.map((table) => ({ ...table, locked: false })),
      relationships,
      settings,
    ).map((p) => [p.id, p]),
  );
  // Locked because these positions are computed, not stored: the canvas
  // already refuses to drag or rubber-band a locked table.
  return members.map((table) => ({
    ...table,
    ...placed.get(table.id),
    locked: true,
  }));
}

/**
 * Bounding box of a set of tables, for framing the camera on them.
 */
export const tablesBounds = (tables, settings, relationships) =>
  boundsOf(tables, {
    tableWidth: settings.tableWidth,
    showComments: settings.showComments,
    relationships,
  });

/**
 * Bounding box of a set of rectangles (areas, cards), for framing a level.
 */
export function rectsBounds(rects) {
  if (rects.length === 0) return null;
  const minX = Math.min(...rects.map((r) => r.x));
  const minY = Math.min(...rects.map((r) => r.y));
  const maxX = Math.max(...rects.map((r) => r.x + r.width));
  const maxY = Math.max(...rects.map((r) => r.y + r.height));
  return { x: minX, y: minY, width: maxX - minX, height: maxY - minY };
}

// Reading order for stepping through cards: rows, then left to right.
export const orderedCards = (cards) =>
  [...cards].sort(
    (a, b) => Math.floor(a.y / 200) - Math.floor(b.y / 200) || a.x - b.x,
  );

const sideMidpoint = (rect, side) =>
  ({
    left: { x: rect.x, y: rect.y + rect.height / 2 },
    right: { x: rect.x + rect.width, y: rect.y + rect.height / 2 },
    top: { x: rect.x + rect.width / 2, y: rect.y },
    bottom: { x: rect.x + rect.width / 2, y: rect.y + rect.height },
  })[side];

/**
 * An elbow between two cards that leaves and enters through the sides facing
 * each other, like a draw.io connector, with the label on the bend.
 */
export function linkRoute(from, to) {
  const a = centerOf(from);
  const b = centerOf(to);
  const gapX = Math.max(
    to.x - (from.x + from.width),
    from.x - (to.x + to.width),
  );
  const gapY = Math.max(
    to.y - (from.y + from.height),
    from.y - (to.y + to.height),
  );

  if (gapX >= gapY) {
    const forward = b.x >= a.x;
    const start = sideMidpoint(from, forward ? "right" : "left");
    const end = sideMidpoint(to, forward ? "left" : "right");
    const midX = (start.x + end.x) / 2;
    return {
      points: [start, { x: midX, y: start.y }, { x: midX, y: end.y }, end],
      label: { x: midX, y: (start.y + end.y) / 2 },
    };
  }

  const down = b.y >= a.y;
  const start = sideMidpoint(from, down ? "bottom" : "top");
  const end = sideMidpoint(to, down ? "top" : "bottom");
  const midY = (start.y + end.y) / 2;
  return {
    points: [start, { x: start.x, y: midY }, { x: end.x, y: midY }, end],
    label: { x: (start.x + end.x) / 2, y: midY },
  };
}

/**
 * Candidate arrows, read from the foreign keys that cross two cards, pointed
 * parent → child (primary key side first). Pairs already linked either way are
 * left out, so accepting a suggestion makes it disappear.
 */
export function suggestLinks(relationships, cards) {
  const cardOf = new Map();
  for (const card of cards) {
    for (const id of card.tableIds ?? []) cardOf.set(id, card);
  }
  const pairOf = (a, b) => [a, b].sort().join("|");
  const linked = new Set(
    cards.flatMap((card) =>
      (card.links ?? []).map((link) => pairOf(card.key, link.to)),
    ),
  );

  const found = new Map();
  for (const r of relationships) {
    const start = cardOf.get(r.startTableId);
    const end = cardOf.get(r.endTableId);
    if (!start || !end || start === end) continue;
    // The FK lives on the start table unless the line was drawn from the "one"
    // side, so parent → child points at the primary key.
    const [from, to] =
      r.cardinality === Cardinality.ONE_TO_MANY ? [start, end] : [end, start];
    const pair = pairOf(from.key, to.key);
    if (linked.has(pair)) continue;
    if (!found.has(pair)) found.set(pair, { from, to, count: 0 });
    found.get(pair).count++;
  }
  return [...found.values()].sort((a, b) => b.count - a.count);
}
