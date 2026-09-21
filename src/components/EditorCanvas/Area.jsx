import { useMemo, useRef, useState } from "react";
import {
  Button,
  ButtonGroup,
  Popover,
  Input,
  TextArea,
  Divider,
} from "@douyinfe/semi-ui";
import ColorPicker from "../EditorSidePanel/ColorPicker";
import {
  IconEdit,
  IconDeleteStroked,
  IconLock,
  IconUnlock,
} from "@douyinfe/semi-icons";
import { Tab, Action, ObjectType, State } from "../../data/constants";
import TableCategoryBadge from "../TableCategoryBadge";
import {
  cardContentHeight,
  isCard,
  isLayer,
  layerTableCount,
  tablesOfCard,
} from "../../utils/blocks";
import {
  useLayout,
  useSettings,
  useUndoRedo,
  useSelect,
  useAreas,
  useDiagram,
  useSaveState,
} from "../../hooks";
import { useTranslation } from "react-i18next";
import { useHover } from "usehooks-ts";

export default function Area({
  data,
  onPointerDown,
  setResize,
  setInitDimensions,
}) {
  const ref = useRef(null);
  const isHovered = useHover(ref);
  const { layout } = useLayout();
  const { settings } = useSettings();
  const { tables } = useDiagram();
  const { setSaveState } = useSaveState();
  const { areas, updateArea } = useAreas();
  const { t } = useTranslation();
  const {
    selectedElement,
    setSelectedElement,
    bulkSelectedElements,
    setBulkSelectedElements,
  } = useSelect();

  const handleResize = (e, dir) => {
    setResize({ id: data.id, dir: dir });
    setInitDimensions({
      x: data.x,
      y: data.y,
      width: data.width,
      height: data.height,
    });
  };

  const lockUnlockArea = (e) => {
    const locking = !data.locked;
    updateArea(data.id, { locked: locking });

    const lockArea = () => {
      setSelectedElement({
        ...selectedElement,
        element: ObjectType.NONE,
        id: -1,
        open: false,
      });
      setBulkSelectedElements((prev) =>
        prev.filter((el) => el.id !== data.id || el.type !== ObjectType.AREA),
      );
    };

    const unlockArea = () => {
      const elementInBulk = {
        id: data.id,
        type: ObjectType.AREA,
        initialCoords: { x: data.x, y: data.y },
        currentCoords: { x: data.x, y: data.y },
      };
      if (e.ctrlKey || e.metaKey) {
        setBulkSelectedElements((prev) => [...prev, elementInBulk]);
      } else {
        setBulkSelectedElements([elementInBulk]);
      }
      setSelectedElement((prev) => ({
        ...prev,
        element: ObjectType.AREA,
        id: data.id,
        open: false,
      }));
    };

    if (locking) {
      lockArea();
    } else {
      unlockArea();
    }
  };

  const edit = () => {
    if (layout.sidebar) {
      setSelectedElement((prev) => ({
        ...prev,
        element: ObjectType.AREA,
        id: data.id,
        currentTab: Tab.AREAS,
        open: true,
      }));
      if (selectedElement.currentTab !== Tab.AREAS) return;
      document
        .getElementById(`scroll_area_${data.id}`)
        .scrollIntoView({ behavior: "smooth" });
    } else {
      setSelectedElement((prev) => ({
        ...prev,
        element: ObjectType.AREA,
        id: data.id,
        open: true,
      }));
    }
  };

  const onClickOutSide = () => {
    if (selectedElement.editFromToolbar) {
      setSelectedElement((prev) => ({
        ...prev,
        editFromToolbar: false,
      }));
      return;
    }
    setSelectedElement((prev) => ({
      ...prev,
      open: false,
    }));
    setSaveState(State.SAVING);
  };

  const areaIsOpen = () =>
    selectedElement.element === ObjectType.AREA &&
    selectedElement.id === data.id &&
    selectedElement.open;

  const isSelected = useMemo(() => {
    return (
      (selectedElement.id === data.id &&
        selectedElement.element === ObjectType.AREA) ||
      bulkSelectedElements.some(
        (e) => e.type === ObjectType.AREA && e.id === data.id,
      )
    );
  }, [selectedElement, data, bulkSelectedElements]);

  const cardTables = isCard(data) ? tablesOfCard(tables, data) : [];
  // The stored height is a floor: a card grows rather than clipping the very
  // thing it exists to show.
  const height = isCard(data)
    ? Math.max(data.height, cardContentHeight(data, tables))
    : data.height;
  const tableCount = isLayer(data) ? layerTableCount(tables, areas, data) : 0;

  return (
    <g ref={ref}>
      <foreignObject
        key={data.id}
        x={data.x}
        y={data.y}
        width={data.width > 0 ? data.width : 0}
        height={height > 0 ? height : 0}
        onPointerDown={onPointerDown}
      >
        <div
          className={`w-full h-full p-2 cursor-move border-2 ${
            isLayer(data) ? "rounded-lg border-dashed" : "rounded"
          } ${
            isHovered
              ? "border-dashed border-blue-500"
              : isSelected
                ? "border-blue-500 opacity-100"
                : isLayer(data)
                  ? "opacity-100"
                  : "border-slate-400 opacity-100"
          }`}
          style={{
            // A layer is a frame around cards, so it stays unfilled; anything
            // else carries a wash of its own color.
            backgroundColor: isLayer(data) ? "transparent" : `${data.color}66`,
            ...(isLayer(data) && !isHovered && !isSelected
              ? { borderColor: data.color }
              : {}),
          }}
          onDoubleClick={edit}
        >
          <div className="flex justify-between gap-1 w-full">
            <div className="min-w-0 flex-1">
              {isCard(data) && data.category && (
                <div className="mb-1">
                  <TableCategoryBadge
                    category={data.category}
                    color={data.color}
                  />
                </div>
              )}
              <div
                className={`text-color select-none overflow-hidden text-ellipsis ${
                  isLayer(data)
                    ? "text-sm font-semibold tracking-wide"
                    : settings.businessView || isCard(data)
                      ? "text-lg font-semibold"
                      : ""
                }`}
                style={isLayer(data) ? { color: data.color } : {}}
              >
                {data.name}
                {isLayer(data) && (
                  <span className="font-normal opacity-80">
                    {"  —  "}
                    {t("table_count", { count: tableCount })}
                  </span>
                )}
              </div>
              {data.description && (
                <div
                  className={`text-color select-none mt-1 pe-2 ${
                    settings.businessView || isCard(data)
                      ? "text-sm opacity-90 whitespace-pre-wrap"
                      : "text-xs opacity-80 line-clamp-2"
                  }`}
                >
                  {data.description}
                </div>
              )}
              {isCard(data) && cardTables.length > 0 && (
                <ul className="mt-2 select-none">
                  {cardTables.map((table) => (
                    <li
                      key={table.id}
                      className="text-color text-xs font-mono opacity-90 leading-[18px] overflow-hidden text-ellipsis whitespace-nowrap"
                    >
                      {"\u00b7 "}
                      {table.name}
                    </li>
                  ))}
                </ul>
              )}
            </div>
            {(isHovered || (areaIsOpen() && !layout.sidebar)) && (
              <ButtonGroup
                type="tertiary"
                size="small"
                aria-label="Area actions"
              >
                <Button
                  size="small"
                  type="tertiary"
                  icon={
                    data.locked ? (
                      <IconLock size="small" />
                    ) : (
                      <IconUnlock size="small" />
                    )
                  }
                  onClick={lockUnlockArea}
                  disabled={layout.readOnly}
                />
                <Popover
                  visible={areaIsOpen() && !layout.sidebar}
                  onClickOutSide={onClickOutSide}
                  stopPropagation
                  content={<EditPopoverContent data={data} />}
                  trigger="custom"
                  position="rightTop"
                  showArrow
                >
                  <Button
                    size="small"
                    type="tertiary"
                    icon={<IconEdit size="small" />}
                    onClick={edit}
                  />
                </Popover>
              </ButtonGroup>
            )}
          </div>
        </div>
      </foreignObject>
      {isHovered && (
        <>
          <circle
            cx={data.x}
            cy={data.y}
            r={6}
            fill={settings.mode === "light" ? "white" : "rgb(28, 31, 35)"}
            stroke="#5891db"
            strokeWidth={2}
            cursor="nwse-resize"
            onPointerDown={(e) => e.isPrimary && handleResize(e, "tl")}
          />
          <circle
            cx={data.x + data.width}
            cy={data.y}
            r={6}
            fill={settings.mode === "light" ? "white" : "rgb(28, 31, 35)"}
            stroke="#5891db"
            strokeWidth={2}
            cursor="nesw-resize"
            onPointerDown={(e) => e.isPrimary && handleResize(e, "tr")}
          />
          <circle
            cx={data.x}
            cy={data.y + data.height}
            r={6}
            fill={settings.mode === "light" ? "white" : "rgb(28, 31, 35)"}
            stroke="#5891db"
            strokeWidth={2}
            cursor="nesw-resize"
            onPointerDown={(e) => e.isPrimary && handleResize(e, "bl")}
          />
          <circle
            cx={data.x + data.width}
            cy={data.y + data.height}
            r={6}
            fill={settings.mode === "light" ? "white" : "rgb(28, 31, 35)"}
            stroke="#5891db"
            strokeWidth={2}
            cursor="nwse-resize"
            onPointerDown={(e) => e.isPrimary && handleResize(e, "br")}
          />
        </>
      )}
    </g>
  );
}

function EditPopoverContent({ data }) {
  const [editField, setEditField] = useState({});
  const { updateArea, deleteArea } = useAreas();
  const { setUndoStack, setRedoStack } = useUndoRedo();
  const { t } = useTranslation();
  const { layout } = useLayout();
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
          aid: data.id,
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
    <div className="popover-theme">
      <div className="font-semibold mb-2 ms-1">{t("edit")}</div>
      <div className="w-[280px] flex items-center mb-2">
        <Input
          value={data.name}
          placeholder={t("name")}
          className="me-2"
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
                aid: data.id,
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
          readOnly={layout.readOnly}
          value={data.color}
          onChange={(color) => updateArea(data.id, { color })}
          onColorPick={(color) => handleColorPick(color)}
        />
      </div>
      <div className="w-[280px] mb-2">
        <TextArea
          value={data.description ?? ""}
          placeholder={t("block_description_placeholder")}
          autosize
          rows={3}
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
                aid: data.id,
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
      <Divider />
      <Button
        icon={<IconDeleteStroked />}
        type="danger"
        theme="borderless"
        block
        onClick={() => deleteArea(data.id, true)}
        disabled={layout.readOnly}
      >
        {t("delete")}
      </Button>
    </div>
  );
}
