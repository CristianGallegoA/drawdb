import { useEffect, useRef, useState } from "react";
import { Slot } from "../../context/ExtensionsContext";
import {
  Action,
  Cardinality,
  Constraint,
  darkBgTheme,
  ObjectType,
  gridSize,
  gridCircleRadius,
  minAreaSize,
} from "../../data/constants";
import { Divider, Popover, Toast, Tooltip } from "@douyinfe/semi-ui";
import Table from "./Table";
import Area from "./Area";
import Relationship from "./Relationship";
import Note from "./Note";
import {
  useCanvas,
  useSettings,
  useTransform,
  useDiagram,
  useUndoRedo,
  useSelect,
  useAreas,
  useNotes,
  useLayout,
  useSaveState,
  useCollab,
} from "../../hooks";
import { useTranslation } from "react-i18next";
import { useEventListener } from "usehooks-ts";
import {
  areFieldsCompatible,
  collectCategories,
  getTableHeight,
  getTableWidth,
  isTableVisible,
  UNCATEGORIZED,
} from "../../utils/utils";
import {
  aggregateBlockLinks,
  blocksFromCategories,
  cardFromSelection,
  isCard,
  isLayer,
  CARD,
  LAYER,
  tablesWithoutCard,
} from "../../utils/blocks";
import { getRectFromEndpoints, isInsideRect } from "../../utils/rect";
import { State, noteWidth } from "../../data/constants";
import { nanoid } from "nanoid";

