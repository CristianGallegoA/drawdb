import useView from "./useView";
import useTransform from "./useTransform";
import useAreas from "./useAreas";
import useDiagram from "./useDiagram";
import useSettings from "./useSettings";
import useSelect from "./useSelect";
import { View, ObjectType } from "../data/constants";
import {
  isCard,
  isOverviewArea,
  focusScene,
  tablesBounds,
  rectsBounds,
  orderedCards,
  tablesOfCard,
} from "../utils/blocks";
import { cameraFor } from "../utils/camera";

/**
 * Moving between the overview, one card and the full diagram. Leaving a whole
 * level remembers its camera, so coming back lands where you were; a card is
 * always framed fresh.
 */
export default function useViewNavigation() {
  const { view, setView, focusKey, setFocusKey, cameras } = useView();
  const { transform, setTransform } = useTransform();
  const { areas } = useAreas();
  const { tables, relationships } = useDiagram();
  const { settings } = useSettings();
  const { setSelectedElement, setBulkSelectedElements } = useSelect();

  const cards = areas.filter(isCard);
  const focusCard = cards.find((card) => card.key === focusKey) ?? null;

  const frame = (rect) => {
    const camera = cameraFor(rect);
    if (camera) setTransform(camera);
  };

  // Only whole levels are remembered; a card is always framed fresh.
  const leave = () => {
    if (!focusKey) cameras.current[view] = transform;
  };

  const frameOverview = (list = areas) =>
    frame(rectsBounds(list.filter(isOverviewArea)));

  const showOverview = () => {
    leave();
    setFocusKey(null);
    setView(View.OVERVIEW);
    const saved = cameras.current[View.OVERVIEW];
    if (saved) setTransform(saved);
    else frameOverview();
  };

  const showDetail = () => {
    leave();
    setFocusKey(null);
    setView(View.DETAIL);
    const saved = cameras.current[View.DETAIL];
    if (saved) setTransform(saved);
    else frame(tablesBounds(tables, settings, relationships));
  };

  const drillDown = (card, tableId) => {
    if (!card?.key) return;
    leave();
    setView(View.DETAIL);
    setFocusKey(card.key);
    setBulkSelectedElements([]);
    // Same deterministic layout the canvas is about to draw.
    const scene = focusScene(tables, relationships, card, settings);
    frame(tablesBounds(scene, settings, relationships));
    if (tableId !== undefined) {
      setSelectedElement((prev) => ({
        ...prev,
        element: ObjectType.TABLE,
        id: tableId,
        open: false,
      }));
    }
  };

  const step = (delta) => {
    const ordered = orderedCards(cards);
    if (ordered.length === 0) return;
    const at = ordered.findIndex((card) => card.key === focusKey);
    drillDown(ordered[(at + delta + ordered.length) % ordered.length]);
  };

  // From a card to the real diagram: its tables framed and selected, so they
  // stand out wherever they happen to live.
  const showInFullDiagram = (card) => {
    const members = tablesOfCard(tables, card);
    leave();
    setFocusKey(null);
    setView(View.DETAIL);
    frame(tablesBounds(members, settings, relationships));
    setBulkSelectedElements(
      members.map((table) => ({
        id: table.id,
        type: ObjectType.TABLE,
        currentCoords: { x: table.x, y: table.y },
        initialCoords: { x: table.x, y: table.y },
      })),
    );
  };

  return {
    view,
    isOverview: view === View.OVERVIEW,
    focusCard,
    frameOverview,
    showOverview,
    showDetail,
    drillDown,
    step,
    showInFullDiagram,
  };
}
