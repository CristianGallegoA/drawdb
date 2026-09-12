import { useMemo, useRef, useState } from "react";
import {
  Action,
  Tab,
  ObjectType,
  tableHeaderHeight,
  tableColorStripHeight,
} from "../../data/constants";
import {
  IconChevronDown,
  IconChevronUp,
  IconMore,
  IconMinus,
  IconDeleteStroked,
  IconEditStroked,
  IconCopyStroked,
  IconKeyStroked,
  IconLock,
  IconUnlock,
} from "@douyinfe/semi-icons";
import { nanoid } from "nanoid";
import {
  Popover,
  Tag,
  Button,
  ButtonGroup,
  SideSheet,
  Divider,
} from "@douyinfe/semi-ui";
import {
  useLayout,
  useSettings,
  useDiagram,
  useSelect,
  useUndoRedo,
  useTransform,
} from "../../hooks";
import TableInfo from "../EditorSidePanel/TablesTab/TableInfo";
import TableCategoryBadge from "../TableCategoryBadge";
import { useTranslation } from "react-i18next";
import { resolveType } from "../../utils/customTypes";
import { isRtl } from "../../i18n/utils/rtl";
import i18n from "../../i18n/i18n";
import {
  getCommentHeight,
  getFieldOffsetY,
  getTableHeight,
  getTableWidth,
  clampTableWidth,
  measureTableWidth,
  getVisibleFieldEntries,
  getVisibleFields,
  getRelationshipFields,
  isTableVisible,
} from "../../utils/utils";

