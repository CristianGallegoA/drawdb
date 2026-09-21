import { useState, useRef } from "react";
import { Button, Input, Select, TextArea } from "@douyinfe/semi-ui";
import ColorPicker from "../ColorPicker";
import { IconDeleteStroked } from "@douyinfe/semi-icons";
import { useAreas, useDiagram, useLayout, useUndoRedo } from "../../../hooks";
import { CARD, LAYER, isCard, tablesOfCard } from "../../../utils/blocks";
import { Action, ObjectType } from "../../../data/constants";
import { useTranslation } from "react-i18next";

export default function AreaInfo({ data, i }) {
  const { t } = useTranslation();
  const { layout } = useLayout();
  const { deleteArea, updateArea } = useAreas();
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
            setUndoStack((prev) => [
              ...prev,
              {
                action: Action.EDIT,
                element: ObjectType.AREA,
                aid: i,
                undo: { kind: data.kind },
                redo: { kind },
                message: t("edit_area", {
                  areaName: data.name,
                  extra: "[kind]",
                }),
              },
            ]);
            setRedoStack([]);
            updateArea(data.id, { kind });
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
    </div>
  );
}
