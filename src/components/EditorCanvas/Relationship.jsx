import { useMemo, useRef, useState, useEffect } from "react";
import {
  Action,
  Cardinality,
  ObjectType,
  RelationshipPathStyle,
  Tab,
} from "../../data/constants";
import {
  calcPath,
  calcCompositePath,
  calcRoutedPath,
  getRoutedPoints,
  nearestSegmentIndex,
} from "../../utils/calcPath";
import {
  useDiagram,
  useSettings,
  useLayout,
  useSelect,
  useCanvas,
  useUndoRedo,
} from "../../hooks";
import { useTranslation } from "react-i18next";
import { SideSheet } from "@douyinfe/semi-ui";
import RelationshipInfo from "../EditorSidePanel/RelationshipsTab/RelationshipInfo";
import {
  getVisibleFieldIndex,
  getVisibleFields,
  getRelationshipFields,
  getTableWidth,
  isTableVisible,
} from "../../utils/utils";

const labelFontSize = 16;
// How far the pointer must travel over a line before it becomes a waypoint.
const DRAG_THRESHOLD = 3;

export default function Relationship({ data }) {
  const { settings } = useSettings();
  const { tables, relationships, updateRelationship } = useDiagram();
  const { layout } = useLayout();
  const { selectedElement, setSelectedElement } = useSelect();
  const { pointer } = useCanvas();
  const { setUndoStack, setRedoStack } = useUndoRedo();
  const { t } = useTranslation();

  const [hovered, setHovered] = useState(false);
  const [dragIndex, setDragIndex] = useState(-1);
  // Waypoints as they were when the current drag started, for the undo entry.
  const routeStartRef = useRef(null);
  // A press on the line that has not moved far enough to become a new
  // waypoint yet, so plain clicks leave the route untouched.
  const pendingRef = useRef(null);

  const waypoints = useMemo(() => data.waypoints ?? [], [data.waypoints]);
  const pathStyle = data.pathStyle ?? RelationshipPathStyle.ORTHOGONAL;
  const isRouted =
    waypoints.length > 0 || pathStyle !== RelationshipPathStyle.ORTHOGONAL;

  const pathValues = useMemo(() => {
    const startTable = tables.find((t) => t.id === data.startTableId);
    const endTable = tables.find((t) => t.id === data.endTableId);

    if (
      !isTableVisible(startTable, settings.hiddenCategories) ||
      !isTableVisible(endTable, settings.hiddenCategories)
    ) {
      return null;
    }

    const startFields = getVisibleFields(startTable, relationships);
    const endFields = getVisibleFields(endTable, relationships);

    const pairs = getRelationshipFields(data);

    return {
      startFieldIndex: getVisibleFieldIndex(
        startTable,
        data.startFieldId,
        relationships,
      ),
      endFieldIndex: getVisibleFieldIndex(
        endTable,
        data.endFieldId,
        relationships,
      ),
      startFieldIndices: pairs.map((p) =>
        getVisibleFieldIndex(startTable, p.startFieldId, relationships),
      ),
      endFieldIndices: pairs.map((p) =>
        getVisibleFieldIndex(endTable, p.endFieldId, relationships),
      ),
      startTable: {
        x: startTable.x,
        y: startTable.y,
        comment: startTable.comment,
        fields: startFields,
        width: getTableWidth(startTable, settings.tableWidth),
      },
      endTable: {
        x: endTable.x,
        y: endTable.y,
        comment: endTable.comment,
        fields: endFields,
        width: getTableWidth(endTable, settings.tableWidth),
      },
    };
  }, [
    tables,
    relationships,
    data,
    settings.tableWidth,
    settings.hiddenCategories,
  ]);

  const isComposite = (pathValues?.startFieldIndices?.length ?? 0) > 1;

  // A hand-routed relationship draws as a single line through its waypoints,
  // so the composite fork only applies while the automatic routing is in use.
  const composite = useMemo(() => {
    if (!pathValues || !isComposite || isRouted) return null;
    return calcCompositePath(
      {
        startTable: pathValues.startTable,
        endTable: pathValues.endTable,
        startFieldIndices: pathValues.startFieldIndices,
        endFieldIndices: pathValues.endFieldIndices,
      },
      settings.tableWidth,
      1,
      settings.showComments,
    );
  }, [
    pathValues,
    isComposite,
    isRouted,
    settings.tableWidth,
    settings.showComments,
  ]);

  const pathData = useMemo(() => {
    if (!pathValues) return "";
    if (composite) return composite.path;
    if (isRouted) {
      return calcRoutedPath(
        pathValues,
        settings.tableWidth,
        settings.showComments,
        waypoints,
        pathStyle,
      );
    }
    return calcPath(pathValues, settings.tableWidth, 1, settings.showComments);
  }, [
    pathValues,
    composite,
    isRouted,
    waypoints,
    pathStyle,
    settings.tableWidth,
    settings.showComments,
  ]);

  // Anchor + waypoint polyline, used to decide which segment a new waypoint
  // belongs to.
  const routedPoints = useMemo(() => {
    if (!pathValues) return [];
    return getRoutedPoints(
      pathValues,
      settings.tableWidth,
      settings.showComments,
      waypoints,
    );
  }, [pathValues, settings.tableWidth, settings.showComments, waypoints]);

  const pathRef = useRef();
  const labelRef = useRef();

  let cardinalityStart = "1";
  let cardinalityEnd = "1";

  switch (data.cardinality) {
    // the translated values are to ensure backwards compatibility
    case t(Cardinality.MANY_TO_ONE):
    case Cardinality.MANY_TO_ONE:
      cardinalityStart = data.manyLabel || "n";
      cardinalityEnd = "1";
      break;
    case t(Cardinality.ONE_TO_MANY):
    case Cardinality.ONE_TO_MANY:
      cardinalityStart = "1";
      cardinalityEnd = data.manyLabel || "n";
      break;
    case t(Cardinality.ONE_TO_ONE):
    case Cardinality.ONE_TO_ONE:
      cardinalityStart = "1";
      cardinalityEnd = "1";
      break;
    default:
      break;
  }

  let cardinalityStartX = 0;
  let cardinalityEndX = 0;
  let cardinalityStartY = 0;
  let cardinalityEndY = 0;
  let labelX = 0;
  let labelY = 0;

  let labelWidth = labelRef.current?.getBBox().width ?? 0;
  let labelHeight = labelRef.current?.getBBox().height ?? 0;

  const cardinalityOffset = 28;

  if (composite) {
    labelX = composite.labelPoint.x - (labelWidth ?? 0) / 2;
    labelY = composite.labelPoint.y + (labelHeight ?? 0) / 2;
    cardinalityStartX = composite.startCardinality.x;
    cardinalityStartY = composite.startCardinality.y;
    cardinalityEndX = composite.endCardinality.x;
    cardinalityEndY = composite.endCardinality.y;
  } else if (pathRef.current) {
    const pathLength = pathRef.current.getTotalLength();

    const labelPoint = pathRef.current.getPointAtLength(pathLength / 2);
    labelX = labelPoint.x - (labelWidth ?? 0) / 2;
    labelY = labelPoint.y + (labelHeight ?? 0) / 2;

    const point1 = pathRef.current.getPointAtLength(cardinalityOffset);
    cardinalityStartX = point1.x;
    cardinalityStartY = point1.y;
    const point2 = pathRef.current.getPointAtLength(
      pathLength - cardinalityOffset,
    );
    cardinalityEndX = point2.x;
    cardinalityEndY = point2.y;
  }

  const edit = () => {
    if (!layout.sidebar) {
      setSelectedElement((prev) => ({
        ...prev,
        element: ObjectType.RELATIONSHIP,
        id: data.id,
        open: true,
      }));
    } else {
      setSelectedElement((prev) => ({
        ...prev,
        currentTab: Tab.RELATIONSHIPS,
        element: ObjectType.RELATIONSHIP,
        id: data.id,
        open: true,
      }));
      if (selectedElement.currentTab !== Tab.RELATIONSHIPS) return;
      document
        .getElementById(`scroll_ref_${data.id}`)
        .scrollIntoView({ behavior: "smooth" });
    }
  };

  const isSelected =
    selectedElement.element === ObjectType.RELATIONSHIP &&
    selectedElement.id === data.id;

  const showHandles =
    !layout.readOnly && (hovered || isSelected || dragIndex !== -1);

  const commitWaypoints = (before, after) => {
    if (JSON.stringify(before) === JSON.stringify(after)) return;
    setUndoStack((prev) => [
      ...prev,
      {
        action: Action.EDIT,
        element: ObjectType.RELATIONSHIP,
        rid: data.id,
        undo: { waypoints: before },
        redo: { waypoints: after },
        message: t("edit_relationship", {
          refName: data.name,
          extra: "[routing]",
        }),
      },
    ]);
    setRedoStack([]);
  };

  const beginDrag = (e, index) => {
    if (layout.readOnly || !e.isPrimary) return;
    // Keep the canvas from starting a bulk selection behind the line.
    e.stopPropagation();
    e.currentTarget.setPointerCapture?.(e.pointerId);
    routeStartRef.current = waypoints.map((p) => ({ ...p }));
    setDragIndex(index);
  };

  const dragWaypoint = (e) => {
    if (!e.isPrimary) return;

    const point = {
      x: pointer.spaces.diagram.x,
      y: pointer.spaces.diagram.y,
    };

    if (dragIndex < 0) {
      // The line was pressed but no waypoint exists yet: create one as soon as
      // the pointer actually travels, so a click stays a click.
      const pending = pendingRef.current;
      if (!pending) return;
      if (
        Math.hypot(point.x - pending.point.x, point.y - pending.point.y) <
        DRAG_THRESHOLD
      ) {
        return;
      }
      pendingRef.current = null;
      routeStartRef.current = waypoints.map((p) => ({ ...p }));
      setDragIndex(pending.index);
      updateRelationship(data.id, {
        waypoints: [
          ...waypoints.slice(0, pending.index),
          point,
          ...waypoints.slice(pending.index),
        ],
      });
      return;
    }

    updateRelationship(data.id, {
      waypoints: waypoints.map((p, i) => (i === dragIndex ? point : p)),
    });
  };

  const endDrag = (e) => {
    pendingRef.current = null;
    if (dragIndex < 0) return;
    e.stopPropagation();

    const before = routeStartRef.current ?? [];
    routeStartRef.current = null;
    setDragIndex(-1);
    commitWaypoints(before, waypoints);
  };

  const grabLine = (e) => {
    if (!e.isPrimary || e.button !== 0) return;

    setSelectedElement((prev) => ({
      ...prev,
      element: ObjectType.RELATIONSHIP,
      id: data.id,
      open: false,
    }));

    if (layout.readOnly) return;

    const point = {
      x: pointer.spaces.diagram.x,
      y: pointer.spaces.diagram.y,
    };
    pendingRef.current = {
      point,
      index: nearestSegmentIndex(point, routedPoints),
    };
    // Keep the canvas from starting a bulk selection behind the line.
    e.stopPropagation();
    e.currentTarget.setPointerCapture?.(e.pointerId);
  };

  const removeWaypoint = (index) => {
    if (layout.readOnly) return;
    const next = waypoints.filter((_, i) => i !== index);
    commitWaypoints(waypoints, next);
    updateRelationship(data.id, { waypoints: next });
  };

  if (!pathValues) return null;

  return (
    <>
      <g
        className="select-none group"
        onDoubleClick={edit}
        onPointerEnter={(e) => e.isPrimary && setHovered(true)}
        onPointerLeave={(e) => e.isPrimary && setHovered(false)}
      >
        {/* invisible wider path for better hover ux */}
        <path
          d={pathData}
          fill="none"
          stroke="transparent"
          strokeWidth={12}
          cursor={layout.readOnly ? "pointer" : "grab"}
          onPointerDown={grabLine}
          onPointerMove={dragWaypoint}
          onPointerUp={endDrag}
        />
        <path
          ref={pathRef}
          d={pathData}
          className="relationship-path"
          fill="none"
          cursor="pointer"
        />
        {settings.showRelationshipLabels && (
          <text
            x={labelX}
            y={labelY}
            fill={settings.mode === "dark" ? "lightgrey" : "#333"}
            fontSize={labelFontSize}
            fontWeight={500}
            ref={labelRef}
            className="group-hover:fill-sky-600"
          >
            {data.name}
          </text>
        )}
        {(composite || pathRef.current) && settings.showCardinality && (
          <>
            <CardinalityLabel
              x={cardinalityStartX}
              y={cardinalityStartY}
              text={cardinalityStart}
            />
            <CardinalityLabel
              x={cardinalityEndX}
              y={cardinalityEndY}
              text={cardinalityEnd}
            />
          </>
        )}
        {showHandles &&
          waypoints.map((p, i) => (
            <circle
              key={i}
              cx={p.x}
              cy={p.y}
              r={6}
              fill={settings.mode === "light" ? "white" : "rgb(28, 31, 35)"}
              stroke="#5891db"
              strokeWidth={2}
              cursor="move"
              onPointerDown={(e) => beginDrag(e, i)}
              onPointerMove={dragWaypoint}
              onPointerUp={endDrag}
              onDoubleClick={(e) => {
                e.stopPropagation();
                removeWaypoint(i);
              }}
            />
          ))}
      </g>
      <SideSheet
        title={t("edit")}
        size="small"
        visible={
          selectedElement.element === ObjectType.RELATIONSHIP &&
          selectedElement.id === data.id &&
          selectedElement.open &&
          !layout.sidebar
        }
        onCancel={() => {
          setSelectedElement((prev) => ({
            ...prev,
            open: false,
          }));
        }}
        style={{ paddingBottom: "16px" }}
      >
        <div className="sidesheet-theme">
          <RelationshipInfo data={data} />
        </div>
      </SideSheet>
    </>
  );
}

function CardinalityLabel({ x, y, text, r = 12, padding = 14 }) {
  const [textWidth, setTextWidth] = useState(0);
  const textRef = useRef(null);

  useEffect(() => {
    if (textRef.current) {
      const bbox = textRef.current.getBBox();
      setTextWidth(bbox.width);
    }
  }, [text]);

  return (
    <g>
      <rect
        x={x - textWidth / 2 - padding / 2}
        y={y - r}
        rx={r}
        ry={r}
        width={textWidth + padding}
        height={r * 2}
        fill="grey"
        className="group-hover:fill-sky-600"
      />
      <text
        ref={textRef}
        x={x}
        y={y}
        fill="white"
        strokeWidth="0.5"
        textAnchor="middle"
        alignmentBaseline="middle"
      >
        {text}
      </text>
    </g>
  );
}