export default function Canvas() {
  const { t } = useTranslation();

  const canvasRef = useRef(null);
  const canvasContextValue = useCanvas();
  const {
    canvas: { viewBox },
    pointer,
  } = canvasContextValue;

  const { tables, updateTable, relationships, addRelationship, database } =
    useDiagram();
  const { setSaveState } = useSaveState();
  const { areas, setAreas, updateArea } = useAreas();
  const { notes, updateNote } = useNotes();
  const { layout } = useLayout();
  const { settings, setSettings } = useSettings();
  const { setUndoStack, setRedoStack } = useUndoRedo();
  const { transform, setTransform } = useTransform();
  const {
    selectedElement,
    setSelectedElement,
    bulkSelectedElements,
    setBulkSelectedElements,
  } = useSelect();
  const notDragging = {
    id: -1,
    type: ObjectType.NONE,
    grabOffset: { x: 0, y: 0 },
  };
  const [dragging, setDragging] = useState(notDragging);
  const [linking, setLinking] = useState(false);
  const [linkingLine, setLinkingLine] = useState({
    startTableId: -1,
    startFieldId: -1,
    endTableId: -1,
    endFieldId: -1,
    startX: 0,
    startY: 0,
    endX: 0,
    endY: 0,
  });
  const { emitAwareness } = useCollab();
  const lastLinkingRef = useRef(false);
  const rightClickPanned = useRef(false);

  useEffect(() => {
    if (linking) {
      emitAwareness({
        linking: {
          startX: linkingLine.startX,
          startY: linkingLine.startY,
          endX: linkingLine.endX,
          endY: linkingLine.endY,
        },
      });
      lastLinkingRef.current = true;
    } else if (lastLinkingRef.current) {
      emitAwareness({ linking: null });
      lastLinkingRef.current = false;
    }
  }, [
    linking,
    linkingLine.startX,
    linkingLine.startY,
    linkingLine.endX,
    linkingLine.endY,
    emitAwareness,
  ]);
  const [hoveredTable, setHoveredTable] = useState({
    tableId: null,
    fieldId: null,
  });
  const [panning, setPanning] = useState({
    isPanning: false,
    panStart: { x: 0, y: 0 },
    cursorStart: { x: 0, y: 0 },
  });
  // Hold space to turn the left button into a hand tool, the way every canvas
  // editor does it. Middle and right drag already pan without it.
  const [spaceHeld, setSpaceHeld] = useState(false);
  // The same thing, latched on from the toolbar, for people who would rather
  // not hold a key (or whose pointing device cannot scroll sideways at all).
  const [handTool, setHandTool] = useState(false);
  const panMode = handTool || spaceHeld;
  const [areaResize, setAreaResize] = useState({ id: -1, dir: "none" });
  const [areaInitDimensions, setAreaInitDimensions] = useState({
    x: 0,
    y: 0,
    width: 0,
    height: 0,
  });
  const [bulkSelectRect, setBulkSelectRect] = useState({
    x1: 0,
    y1: 0,
    x2: 0,
    y2: 0,
    show: false,
    ctrlKey: false,
    metaKey: false,
  });
  // this is used to store the element that is clicked on
  // at the moment, and shouldn't be a part of the state
  let elementPointerDown = null;

  const isSameElement = (el1, el2) => {
    return el1.id === el2.id && el1.type === el2.type;
  };

  const collectSelectedElements = () => {
    const rect = getRectFromEndpoints(bulkSelectRect);
    const elements = [];
    const shouldAddElement = (elementRect, element) => {
      // if ctrl key is pressed, only add the elements that are not already selected
      // can theoretically be optimized later if the selected elements is
      // a map from id to element (after the ids are made unique)
      return (
        isInsideRect(elementRect, rect) &&
        ((!bulkSelectRect.ctrlKey && !bulkSelectRect.metaKey) ||
          !bulkSelectedElements.some((el) => isSameElement(el, element)))
      );
    };

    tables.forEach((table) => {
      if (table.locked) return;
      // A table you cannot see should not land in a rubber band selection.
      if (!isTableVisible(table, settings.hiddenCategories)) return;

      const element = {
        id: table.id,
        type: ObjectType.TABLE,
        currentCoords: { x: table.x, y: table.y },
        initialCoords: { x: table.x, y: table.y },
      };
      const tableWidth = getTableWidth(table, settings.tableWidth);
      const tableRect = {
        x: table.x,
        y: table.y,
        width: tableWidth,
        height: getTableHeight(
          table,
          tableWidth,
          settings.showComments,
          relationships,
        ),
      };
      if (shouldAddElement(tableRect, element)) {
        elements.push(element);
      }
    });

    areas.forEach((area) => {
      if (area.locked) return;

      const element = {
        id: area.id,
        type: ObjectType.AREA,
        currentCoords: { x: area.x, y: area.y },
        initialCoords: { x: area.x, y: area.y },
      };
      const areaRect = {
        x: area.x,
        y: area.y,
        width: area.width,
        height: area.height,
      };
      if (shouldAddElement(areaRect, element)) {
        elements.push(element);
      }
    });

    notes.forEach((note) => {
      if (note.locked) return;

      const element = {
        id: note.id,
        type: ObjectType.NOTE,
        currentCoords: { x: note.x, y: note.y },
        initialCoords: { x: note.x, y: note.y },
      };
      const noteRect = {
        x: note.x,
        y: note.y,
        width: note.width ?? noteWidth,
        height: note.height,
      };
      if (shouldAddElement(noteRect, element)) {
        elements.push(element);
      }
    });

    if (bulkSelectRect.ctrlKey || bulkSelectRect.metaKey) {
      setBulkSelectedElements([...bulkSelectedElements, ...elements]);
    } else {
      setBulkSelectedElements(elements);
    }
  };

  const handlePointerDownOnElement = (e, { element, type }) => {
    if (selectedElement.open && !layout.sidebar) return;

    if (!e.isPrimary) return;

    if (!element.locked || !(e.ctrlKey || e.metaKey)) {
      setSelectedElement((prev) => ({
        ...prev,
        element: type,
        id: element.id,
        open: false,
      }));
    }

    if (element.locked) {
      if (!(e.ctrlKey || e.metaKey)) {
        setBulkSelectedElements([]);
      }
      return;
    }

    setBulkSelectRect((prev) => ({
      ...prev,
      show: false,
    }));

    // this is the object that will be added to the bulk selected elements
    // if necessary
    const elementInBulk = {
      id: element.id,
      type,
      currentCoords: { x: element.x, y: element.y },
      initialCoords: { x: element.x, y: element.y },
    };

    const isSelected = bulkSelectedElements.some((el) =>
      isSameElement(el, elementInBulk),
    );

    if (e.ctrlKey || e.metaKey) {
      if (isSelected) {
        if (bulkSelectedElements.length > 1) {
          setBulkSelectedElements(
            bulkSelectedElements.filter(
              (el) => !isSameElement(el, elementInBulk),
            ),
          );
          setSelectedElement({
            ...selectedElement,
            element: ObjectType.NONE,
            id: -1,
            open: false,
          });
        }
      } else {
        setBulkSelectedElements([...bulkSelectedElements, elementInBulk]);
      }
      setDragging(notDragging);
      return;
    }

    if (!isSelected) {
      setBulkSelectedElements([elementInBulk]);
    }
    setDragging({
      id: element.id,
      type,
      grabOffset: {
        x: pointer.spaces.diagram.x - element.x,
        y: pointer.spaces.diagram.y - element.y,
      },
    });
  };

  const coordinatesAfterSnappingToGrid = ({ x, y }) => {
    if (settings.snapToGrid) {
      return {
        x: Math.round(x / gridSize) * gridSize,
        y: Math.round(y / gridSize) * gridSize,
      };
    }
    return { x, y };
  };

  /**
   * @param {PointerEvent} e
   */
  const handlePointerMove = (e) => {
    if (selectedElement.open && !layout.sidebar) return;

    if (!e.isPrimary) return;

    if (panning.isPanning) {
      setTransform((prev) => ({
        ...prev,
        pan: {
          x:
            panning.panStart.x +
            (panning.cursorStart.x - pointer.spaces.screen.x) / transform.zoom,
          y:
            panning.panStart.y +
            (panning.cursorStart.y - pointer.spaces.screen.y) / transform.zoom,
        },
      }));
      return;
    }

    if (layout.readOnly) return;

    if (linking) {
      setLinkingLine({
        ...linkingLine,
        endX: pointer.spaces.diagram.x,
        endY: pointer.spaces.diagram.y,
      });
      return;
    }

    if (isDragging()) {
      const { x: mainElementFinalX, y: mainElementFinalY } =
        coordinatesAfterSnappingToGrid({
          x: pointer.spaces.diagram.x - dragging.grabOffset.x,
          y: pointer.spaces.diagram.y - dragging.grabOffset.y,
        });

      const { currentCoords } = bulkSelectedElements.find((el) =>
        isSameElement(el, dragging),
      );

      const deltaX = mainElementFinalX - currentCoords.x;
      const deltaY = mainElementFinalY - currentCoords.y;

      const newBulkSelectedElements = [];
      bulkSelectedElements.forEach((el) => {
        const elementFinalCoords = {
          x: el.currentCoords.x + deltaX,
          y: el.currentCoords.y + deltaY,
        };
        if (el.type === ObjectType.TABLE) {
          updateTable(el.id, { ...elementFinalCoords });
        }
        if (el.type === ObjectType.AREA) {
          updateArea(el.id, { ...elementFinalCoords });
        }
        if (el.type === ObjectType.NOTE) {
          updateNote(el.id, { ...elementFinalCoords });
        }
        newBulkSelectedElements.push({
          ...el,
          currentCoords: elementFinalCoords,
        });
      });

      setBulkSelectedElements(newBulkSelectedElements);
      return;
    }

    if (areaResize.id !== -1) {
      if (areaResize.dir === "none") return;
      let newDims = { ...areaInitDimensions };
      setPanning((old) => ({ ...old, isPanning: false }));
      const { x, y } = coordinatesAfterSnappingToGrid(pointer.spaces.diagram);

      switch (areaResize.dir) {
        case "br":
          newDims.width = x - areaInitDimensions.x;
          newDims.height = y - areaInitDimensions.y;
          break;
        case "tl":
          newDims.x = x;
          newDims.y = y;
          newDims.width = areaInitDimensions.width - (x - areaInitDimensions.x);
          newDims.height =
            areaInitDimensions.height - (y - areaInitDimensions.y);
          break;
        case "tr":
          newDims.y = y;
          newDims.width = x - areaInitDimensions.x;
          newDims.height =
            areaInitDimensions.height - (y - areaInitDimensions.y);
          break;
        case "bl":
          newDims.x = x;
          newDims.width = areaInitDimensions.width - (x - areaInitDimensions.x);
          newDims.height = y - areaInitDimensions.y;
          break;
      }

      if (newDims.width <= minAreaSize) {
        newDims.width = minAreaSize;
        if (areaResize.dir === "tl" || areaResize.dir === "bl") {
          newDims.x =
            areaInitDimensions.x + areaInitDimensions.width - minAreaSize;
        }
      }

      if (newDims.height <= minAreaSize) {
        newDims.height = minAreaSize;
        if (areaResize.dir === "tl" || areaResize.dir === "tr") {
          newDims.y =
            areaInitDimensions.y + areaInitDimensions.height - minAreaSize;
        }
      }

      updateArea(areaResize.id, { ...newDims });
      return;
    }

    if (bulkSelectRect.show) {
      setBulkSelectRect((prev) => ({
        ...prev,
        x2: pointer.spaces.diagram.x,
        y2: pointer.spaces.diagram.y,
      }));
    }
  };

  /**
   * @param {PointerEvent} e
   */
  const handlePointerDown = (e) => {
    if (!e.isPrimary) return;

    // don't pan if the sidesheet for editing a table is open
    if (
      selectedElement.element === ObjectType.TABLE &&
      selectedElement.open &&
      !layout.sidebar
    )
      return;

    const isMouseLeftButton = e.button === 0;
    const isMouseMiddleButton = e.button === 1;
    const isMouseRightButton = e.button === 2;

    if (isMouseLeftButton && panMode) {
      startPanning();
      return;
    }

    if (isMouseLeftButton) {
      setBulkSelectRect({
        x1: pointer.spaces.diagram.x,
        y1: pointer.spaces.diagram.y,
        x2: pointer.spaces.diagram.x,
        y2: pointer.spaces.diagram.y,
        show: elementPointerDown === null || !elementPointerDown.element.locked,
        ctrlKey: e.ctrlKey,
        metaKey: e.metaKey,
      });
      if (elementPointerDown !== null) {
        handlePointerDownOnElement(e, elementPointerDown);
      }
      pointer.setStyle("crosshair");
    } else if (isMouseMiddleButton || isMouseRightButton) {
      if (isMouseRightButton) rightClickPanned.current = false;
      startPanning();
    }
  };

  const categories = collectCategories(tables);
  const hiddenCategories = settings.hiddenCategories ?? [];

  const toggleCategory = (category) => {
    setSettings((prev) => {
      const hidden = prev.hiddenCategories ?? [];
      return {
        ...prev,
        hiddenCategories: hidden.includes(category)
          ? hidden.filter((c) => c !== category)
          : [...hidden, category],
      };
    });
  };

  const showAllCategories = () =>
    setSettings((prev) => ({ ...prev, hiddenCategories: [] }));

  const toggleBusinessView = () =>
    setSettings((prev) => ({ ...prev, businessView: !prev.businessView }));

  const generateBlocks = () => {
    if (layout.readOnly) return;

    const result = blocksFromCategories(tables, areas, {
      tableWidth: settings.tableWidth,
      showComments: settings.showComments,
      relationships,
    });

    if (result.created === 0 && result.refitted === 0) {
      Toast.info(t("no_categories_for_blocks"));
      return;
    }

    // One snapshot rather than an entry per area: the generator rewrites
    // several at once and area ids are array indices.
    setUndoStack((prev) => [
      ...prev,
      {
        action: Action.EDIT,
        element: ObjectType.AREA,
        component: "bulk",
        undo: areas.map((area) => ({ ...area })),
        redo: result.areas,
        message: t("generate_blocks"),
      },
    ]);
    setRedoStack([]);
    setAreas(result.areas);
    Toast.success(
      t("blocks_generated", {
        created: result.created,
        refitted: result.refitted,
      }),
    );
  };

  const selectedTableIds = bulkSelectedElements
    .filter((el) => el.type === ObjectType.TABLE)
    .map((el) => el.id);

  const selectedArea =
    selectedElement.element === ObjectType.AREA
      ? areas.find((a) => a.id === selectedElement.id)
      : null;

  const orphanTables = tablesWithoutCard(tables, areas);

  const commitAreas = (nextAreas, message) => {
    setUndoStack((prev) => [
      ...prev,
      {
        action: Action.EDIT,
        element: ObjectType.AREA,
        component: "bulk",
        undo: areas.map((area) => ({ ...area })),
        redo: nextAreas,
        message,
      },
    ]);
    setRedoStack([]);
    setAreas(nextAreas);
  };

  const createCardFromSelection = () => {
    if (layout.readOnly || selectedTableIds.length === 0) return;

    const result = cardFromSelection(tables, areas, selectedTableIds);
    if (!result.card) return;

    commitAreas(result.areas, t("create_card"));
    setBulkSelectedElements([]);
    setSelectedElement((prev) => ({
      ...prev,
      element: ObjectType.AREA,
      id: result.card.id,
      open: false,
    }));
    Toast.success(t("card_created", { count: result.card.tableIds.length }));
  };

  const setAreaKind = (kind) => {
    if (layout.readOnly || !selectedArea) return;
    commitAreas(
      areas.map((area) =>
        area.id === selectedArea.id ? { ...area, kind } : { ...area },
      ),
      t("edit_area", { areaName: selectedArea.name, extra: "[kind]" }),
    );
  };

  const blockLinks = settings.businessView
    ? aggregateBlockLinks(tables, relationships, areas)
    : [];

  const startPanning = () => {
    setPanning({
      isPanning: true,
      panStart: transform.pan,
      // Diagram space depends on the current panning.
      // Use screen space to avoid circular dependencies and undefined behavior.
      cursorStart: pointer.spaces.screen,
    });
    pointer.setStyle("grabbing");
  };

  const isDragging = () => {
    return dragging.type !== ObjectType.NONE && dragging.id !== -1;
  };

  const didDrag = () => {
    if (!isDragging()) return false;
    // checking any element is sufficient
    const { currentCoords, initialCoords } = bulkSelectedElements[0];
    return (
      currentCoords.x !== initialCoords.x || currentCoords.y !== initialCoords.y
    );
  };

  const didResize = (id) => {
    return !(
      areas[id].x === areaInitDimensions.x &&
      areas[id].y === areaInitDimensions.y &&
      areas[id].width === areaInitDimensions.width &&
      areas[id].height === areaInitDimensions.height
    );
  };

  const didPan = () =>
    !(
      transform.pan.x === panning.panStart.x &&
      transform.pan.y === panning.panStart.y
    );

  /**
   * @param {PointerEvent} e
   */
  const handlePointerUp = (e) => {
    if (selectedElement.open && !layout.sidebar) return;

    if (!e.isPrimary) return;

    if (didDrag()) {
      setUndoStack((prev) => [
        ...prev,
        {
          action: Action.MOVE,
          bulk: true,
          message: t("bulk_update"),
          elements: bulkSelectedElements.map((el) => ({
            id: el.id,
            type: el.type,
            undo: el.initialCoords,
            redo: el.currentCoords,
          })),
        },
      ]);
      setRedoStack([]);
      setBulkSelectedElements((prev) =>
        prev.map((el) => ({
          ...el,
          initialCoords: { ...el.currentCoords },
        })),
      );
    }

    if (bulkSelectRect.show) {
      setBulkSelectRect((prev) => ({
        ...prev,
        x2: pointer.spaces.diagram.x,
        y2: pointer.spaces.diagram.y,
        show: false,
      }));
      if (!isDragging()) {
        collectSelectedElements();
      }
    }
    setDragging(notDragging);

    if (panning.isPanning && didPan()) {
      setSaveState(State.SAVING);
      if (e.button === 2) rightClickPanned.current = true;
    }
    setPanning((old) => ({ ...old, isPanning: false }));
    pointer.setStyle(panMode ? "grab" : "default");

    if (linking) handleLinking();
    setLinking(false);

    if (areaResize.id !== -1 && didResize(areaResize.id)) {
      setUndoStack((prev) => [
        ...prev,
        {
          action: Action.EDIT,
          element: ObjectType.AREA,
          aid: areaResize.id,
          undo: {
            ...areas[areaResize.id],
            x: areaInitDimensions.x,
            y: areaInitDimensions.y,
            width: areaInitDimensions.width,
            height: areaInitDimensions.height,
          },
          redo: areas[areaResize.id],
          message: t("edit_area", {
            areaName: areas[areaResize.id].name,
            extra: "[resize]",
          }),
        },
      ]);
      setRedoStack([]);
    }
    setAreaResize({ id: -1, dir: "none" });
    setAreaInitDimensions({
      x: 0,
      y: 0,
      width: 0,
      height: 0,
    });
  };

  const handleGripField = () => {
    setPanning((old) => ({ ...old, isPanning: false }));
    setDragging(notDragging);
    setLinking(true);
  };

  const getCardinality = (startField, endField) => {
    const startIsUnique = startField.unique || startField.primary;
    const endIsUnique = endField.unique || endField.primary;

    if (startIsUnique && endIsUnique) {
      return Cardinality.ONE_TO_ONE;
    }

    if (startIsUnique && !endIsUnique) {
      return Cardinality.ONE_TO_MANY;
    }

    if (!startIsUnique && endIsUnique) {
      return Cardinality.MANY_TO_ONE;
    }

    return Cardinality.ONE_TO_ONE;
  };

  const handleLinking = () => {
    if (hoveredTable.tableId === null) return;
    if (hoveredTable.fieldId === null) return;

    const { fields: startTableFields, name: startTableName } = tables.find(
      (t) => t.id === linkingLine.startTableId,
    );
    const startField = startTableFields.find(
      (f) => f.id === linkingLine.startFieldId,
    );
    const { fields: endTableFields, name: endTableName } = tables.find(
      (t) => t.id === hoveredTable.tableId,
    );
    const endField = endTableFields.find((f) => f.id === hoveredTable.fieldId);

    if (!areFieldsCompatible(database, startField.type, endField.type)) {
      Toast.info(t("cannot_connect"));
      return;
    }
    if (
      linkingLine.startTableId === hoveredTable.tableId &&
      linkingLine.startFieldId === hoveredTable.fieldId
    )
      return;

    const cardinality = getCardinality(startField, endField);

    const newRelationship = {
      ...linkingLine,
      cardinality,
      endTableId: hoveredTable.tableId,
      endFieldId: hoveredTable.fieldId,
      fields: [
        {
          startFieldId: linkingLine.startFieldId,
          endFieldId: hoveredTable.fieldId,
        },
      ],
      updateConstraint: Constraint.NONE,
      deleteConstraint: Constraint.NONE,
      name: `fk_${startTableName}_${startField.name}_${endTableName}`,
      id: nanoid(),
    };
    delete newRelationship.startX;
    delete newRelationship.startY;
    delete newRelationship.endX;
    delete newRelationship.endY;
    addRelationship(newRelationship);
  };

  const isTypingTarget = (target) =>
    target instanceof HTMLElement &&
    (target.tagName === "INPUT" ||
      target.tagName === "TEXTAREA" ||
      target.isContentEditable);

  useEventListener("keydown", (e) => {
    if (e.code !== "Space" || e.repeat) return;
    if (isTypingTarget(e.target)) return;
    // Space would otherwise scroll the page or re-trigger the focused button.
    e.preventDefault();
    setSpaceHeld(true);
  });

  useEventListener("keyup", (e) => {
    if (e.code !== "Space") return;
    setSpaceHeld(false);
  });

  // Alt-tabbing away while space is down would otherwise leave the hand on.
  useEventListener("blur", () => setSpaceHeld(false));

  // Single source of truth for the resting cursor; the drag handlers own it
  // only while a pan is actually in progress.
  const setPointerStyle = pointer.setStyle;
  useEffect(() => {
    if (panning.isPanning) return;
    setPointerStyle(panMode ? "grab" : "default");
  }, [panMode, panning.isPanning, setPointerStyle]);

  useEventListener(
    "wheel",
    (e) => {
      e.preventDefault();

      if (e.ctrlKey || e.metaKey) {
        const eagernessFactor = 0.05;
        setTransform((prev) => ({
          pan: {
            x:
              prev.pan.x -
              (pointer.spaces.diagram.x - prev.pan.x) *
                eagernessFactor *
                Math.sign(e.deltaY),
            y:
              prev.pan.y -
              (pointer.spaces.diagram.y - prev.pan.y) *
                eagernessFactor *
                Math.sign(e.deltaY),
          },
          zoom: e.deltaY <= 0 ? prev.zoom * 1.05 : prev.zoom / 1.05,
        }));
      } else if (e.shiftKey) {
        // A mouse wheel only reports deltaY, so shift maps it onto x.
        setTransform((prev) => ({
          ...prev,
          pan: {
            ...prev.pan,
            x: prev.pan.x + (e.deltaX || e.deltaY) / prev.zoom,
          },
        }));
      } else {
        // Trackpads and tilt wheels report deltaX for sideways scrolling; a
        // plain wheel leaves it at 0 and only pans vertically.
        setTransform((prev) => ({
          ...prev,
          pan: {
            x: prev.pan.x + e.deltaX / prev.zoom,
            y: prev.pan.y + e.deltaY / prev.zoom,
          },
        }));
      }
    },
    canvasRef,
    { passive: false },
  );

  return (
    <div className="grow h-full touch-none" id="canvas">
      <div
        className={`w-full h-full ${
          panning.isPanning
            ? "[&_*]:!cursor-grabbing"
            : panMode
              ? "[&_*]:!cursor-grab"
              : ""
        }`}
        style={{
          cursor: pointer.style,
          backgroundColor: settings.mode === "dark" ? darkBgTheme : "white",
        }}
      >
        <svg
          id="diagram"
          ref={canvasRef}
          onPointerMove={handlePointerMove}
          onPointerDown={handlePointerDown}
          onPointerUp={handlePointerUp}
          onContextMenu={(e) => {
            if (rightClickPanned.current) {
              e.preventDefault();
              rightClickPanned.current = false;
            }
          }}
          className="absolute w-full h-full touch-none"
          viewBox={`${viewBox.left} ${viewBox.top} ${viewBox.width} ${viewBox.height}`}
        >
          {settings.showGrid && (
            <>
              <defs>
                <pattern
                  id="pattern-grid"
                  x={-gridCircleRadius}
                  y={-gridCircleRadius}
                  width={gridSize}
                  height={gridSize}
                  patternUnits="userSpaceOnUse"
                  patternContentUnits="userSpaceOnUse"
                >
                  <circle
                    cx={gridCircleRadius}
                    cy={gridCircleRadius}
                    r={gridCircleRadius}
                    fill="rgb(99, 152, 191)"
                    opacity="1"
                  />
                </pattern>
              </defs>
              <rect
                x={viewBox.left}
                y={viewBox.top}
                width={viewBox.width}
                height={viewBox.height}
                fill="url(#pattern-grid)"
              />
            </>
          )}
          {/* Layers frame cards, so they are painted first no matter where they
              sit in the stored array. */}
          {[...areas]
            .sort((a, b) => (isLayer(a) ? 0 : 1) - (isLayer(b) ? 0 : 1))
            .map((a) => (
              <Area
                key={a.id}
                data={a}
                setResize={setAreaResize}
                setInitDimensions={setAreaInitDimensions}
                onPointerDown={() => {
                  elementPointerDown = {
                    element: a,
                    type: ObjectType.AREA,
                  };
                }}
              />
            ))}
          {/* Business view drops to block level: the blocks above stay, the
              tables and their individual relationships give way to one link
              per pair of blocks. */}
          {settings.businessView
            ? blockLinks.map((link) => (
                <g key={link.id} className="pointer-events-none select-none">
                  <line
                    x1={link.start.x}
                    y1={link.start.y}
                    x2={link.end.x}
                    y2={link.end.y}
                    className="relationship-path"
                    strokeWidth={2}
                  />
                  <circle
                    cx={link.label.x}
                    cy={link.label.y}
                    r={13}
                    fill="grey"
                  />
                  <text
                    x={link.label.x}
                    y={link.label.y}
                    fill="white"
                    textAnchor="middle"
                    alignmentBaseline="middle"
                    fontSize={13}
                    fontWeight={600}
                  >
                    {link.count}
                  </text>
                </g>
              ))
            : relationships.map((e) => <Relationship key={e.id} data={e} />)}
          {!settings.businessView &&
            tables.map((table) => (
              <Table
                key={table.id}
                tableData={table}
                setHoveredTable={setHoveredTable}
                handleGripField={handleGripField}
                setLinkingLine={setLinkingLine}
                onPointerDown={() => {
                  elementPointerDown = {
                    element: table,
                    type: ObjectType.TABLE,
                  };
                }}
              />
            ))}
          {linking && (
            <path
              d={`M ${linkingLine.startX} ${linkingLine.startY} L ${linkingLine.endX} ${linkingLine.endY}`}
              stroke="red"
              strokeDasharray="8,8"
              className="pointer-events-none touch-none"
            />
          )}
          <Slot name="svg-overlay" />
          {notes.map((n) => (
            <Note
              key={n.id}
              data={n}
              onPointerDown={() => {
                elementPointerDown = {
                  element: n,
                  type: ObjectType.NOTE,
                };
              }}
            />
          ))}
          {bulkSelectRect.show && (
            <rect
              {...getRectFromEndpoints(bulkSelectRect)}
              stroke="grey"
              fill="grey"
              fillOpacity={0.15}
              strokeDasharray={10}
            />
          )}
        </svg>
      </div>
      <div className="absolute bottom-4 left-4 z-20 flex flex-col gap-1 rounded-lg p-1 popover-theme">
        {[
          {
            active: !panMode,
            icon: "bi-cursor",
            label: t("select_tool"),
            hint: t("select_tool_hint"),
            onClick: () => setHandTool(false),
          },
          {
            active: panMode,
            icon: "bi-hand-index-thumb",
            label: t("pan_tool"),
            hint: t("pan_tool_hint"),
            onClick: () => setHandTool(true),
          },
        ].map((tool) => (
          <Tooltip
            key={tool.icon}
            position="right"
            content={
              <div>
                <div className="font-semibold">{tool.label}</div>
                <div className="text-xs opacity-80">{tool.hint}</div>
              </div>
            }
          >
            <button
              aria-label={tool.label}
              aria-pressed={tool.active}
              className={`px-3 py-2 rounded-md ${
                tool.active ? "bg-sky-600 text-white" : ""
              }`}
              onClick={tool.onClick}
            >
              <i className={`bi ${tool.icon}`} />
            </button>
          </Tooltip>
        ))}

        <Popover
          position="right"
          trigger="click"
          content={
            <div className="popover-theme flex flex-col py-1 min-w-[200px]">
              <div className="px-2 pb-1 text-xs opacity-70">
                {t("categories")}
              </div>
              {categories.map(({ category, count }) => {
                const off = hiddenCategories.includes(category);
                return (
                  <button
                    key={category || UNCATEGORIZED}
                    className="px-2 py-1.5 rounded-md flex items-center gap-2"
                    onClick={() => toggleCategory(category)}
                  >
                    <i
                      className={`bi ${off ? "bi-eye-slash" : "bi-eye"} ${
                        off ? "opacity-50" : ""
                      }`}
                    />
                    <span
                      className={`grow text-start ${off ? "opacity-50 line-through" : ""}`}
                    >
                      {category === UNCATEGORIZED
                        ? t("no_category")
                        : category.toUpperCase()}
                    </span>
                    <span className="text-xs opacity-60">{count}</span>
                  </button>
                );
              })}
              {hiddenCategories.length > 0 && (
                <>
                  <Divider className="!my-1" />
                  <button
                    className="px-2 py-1.5 text-start rounded-md"
                    onClick={showAllCategories}
                  >
                    {t("show_all_categories")}
                  </button>
                </>
              )}
            </div>
          }
        >
          <button
            aria-label={t("categories")}
            title={t("categories")}
            className={`px-3 py-2 rounded-md ${
              hiddenCategories.length > 0 ? "bg-sky-600 text-white" : ""
            }`}
          >
            <i className="bi bi-eye" />
          </button>
        </Popover>

        <Popover
          position="right"
          trigger="click"
          content={
            <div className="popover-theme flex flex-col py-1 min-w-[220px]">
              <div className="px-2 pb-1 text-xs opacity-70">
                {t("business_view_hint")}
              </div>
              <button
                className={`px-2 py-1.5 text-start rounded-md ${
                  settings.businessView ? "bg-sky-600 text-white" : ""
                }`}
                onClick={toggleBusinessView}
              >
                {settings.businessView
                  ? t("business_view_on")
                  : t("business_view_off")}
              </button>
              <Divider className="!my-1" />
              <button
                className="px-2 py-1.5 text-start rounded-md disabled:opacity-40"
                onClick={createCardFromSelection}
                disabled={layout.readOnly || selectedTableIds.length === 0}
              >
                {selectedTableIds.length > 0
                  ? t("create_card_from_selection", {
                      count: selectedTableIds.length,
                    })
                  : t("select_tables_first")}
              </button>
              <button
                className="px-2 py-1.5 text-start rounded-md"
                onClick={generateBlocks}
                disabled={layout.readOnly}
              >
                {t("generate_blocks")}
              </button>
              {selectedArea && (
                <>
                  <Divider className="!my-1" />
                  <button
                    className={`px-2 py-1.5 text-start rounded-md ${
                      isCard(selectedArea) ? "bg-sky-600 text-white" : ""
                    }`}
                    onClick={() => setAreaKind(CARD)}
                    disabled={layout.readOnly}
                  >
                    {t("make_card")}
                  </button>
                  <button
                    className={`px-2 py-1.5 text-start rounded-md ${
                      isLayer(selectedArea) ? "bg-sky-600 text-white" : ""
                    }`}
                    onClick={() => setAreaKind(LAYER)}
                    disabled={layout.readOnly}
                  >
                    {t("make_layer")}
                  </button>
                </>
              )}
              {orphanTables.length > 0 && (
                <>
                  <Divider className="!my-1" />
                  <div className="px-2 py-1 text-xs opacity-70">
                    {t("tables_without_card", { count: orphanTables.length })}
                  </div>
                </>
              )}
            </div>
          }
        >
          <button
            aria-label={t("business_view")}
            title={t("business_view")}
            className={`px-3 py-2 rounded-md ${
              settings.businessView ? "bg-sky-600 text-white" : ""
            }`}
          >
            <i className="bi bi-bounding-box" />
          </button>
        </Popover>
      </div>
      {settings.showDebugCoordinates && (
        <div className="fixed flex flex-col flex-wrap gap-6 bg-[rgba(var(--semi-grey-1),var(--tw-bg-opacity))]/40 border border-color bottom-4 right-4 p-4 rounded-xl backdrop-blur-xs pointer-events-none select-none">
          <table className="table-auto grow">
            <thead>
              <tr>
                <th className="text-left" colSpan={3}>
                  {t("transform")}
                </th>
              </tr>
              <tr className="italic [&_th]:font-normal [&_th]:text-right">
                <th>pan x</th>
                <th>pan y</th>
                <th>scale</th>
              </tr>
            </thead>
            <tbody className="[&_td]:text-right [&_td]:min-w-[8ch]">
              <tr>
                <td>{transform.pan.x.toFixed(2)}</td>
                <td>{transform.pan.y.toFixed(2)}</td>
                <td>{transform.zoom.toFixed(4)}</td>
              </tr>
            </tbody>
          </table>
          <table className="table-auto grow [&_th]:text-left [&_th:not(:first-of-type)]:text-right [&_td:not(:first-of-type)]:text-right [&_td]:min-w-[8ch]">
            <thead>
              <tr>
                <th colSpan={4}>{t("viewbox")}</th>
              </tr>
              <tr className="italic [&_th]:font-normal">
                <th>left</th>
                <th>top</th>
                <th>width</th>
                <th>height</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>{viewBox.left.toFixed(2)}</td>
                <td>{viewBox.top.toFixed(2)}</td>
                <td>{viewBox.width.toFixed(2)}</td>
                <td>{viewBox.height.toFixed(2)}</td>
              </tr>
            </tbody>
          </table>
          <table className="table-auto grow [&_th]:text-left [&_th:not(:first-of-type)]:text-right [&_td:not(:first-of-type)]:text-right [&_td]:min-w-[8ch]">
            <thead>
              <tr>
                <th colSpan={3}>{t("cursor_coordinates")}</th>
              </tr>
              <tr className="italic [&_th]:font-normal">
                <th>{t("coordinate_space")}</th>
                <th>x</th>
                <th>y</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>{t("coordinate_space_screen")}</td>
                <td>{pointer.spaces.screen.x.toFixed(2)}</td>
                <td>{pointer.spaces.screen.y.toFixed(2)}</td>
              </tr>
              <tr>
                <td>{t("coordinate_space_diagram")}</td>
                <td>{pointer.spaces.diagram.x.toFixed(2)}</td>
                <td>{pointer.spaces.diagram.y.toFixed(2)}</td>
              </tr>
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
