import { useEffect, useMemo, useRef, useState } from "react";
import { Button, Input, Tooltip } from "@douyinfe/semi-ui";
import { IconDeleteStroked } from "@douyinfe/semi-icons";
import { useTranslation } from "react-i18next";
import { useAreas, useDiagram, useSettings } from "../../hooks";
import { renderedHeight, linkGeometry } from "../../utils/blocks";
import { roundedPolyline } from "../../utils/calcPath";
import { darkBgTheme } from "../../data/constants";

const markerId = (color, kind) => `overview-${kind}-${color.replace("#", "")}`;

const sameLink = (a, b) => a && b && a.key === b.key && a.index === b.index;

/**
 * Every arrow of the overview with where it is drawn. Arrows come from what
 * each card says it points to, never inferred: the story is the designer's.
 */
export function useOverviewLinks(cards) {
  const { tables } = useDiagram();
  return useMemo(() => {
    const byKey = new Map(
      cards
        .filter((card) => card.key)
        .map((card) => [
          card.key,
          { ...card, height: renderedHeight(card, tables) },
        ]),
    );
    const pairs = new Set(
      cards.flatMap((card) =>
        (card.links ?? []).map((link) => `${card.key}>${link.to}`),
      ),
    );
    return cards.flatMap((card) => {
      const from = byKey.get(card.key);
      if (!from) return [];
      return (card.links ?? []).flatMap((link, index) => {
        const to = byKey.get(link.to);
        // A link to a deleted card is skipped, not drawn to nowhere.
        if (!to || to.key === from.key) return [];
        const twoWay = pairs.has(`${link.to}>${card.key}`);
        return [
          {
            key: card.key,
            index,
            link,
            color: card.color,
            from,
            to,
            ...linkGeometry(from, to, { twoWay }),
          },
        ];
      });
    });
  }, [cards, tables]);
}

/**
 * Edits of the overview arrows. A link belongs to its source card, so each one
 * rewrites the areas as a single undoable step.
 */
export function useOverviewLinkActions() {
  const { t } = useTranslation();
  const { areas, commitAreas } = useAreas();

  const cardByKey = (key) => areas.find((area) => area.key === key);
  const message = (key) =>
    t("edit_area", { areaName: cardByKey(key)?.name ?? "", extra: "[links]" });

  const rewrite = (key, fn) =>
    commitAreas(
      areas.map((area) =>
        area.key === key ? { ...area, links: fn(area.links ?? []) } : area,
      ),
      message(key),
    );

  return {
    add(fromKey, toKey) {
      const from = cardByKey(fromKey);
      if (!from || fromKey === toKey) return null;
      const links = from.links ?? [];
      const existing = links.findIndex((l) => l.to === toKey);
      if (existing !== -1) return { key: fromKey, index: existing };
      rewrite(fromKey, (prev) => [
        ...prev,
        { to: toKey, label: "", dashed: false },
      ]);
      return { key: fromKey, index: links.length };
    },
    update(key, index, patch) {
      rewrite(key, (links) =>
        links.map((l, i) => (i === index ? { ...l, ...patch } : l)),
      );
    },
    remove(key, index) {
      rewrite(key, (links) => links.filter((_, i) => i !== index));
    },
    // Reversing moves the link to the other card. If that card already points
    // back, both arrows exist either way, so what flips is their content: the
    // text and style of each one move to the other.
    reverse(key, index) {
      const link = cardByKey(key)?.links?.[index];
      if (!link) return null;
      const target = cardByKey(link.to);
      const back = target?.links ?? [];
      const backIndex = back.findIndex((l) => l.to === key);
      const contentOf = ({ label, dashed }) => ({ label, dashed });
      commitAreas(
        areas.map((area) => {
          if (area.key === key)
            return {
              ...area,
              links:
                backIndex === -1
                  ? (area.links ?? []).filter((_, i) => i !== index)
                  : (area.links ?? []).map((l, i) =>
                      i === index ? { ...l, ...contentOf(back[backIndex]) } : l,
                    ),
            };
          if (area.key === link.to)
            return {
              ...area,
              links:
                backIndex === -1
                  ? [...back, { ...link, to: key }]
                  : back.map((l, i) =>
                      i === backIndex ? { ...l, ...contentOf(link) } : l,
                    ),
            };
          return area;
        }),
        message(key),
      );
      return {
        key: link.to,
        index: backIndex === -1 ? back.length : backIndex,
      };
    },
  };
}

/**
 * The arrows themselves. Each one has a wide invisible stroke so it is easy to
 * grab: a click selects it, a double click goes straight to its text.
 *
 * Drawn in two passes: the lines run under the cards, like draw.io, while
 * the texts (`layer="labels"`) go over them so a tight gap never hides one.
 */
