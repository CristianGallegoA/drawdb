import { useState, useRef } from "react";
import { nanoid } from "nanoid";
import { Button, Input, Select, TextArea } from "@douyinfe/semi-ui";
import ColorPicker from "../ColorPicker";
import { IconDeleteStroked } from "@douyinfe/semi-icons";
import { useAreas, useDiagram, useLayout, useUndoRedo } from "../../../hooks";
import {
  CARD,
  LAYER,
  assignTables,
  isCard,
  tablesOfCard,
} from "../../../utils/blocks";
import { Action, ObjectType } from "../../../data/constants";
import { useTranslation } from "react-i18next";

export default function AreaInfo({ data, i }) {
  const { t } = useTranslation();
  const { layout } = useLayout();
  const { areas, deleteArea, updateArea, commitAreas } = useAreas();
  const { tables } = useDiagram();
  const { setUndoStack, setRedoStack } = useUndoRedo();
  const [editField, setEditField] = useState({});
  const initialColorRef = useRef(data.color);

  const handleColorPick = (color) => {
    setUndoStack((prev) => {
      let undoColor = initialColorRef.current;
      const lastColorChange = prev.findLast(
        (e) =>
          e.element === ObjectType.AREA &&
          e.aid === data.id &&
          e.action === Action.EDIT &&
          e.redo?.color,
      );
      if (lastColorChange) {
        undoColor = lastColorChange.redo.color;
      }

      if (color === undoColor) return prev;

      const newStack = [
        ...prev,
        {
          action: Action.EDIT,
          element: ObjectType.AREA,
          aid: i,
          undo: { color: undoColor },
          redo: { color: color },
          message: t("edit_area", {
            areaName: data.name,
            extra: "[color]",
          }),
        },
      ];
      return newStack;
    });
    setRedoStack([]);
  };

  return (
    <div id={`scroll_area_${data.id}`} className="my-3">
      <div className="flex gap-2 items-center">
        <Input
          value={data.name}
          placeholder={t("name")}
          readonly={layout.readOnly}
          onChange={(value) => updateArea(data.id, { name: value })}
          onFocus={(e) => setEditField({ name: e.target.value })}
          onBlur={(e) => {
            if (e.target.value === editField.name) return;
            setUndoStack((prev) => [
              ...prev,
              {
                action: Action.EDIT,
                element: ObjectType.AREA,
                aid: i,
                undo: editField,
                redo: { name: e.target.value },
                message: t("edit_area", {
                  areaName: e.target.value,
                  extra: "[name]",
                }),
              },
            ]);
            setRedoStack([]);
          }}
        />
        <ColorPicker
          usePopover={true}
          value={data.color}
          readOnly={layout.readOnly}
          onChange={(color) => updateArea(i, { color })}
          onColorPick={(color) => handleColorPick(color)}
        />
        <Button
          type="danger"
          disabled={layout.readOnly}
          icon={<IconDeleteStroked />}
          onClick={() => deleteArea(i, true)}
        />
      </div>
      <div className="mt-2 flex items-center gap-2">
        <Select
          className="grow"
          value={data.kind ?? ""}
          disabled={layout.readOnly}
          optionList={[
            { label: t("plain_area"), value: "" },
            { label: t("make_card"), value: CARD },
            { label: t("make_layer"), value: LAYER },
          ]}
          onChange={(value) => {
            const kind = value || undefined;
            if (kind === data.kind) return;
            // A card needs a stable key (links point at it) and its own table
            // list, so becoming one fills those in once.
            const patch =
              kind === CARD
                ? {
                    kind,
                    key: data.key ?? nanoid(8),
                    tableIds: data.tableIds ?? [],
                    links: data.links ?? [],
                  }
                : { kind };
            setUndoStack((prev) => [
              ...prev,
              {
                action: Action.EDIT,
                element: ObjectType.AREA,
                aid: i,
                undo: {
                  kind: data.kind,
                  key: data.key,
                  tableIds: data.tableIds,
                  links: data.links,
                },
                redo: patch,
                message: t("edit_area", {
                  areaName: data.name,
                  extra: "[kind]",
                }),
              },
            ]);
            setRedoStack([]);
            updateArea(data.id, patch);
          }}
        />
        {isCard(data) && (
          <span className="text-xs opacity-70 shrink-0">
            {t("table_count", { count: tablesOfCard(tables, data).length })}
          </span>
        )}
      </div>
      <TextArea
        className="mt-2"
        value={data.description ?? ""}
        placeholder={t("block_description_placeholder")}
        autosize
        rows={2}
        readonly={layout.readOnly}
        onChange={(value) => updateArea(data.id, { description: value })}
        onFocus={(e) => setEditField({ description: e.target.value })}
        onBlur={(e) => {
          if (e.target.value === editField.description) return;
          setUndoStack((prev) => [
            ...prev,
            {
              action: Action.EDIT,
              element: ObjectType.AREA,
              aid: i,
              undo: editField,
              redo: { description: e.target.value },
              message: t("edit_area", {
                areaName: data.name,
                extra: "[description]",
              }),
            },
          ]);
          setRedoStack([]);
        }}
      />
      {isCard(data) && (
        <Select
          className="mt-2 w-full"
          multiple
          filter
          maxTagCount={6}
          placeholder={t("card_tables")}
          value={data.tableIds ?? []}
          optionList={tables.map((table) => ({
            label: table.name,
            value: table.id,
          }))}
          disabled={layout.readOnly}
          onChange={(ids) =>
            commitAreas(
              assignTables(areas, data.id, ids),
              t("edit_area", { areaName: data.name, extra: "[tables]" }),
            )
          }
        />
      )}
      {isCard(data) && <CardLinks card={data} />}
    </div>
  );
}