export default function Table({
  tableData,
  onPointerDown,
  setHoveredTable,
  handleGripField,
  setLinkingLine,
}) {
  const [hoveredField, setHoveredField] = useState(null);
  const [resizing, setResizing] = useState(false);
  const [hoveredResizeHandle, setHoveredResizeHandle] = useState(false);
  const initialWidthRef = useRef(null);
  const { layout } = useLayout();
  const { transform } = useTransform();
  const {
    database,
    tables,
    relationships,
    addTable,
    deleteTable,
    deleteField,
    updateTable,
  } = useDiagram();
  const { setUndoStack, setRedoStack } = useUndoRedo();
  const { settings } = useSettings();
  const { t } = useTranslation();
  const {
    selectedElement,
    setSelectedElement,
    bulkSelectedElements,
    setBulkSelectedElements,
  } = useSelect();

  const borderColor = useMemo(
    () => (settings.mode === "light" ? "border-zinc-300" : "border-zinc-600"),
    [settings.mode],
  );

  const width = getTableWidth(tableData, settings.tableWidth);

  const height = getTableHeight(
    tableData,
    width,
    settings.showComments,
    relationships,
  );

  const visibleFieldEntries = useMemo(
    () => getVisibleFieldEntries(tableData, relationships),
    [tableData, relationships],
  );

  const visibleFields = useMemo(
    () => getVisibleFields(tableData, relationships),
    [tableData, relationships],
  );

  const isSelected = useMemo(() => {
    return (
      (selectedElement.id == tableData.id &&
        selectedElement.element === ObjectType.TABLE) ||
      bulkSelectedElements.some(
        (e) => e.type === ObjectType.TABLE && e.id === tableData.id,
      )
    );
  }, [selectedElement, tableData, bulkSelectedElements]);

  const toggleTableCollapse = (e) => {
    e.stopPropagation();
    if (layout.readOnly) return;

    const collapsed = !tableData.collapsed;
    setUndoStack((prev) => [
      ...prev,
      {
        action: Action.EDIT,
        element: ObjectType.TABLE,
        component: "self",
        tid: tableData.id,
        undo: { collapsed: tableData.collapsed },
        redo: { collapsed },
        message: t("edit_table", {
          tableName: tableData.name,
          extra: "[collapse fields]",
        }),
      },
    ]);
    setRedoStack([]);
    updateTable(tableData.id, { collapsed });
  };

  const lockUnlockTable = (e) => {
    const locking = !tableData.locked;
    updateTable(tableData.id, { locked: locking });

    const lockTable = () => {
      setSelectedElement({
        ...selectedElement,
        element: ObjectType.NONE,
        id: -1,
        open: false,
      });
      setBulkSelectedElements((prev) =>
        prev.filter(
          (el) => el.id !== tableData.id || el.type !== ObjectType.TABLE,
        ),
      );
    };

    const unlockTable = () => {
      const elementInBulk = {
        id: tableData.id,
        type: ObjectType.TABLE,
        initialCoords: { x: tableData.x, y: tableData.y },
        currentCoords: { x: tableData.x, y: tableData.y },
      };
      if (e.ctrlKey || e.metaKey) {
        setBulkSelectedElements((prev) => [...prev, elementInBulk]);
      } else {
        setBulkSelectedElements([elementInBulk]);
      }
      setSelectedElement((prev) => ({
        ...prev,
        element: ObjectType.TABLE,
        id: tableData.id,
        open: false,
      }));
    };

    if (locking) {
      lockTable();
    } else {
      unlockTable();
    }
  };

  const duplicateTable = () => {
    if (layout.readOnly) return;
    const duplicated = {
      ...tableData,
      id: nanoid(),
      name: `${tableData.name}_copy`,
      x: tableData.x + 24,
      y: tableData.y + 24,
      fields: tableData.fields.map((f) => ({ ...f, id: nanoid() })),
      indices: tableData.indices.map((idx) => ({ ...idx, id: nanoid() })),
    };
    addTable({ table: duplicated });
  };

  const openEditor = () => {
    if (!layout.sidebar) {
      setSelectedElement((prev) => ({
        ...prev,
        element: ObjectType.TABLE,
        id: tableData.id,
        open: true,
      }));
    } else {
      setSelectedElement((prev) => ({
        ...prev,
        currentTab: Tab.TABLES,
        element: ObjectType.TABLE,
        id: tableData.id,
        open: true,
      }));
      if (selectedElement.currentTab !== Tab.TABLES) return;
      document
        .getElementById(`scroll_table_${tableData.id}`)
        .scrollIntoView({ behavior: "smooth" });
    }
  };

  const getFieldReference = (fieldData) => {
    let matchedEndFieldId = null;
    const rel = relationships.find((r) => {
      if (r.startTableId !== tableData.id) return false;
      const pair = getRelationshipFields(r).find(
        (p) => p.startFieldId === fieldData.id,
      );
      if (!pair) return false;
      matchedEndFieldId = pair.endFieldId;
      return true;
    });
    if (!rel) return null;

    const refTable = tables.find((tbl) => tbl.id === rel.endTableId);
    const refField = refTable?.fields.find((f) => f.id === matchedEndFieldId);
    if (!refTable || !refField) return null;

    return { tableName: refTable.name, fieldName: refField.name };
  };

  const typeLabelOf = (field) => {
    const resolved = resolveType(database, field.type);
    return (
      field.type +
      ((resolved.isSized || resolved.hasPrecision) && field.size
        ? `(${field.size})`
        : "")
    );
  };

  const commitWidth = (from, to) => {
    if (from === to) return;
    setUndoStack((prev) => [
      ...prev,
      {
        action: Action.EDIT,
        element: ObjectType.TABLE,
        component: "self",
        tid: tableData.id,
        undo: { width: from },
        redo: { width: to },
        message: t("edit_table", {
          tableName: tableData.name,
          extra: "[width]",
        }),
      },
    ]);
    setRedoStack([]);
  };

  const autoFitWidth = () => {
    if (layout.readOnly || tableData.locked) return;
    const fitted = measureTableWidth(tableData, {
      showDataTypes: settings.showDataTypes,
      typeLabelOf,
    });
    if (fitted === width) return;
    commitWidth(width, fitted);
    updateTable(tableData.id, { width: fitted });
  };

  if (!isTableVisible(tableData, settings.hiddenCategories)) return null;

  return (
    <>
      <foreignObject
        key={tableData.id}
        x={tableData.x}
        y={tableData.y}
        width={width}
        height={height}
        className="group drop-shadow-lg rounded-md cursor-move"
        onPointerDown={onPointerDown}
      >
        <div
          onDoubleClick={openEditor}
          className={`border-2 hover:border-dashed hover:border-blue-500
               select-none rounded-lg w-full ${
                 settings.mode === "light"
                   ? "bg-zinc-100 text-zinc-800"
                   : "bg-zinc-800 text-zinc-200"
               } ${isSelected ? "border-solid border-blue-500" : borderColor}`}
          style={{ direction: "ltr" }}
        >
          <div
            className="h-[10px] w-full rounded-t-md"
            style={{ backgroundColor: tableData.color }}
          />
          <div
            className={`${
              visibleFieldEntries.length === 0
                ? "rounded-b-md"
                : "border-b border-gray-400"
            } ${
              settings.mode === "light" ? "bg-zinc-100" : "bg-zinc-900"
            } ${tableData.comment && settings.showComments ? "pb-3" : ""}`}
          >
            <div
              className={`overflow-hidden font-bold h-[40px] flex justify-between items-center gap-2`}
            >
              <TableSummaryPopover
                enabled={settings.showFieldSummary}
                tableData={tableData}
                t={t}
              >
                <div className="px-3 min-w-0 flex-1 flex items-center gap-2">
                  <TableCategoryBadge
                    category={tableData.category}
                    color={tableData.color}
                  />
                  <span className="overflow-hidden text-ellipsis whitespace-nowrap">
                    {tableData.name}
                  </span>
                </div>
              </TableSummaryPopover>
              <div className="hidden group-hover:flex items-center shrink-0 pe-2">
                <ButtonGroup
                  type="tertiary"
                  size="small"
                  aria-label="Table actions"
                >
                  <Button
                    size="small"
                    type="tertiary"
                    title={tableData.locked ? "Unlock table" : "Lock table"}
                    icon={
                      tableData.locked ? (
                        <IconLock size="small" />
                      ) : (
                        <IconUnlock size="small" />
                      )
                    }
                    disabled={layout.readOnly}
                    onClick={lockUnlockTable}
                  />
                  <Button
                    size="small"
                    type="tertiary"
                    icon={
                      tableData.collapsed ? (
                        <IconChevronDown size="small" />
                      ) : (
                        <IconChevronUp size="small" />
                      )
                    }
                    disabled={layout.readOnly}
                    aria-label={
                      tableData.collapsed
                        ? "Expand unlinked fields"
                        : "Collapse unlinked fields"
                    }
                    title={
                      tableData.collapsed
                        ? "Expand unlinked fields"
                        : "Collapse unlinked fields"
                    }
                    onClick={toggleTableCollapse}
                    onPointerDown={(e) => e.stopPropagation()}
                  />
                  <Popover
                    key={tableData.id}
                    content={
                      <div className="popover-theme flex flex-col py-1 min-w-[160px]">
                        <Button
                          icon={<IconEditStroked />}
                          type="tertiary"
                          theme="borderless"
                          block
                          style={{ justifyContent: "flex-start" }}
                          onClick={openEditor}
                        >
                          {t("edit")}
                        </Button>
                        <Button
                          icon={<IconCopyStroked />}
                          type="tertiary"
                          theme="borderless"
                          block
                          style={{ justifyContent: "flex-start" }}
                          onClick={duplicateTable}
                          disabled={layout.readOnly}
                        >
                          {t("duplicate")}
                        </Button>
                        <Divider className="!my-1" />
                        <Button
                          icon={<IconDeleteStroked />}
                          type="danger"
                          theme="borderless"
                          block
                          style={{ justifyContent: "flex-start" }}
                          onClick={() => deleteTable(tableData.id)}
                          disabled={layout.readOnly}
                        >
                          {t("delete")}
                        </Button>
                      </div>
                    }
                    position="rightTop"
                    style={{ padding: 8 }}
                    showArrow
                    trigger="click"
                  >
                    <Button
                      size="small"
                      type="tertiary"
                      icon={<IconMore size="small" />}
                      title="See more"
                    />
                  </Popover>
                </ButtonGroup>
              </div>
            </div>
            {tableData.comment && settings.showComments && (
              <div className="text-xs px-3 line-clamp-5">
                {tableData.comment}
              </div>
            )}
          </div>

          {visibleFieldEntries.map(({ field: e }, i) => {
            const resolved = resolveType(database, e.type);
            const reference = getFieldReference(e);
            return settings.showFieldSummary ? (
              <Popover
                key={e.id ?? i}
                content={
                  <div className="popover-theme">
                    <div
                      className="flex justify-between items-center pb-2"
                      style={{ direction: "ltr" }}
                    >
                      <p className="me-4 font-bold">{e.name}</p>
                      <p
                        className={
                          "ms-4 font-mono " +
                          (resolved.isCustom ? "" : resolved.color)
                        }
                        style={
                          resolved.isCustom ? { color: resolved.color } : {}
                        }
                      >
                        {e.type +
                          ((resolved.isSized || resolved.hasPrecision) &&
                          e.size &&
                          e.size !== ""
                            ? "(" + e.size + ")"
                            : "")}
                      </p>
                    </div>
                    <hr />
                    {e.primary && (
                      <Tag color="blue" className="me-2 my-2">
                        {t("primary_key")}
                      </Tag>
                    )}
                    {e.unique && (
                      <Tag color="amber" className="me-2 my-2">
                        {t("unique")}
                      </Tag>
                    )}
                    {e.notNull && (
                      <Tag color="purple" className="me-2 my-2">
                        {t("not_null")}
                      </Tag>
                    )}
                    {e.increment && (
                      <Tag color="green" className="me-2 my-2">
                        {t("autoincrement")}
                      </Tag>
                    )}
                    {reference && (
                      <Tag color="light-blue" className="me-2 my-2">
                        {t("foreign_key")}
                      </Tag>
                    )}
                    {reference && (
                      <p>
                        <strong>{t("references")}: </strong>
                        {reference.tableName}({reference.fieldName})
                      </p>
                    )}
                    <p>
                      <strong>{t("default_value")}: </strong>
                      {e.default === "" ? t("not_set") : e.default}
                    </p>
                    <p>
                      <strong>{t("owner")}: </strong>
                      {e.owner ? (
                        e.owner
                      ) : tableData.owner ? (
                        <span className="opacity-60">
                          {tableData.owner} ({t("inherited")})
                        </span>
                      ) : (
                        t("not_set")
                      )}
                    </p>
                    <p className="max-w-80">
                      <strong>{t("comment")}: </strong>
                      {e.comment === "" ? t("not_set") : e.comment}
                    </p>
                  </div>
                }
                position="right"
                showArrow
                style={
                  isRtl(i18n.language)
                    ? { direction: "rtl" }
                    : { direction: "ltr" }
                }
              >
                {field(e, i)}
              </Popover>
            ) : (
              field(e, i)
            );
          })}
        </div>
      </foreignObject>
      {!layout.readOnly && !tableData.locked && (
        <>
          {(hoveredResizeHandle || resizing) && (
            <line
              x1={tableData.x + width}
              y1={tableData.y + tableColorStripHeight}
              x2={tableData.x + width}
              y2={tableData.y + height}
              stroke="#5891db"
              strokeWidth={2}
              className="pointer-events-none"
            />
          )}
          <rect
            x={tableData.x + width - 4}
            y={tableData.y + tableColorStripHeight}
            width={8}
            height={Math.max(0, height - tableColorStripHeight)}
            fill="transparent"
            style={{ cursor: "ew-resize" }}
            onPointerEnter={(e) => e.isPrimary && setHoveredResizeHandle(true)}
            onPointerLeave={(e) => e.isPrimary && setHoveredResizeHandle(false)}
            onPointerDown={(e) => {
              if (!e.isPrimary) return;
              // Keep the canvas from starting a bulk selection behind us.
              e.stopPropagation();
              initialWidthRef.current = width;
              setResizing(true);
              e.currentTarget.setPointerCapture?.(e.pointerId);
            }}
            onPointerMove={(e) => {
              if (!resizing || !e.isPrimary) return;
              const next = clampTableWidth(
                width + e.movementX / (transform?.zoom || 1),
              );
              if (next !== width) updateTable(tableData.id, { width: next });
            }}
            onPointerUp={(e) => {
              if (!resizing) return;
              e.stopPropagation();
              setResizing(false);
              commitWidth(initialWidthRef.current, width);
            }}
            onDoubleClick={(e) => {
              e.stopPropagation();
              autoFitWidth();
            }}
          />
        </>
      )}
      <SideSheet
        title={t("edit")}
        size="small"
        visible={
          selectedElement.element === ObjectType.TABLE &&
          selectedElement.id === tableData.id &&
          selectedElement.open &&
          !layout.sidebar
        }
        onCancel={() =>
          setSelectedElement((prev) => ({
            ...prev,
            open: !prev.open,
          }))
        }
        style={{ paddingBottom: "16px" }}
      >
        <div className="sidesheet-theme">
          <TableInfo data={tableData} />
        </div>
      </SideSheet>
    </>
  );

  function field(fieldData, index) {
    const fieldResolved = resolveType(database, fieldData.type);
    const showFieldComment = fieldData.comment && settings.showComments;
    return (
      <div
        className={`${
          index === visibleFields.length - 1 ? "" : "border-b border-gray-400"
        } group w-full overflow-hidden`}
        onPointerEnter={(e) => {
          if (!e.isPrimary) return;

          setHoveredField(index);
          setHoveredTable({
            tableId: tableData.id,
            fieldId: fieldData.id,
          });
        }}
        onPointerLeave={(e) => {
          if (!e.isPrimary) return;

          setHoveredField(null);
          setHoveredTable({
            tableId: null,
            fieldId: null,
          });
        }}
        onPointerDown={(e) => {
          // Required for onPointerLeave to trigger when a touch pointer leaves
          // https://stackoverflow.com/a/70976017/1137077
          e.target.releasePointerCapture(e.pointerId);
        }}
      >
        <div className="h-[36px] px-2 py-1 flex justify-between items-center gap-1">
          <div
            className={`${
              hoveredField === index ? "text-zinc-400" : ""
            } flex items-center gap-2 overflow-hidden`}
          >
            <button
              className="shrink-0 w-[10px] h-[10px] bg-[#2f68adcc] rounded-full"
              onPointerDown={(e) => {
                if (!e.isPrimary) return;

                handleGripField();
                const fieldY =
                  tableData.y +
                  getFieldOffsetY(
                    visibleFields,
                    index,
                    width,
                    settings.showComments,
                  ) +
                  tableHeaderHeight +
                  tableColorStripHeight +
                  getCommentHeight(
                    tableData.comment,
                    width,
                    settings.showComments,
                  ) +
                  14;
                setLinkingLine((prev) => ({
                  ...prev,
                  startFieldId: fieldData.id,
                  startTableId: tableData.id,
                  startX: tableData.x + 15,
                  startY: fieldY,
                  endX: tableData.x + 15,
                  endY: fieldY,
                }));
              }}
            />
            <span className="overflow-hidden text-ellipsis whitespace-nowrap">
              {fieldData.name}
            </span>
          </div>
          <div className="text-zinc-400">
            {hoveredField === index ? (
              <Button
                theme="solid"
                size="small"
                style={{
                  backgroundColor: "#d42020b3",
                }}
                icon={<IconMinus />}
                disabled={layout.readOnly}
                onClick={() => {
                  if (layout.readOnly) return;
                  deleteField(fieldData, tableData.id);
                }}
              />
            ) : settings.showDataTypes ? (
              <div className="flex gap-1 items-center">
                {fieldData.primary && <IconKeyStroked />}
                {!fieldData.notNull && <span className="font-mono">?</span>}
                <span
                  className={
                    "font-mono " +
                    (fieldResolved.isCustom ? "" : fieldResolved.color)
                  }
                  style={
                    fieldResolved.isCustom ? { color: fieldResolved.color } : {}
                  }
                >
                  {fieldData.type +
                    ((fieldResolved.isSized || fieldResolved.hasPrecision) &&
                    fieldData.size &&
                    fieldData.size !== ""
                      ? `(${fieldData.size})`
                      : "")}
                </span>
              </div>
            ) : null}
          </div>
        </div>
        {showFieldComment && (
          <div className="ms-3 px-3 pb-3">
            <div
              className={`text-xs line-clamp-2 ${settings.mode === "light" ? "text-zinc-600" : "text-zinc-200"}`}
            >
              {fieldData.comment}
            </div>
          </div>
        )}
      </div>
    );
  }
}

/**
 * Hover summary for the table itself: owner and comment, mirroring the per
 * field summary. Only the name and category badge are wrapped, so the
 * lock/collapse/menu buttons on the right of the header stay clickable.
 */
function TableSummaryPopover({ enabled, tableData, t, children }) {
  if (!enabled) return children;

  return (
    <Popover
      content={
        <div className="popover-theme">
          <div
            className="flex items-center gap-2 pb-2"
            style={{ direction: "ltr" }}
          >
            <TableCategoryBadge
              category={tableData.category}
              color={tableData.color}
            />
            <p className="font-bold">{tableData.name}</p>
          </div>
          <hr />
          <p className="mt-2">
            <strong>{t("owner")}: </strong>
            {tableData.owner ? tableData.owner : t("not_set")}
          </p>
          <p className="max-w-80">
            <strong>{t("comment")}: </strong>
            {tableData.comment ? tableData.comment : t("not_set")}
          </p>
        </div>
      }
      position="top"
      showArrow
      style={
        isRtl(i18n.language) ? { direction: "rtl" } : { direction: "ltr" }
      }
    >
      {children}
    </Popover>
  );
}