export default function OverviewLinks({
  links,
  selected,
  onSelect,
  readOnly,
  layer = "paths",
}) {
  const { settings } = useSettings();
  const background = settings.mode === "dark" ? darkBgTheme : "white";
  const colors = [...new Set(links.map((l) => l.color))];

  const select = (e, item, edit) => {
    if (e.button !== 0) return;
    e.stopPropagation();
    onSelect({ key: item.key, index: item.index, edit });
  };

  if (layer === "labels") {
    return (
      <g className="select-none">
        {links
          .filter((item) => item.link.label)
          .map((item) => (
            <text
              key={`${item.key}-${item.index}`}
              x={item.label.x}
              y={item.label.y}
              textAnchor="middle"
              dominantBaseline="middle"
              fontSize={13}
              fontWeight={600}
              className={`fill-current text-color ${
                readOnly ? "" : "cursor-pointer"
              }`}
              stroke={background}
              strokeWidth={5}
              strokeLinejoin="round"
              paintOrder="stroke"
              onPointerDown={(e) => !readOnly && select(e, item, false)}
              onDoubleClick={(e) => !readOnly && select(e, item, true)}
            >
              {item.link.label}
            </text>
          ))}
      </g>
    );
  }

  return (
    <g className="select-none">
      <defs>
        {colors.map((color) => (
          <g key={color}>
            <marker
              id={markerId(color, "arrow")}
              viewBox="0 0 10 10"
              refX="9"
              refY="5"
              markerWidth="7"
              markerHeight="7"
              orient="auto-start-reverse"
            >
              <path d="M 0 0 L 10 5 L 0 10 z" fill={color} />
            </marker>
            {/* A dot where the arrow leaves, so direction reads at both ends. */}
            <marker
              id={markerId(color, "origin")}
              viewBox="0 0 10 10"
              refX="5"
              refY="5"
              markerWidth="4"
              markerHeight="4"
            >
              <circle cx="5" cy="5" r="4" fill={color} />
            </marker>
          </g>
        ))}
      </defs>
      {links.map((item) => {
        const d = roundedPolyline(item.points, 12);
        const isSelected = sameLink(item, selected);
        const { link } = item;
        return (
          <g key={`${item.key}-${item.index}`}>
            {isSelected && (
              <path
                d={d}
                fill="none"
                stroke={item.color}
                strokeOpacity={0.25}
                strokeWidth={12}
                strokeLinecap="round"
                className="pointer-events-none"
                data-export-ignore
              />
            )}
            <path
              d={d}
              fill="none"
              stroke={item.color}
              strokeWidth={isSelected ? 3.5 : 2.5}
              strokeDasharray={link.dashed ? "8 6" : undefined}
              markerStart={`url(#${markerId(item.color, "origin")})`}
              markerEnd={`url(#${markerId(item.color, "arrow")})`}
              className="pointer-events-none"
            />
            {/* Hit area: invisible, wide, only on the stroke. */}
            <path
              d={d}
              fill="none"
              stroke="transparent"
              strokeWidth={16}
              style={{ pointerEvents: "stroke" }}
              className={readOnly ? "" : "cursor-pointer"}
              onPointerDown={(e) => !readOnly && select(e, item, false)}
              onDoubleClick={(e) => !readOnly && select(e, item, true)}
              data-export-ignore
            />
          </g>
        );
      })}
    </g>
  );
}

/**
 * Floating editor for the selected arrow, drawn in screen space so it keeps
 * its size at any zoom: the sentence on the arrow plus its few switches.
 */
export function OverviewLinkEditor({
  item,
  toScreen,
  onChangeSelection,
  autoFocus,
}) {
  const { t } = useTranslation();
  const actions = useOverviewLinkActions();
  const [draft, setDraft] = useState(item.link.label ?? "");
  const inputRef = useRef(null);
  // What the stored label is known to be, so Enter followed by the blur of
  // closing the editor commits once, and Escape commits nothing.
  const savedRef = useRef(item.link.label ?? "");

  useEffect(() => {
    setDraft(item.link.label ?? "");
    savedRef.current = item.link.label ?? "";
  }, [item.key, item.index, item.link.label]);

  useEffect(() => {
    if (autoFocus) inputRef.current?.focus();
  }, [autoFocus, item.key, item.index]);

  const commitLabel = () => {
    const label = draft.trim();
    if (savedRef.current === label) return;
    savedRef.current = label;
    actions.update(item.key, item.index, { label });
  };

  const at = toScreen(item.label);

  return (
    <div
      className="absolute z-30 popover-theme rounded-lg shadow-lg p-1.5 flex items-center gap-1"
      style={{
        left: at.x,
        top: at.y + 18,
        transform: "translateX(-50%)",
      }}
      onPointerDown={(e) => e.stopPropagation()}
    >
      <span
        className="text-xs px-1 max-w-[220px] truncate shrink-0"
        title={`${item.from.name} → ${item.to.name}`}
      >
        <span className="font-semibold" style={{ color: item.color }}>
          {item.from.name}
        </span>
        {" → "}
        {item.to.name}
      </span>
      <Input
        ref={inputRef}
        size="small"
        className="!w-[220px]"
        value={draft}
        placeholder={t("link_label_placeholder")}
        onChange={setDraft}
        onBlur={commitLabel}
        onKeyDown={(e) => {
          if (e.key === "Enter") {
            commitLabel();
            onChangeSelection(null);
          }
          if (e.key === "Escape") {
            savedRef.current = draft.trim();
            onChangeSelection(null);
          }
        }}
      />
      <Tooltip content={t("toggle_dashed")}>
        <Button
          size="small"
          theme={item.link.dashed ? "solid" : "borderless"}
          icon={<i className="bi bi-three-dots" />}
          onClick={() =>
            actions.update(item.key, item.index, { dashed: !item.link.dashed })
          }
        />
      </Tooltip>
      <Tooltip content={t("reverse_link")}>
        <Button
          size="small"
          theme="borderless"
          icon={<i className="bi bi-arrow-left-right" />}
          onClick={() =>
            onChangeSelection(actions.reverse(item.key, item.index))
          }
        />
      </Tooltip>
      <Tooltip content={t("delete")}>
        <Button
          size="small"
          theme="borderless"
          type="danger"
          icon={<IconDeleteStroked />}
          onClick={() => {
            actions.remove(item.key, item.index);
            onChangeSelection(null);
          }}
        />
      </Tooltip>
    </div>
  );
}