function CardLinks({ card }) {
  const { t } = useTranslation();
  const { areas, updateArea, commitAreas } = useAreas();
  const { layout } = useLayout();
  const { setUndoStack, setRedoStack } = useUndoRedo();
  const editRef = useRef(null);

  const others = areas.filter((area) => isCard(area) && area.key !== card.key);
  const links = card.links ?? [];
  const nameOf = (key) => others.find((area) => area.key === key)?.name ?? "?";
  const message = t("edit_area", { areaName: card.name, extra: "[links]" });

  const setLinks = (next) =>
    commitAreas(
      areas.map((area) =>
        area.id === card.id ? { ...area, links: next } : area,
      ),
      message,
    );

  // A link belongs to its source card, so reversing moves it to the other one.
  const reverse = (i) =>
    commitAreas(
      areas.map((area) => {
        if (area.id === card.id)
          return { ...area, links: links.filter((_, j) => j !== i) };
        if (area.key === links[i].to)
          return {
            ...area,
            links: [...(area.links ?? []), { ...links[i], to: card.key }],
          };
        return area;
      }),
      message,
    );

  return (
    <div className="mt-3">
      <div className="text-xs font-semibold opacity-70 mb-1">
        {t("card_links")}
      </div>
      {links.map((link, i) => (
        <div key={`${link.to}-${i}`} className="flex items-center gap-1 mb-1">
          <span
            className="text-xs w-24 shrink-0 truncate"
            title={nameOf(link.to)}
          >
            → {nameOf(link.to)}
          </span>
          <Input
            size="small"
            value={link.label ?? ""}
            placeholder={t("link_label_placeholder")}
            readonly={layout.readOnly}
            onChange={(label) =>
              updateArea(card.id, {
                links: links.map((l, j) => (j === i ? { ...l, label } : l)),
              })
            }
            onFocus={() => {
              editRef.current = areas.map((area) => ({ ...area }));
            }}
            onBlur={(e) => {
              const before = editRef.current;
              if (!before) return;
              const wasLabel = before.find((a) => a.id === card.id)?.links?.[i]
                ?.label;
              if ((wasLabel ?? "") === e.target.value) return;
              setUndoStack((prev) => [
                ...prev,
                {
                  action: Action.EDIT,
                  element: ObjectType.AREA,
                  component: "bulk",
                  undo: before,
                  redo: areas.map((area) => ({ ...area })),
                  message,
                },
              ]);
              setRedoStack([]);
            }}
          />
          <Button
            size="small"
            theme="borderless"
            disabled={layout.readOnly}
            title={t("toggle_dashed")}
            icon={<i className="bi bi-three-dots" />}
            onClick={() =>
              setLinks(
                links.map((l, j) => (j === i ? { ...l, dashed: !l.dashed } : l)),
              )
            }
          />
          <Button
            size="small"
            theme="borderless"
            disabled={layout.readOnly}
            title={t("reverse_link")}
            icon={<i className="bi bi-arrow-left-right" />}
            onClick={() => reverse(i)}
          />
          <Button
            size="small"
            theme="borderless"
            type="danger"
            disabled={layout.readOnly}
            icon={<IconDeleteStroked />}
            onClick={() => setLinks(links.filter((_, j) => j !== i))}
          />
        </div>
      ))}
      <Select
        size="small"
        className="w-full mt-1"
        filter
        value={null}
        placeholder={t("add_link")}
        disabled={layout.readOnly}
        optionList={others
          .filter((area) => !links.some((l) => l.to === area.key))
          .map((area) => ({ label: area.name, value: area.key }))}
        onChange={(to) =>
          setLinks([...links, { to, label: "", dashed: false }])
        }
      />
    </div>
  );
}
