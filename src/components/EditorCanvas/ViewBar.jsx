import { useEffect, useRef } from "react";
import { useEventListener } from "usehooks-ts";
import { useTranslation } from "react-i18next";
import { useAreas, useViewNavigation } from "../../hooks";
import { isLayer, isOverviewArea, layerMembers } from "../../utils/blocks";
import { isTypingTarget } from "../../utils/utils";

/**
 * Where you are and how to move: overview ⇄ detail and, inside a card, the
 * trail back plus previous / next to walk a room through the model.
 */
export default function ViewBar() {
  const { t } = useTranslation();
  const { areas } = useAreas();
  const {
    isOverview,
    focusCard,
    frameOverview,
    showOverview,
    showDetail,
    step,
    showInFullDiagram,
  } = useViewNavigation();

  const block =
    focusCard &&
    areas.find(
      (area) =>
        isLayer(area) &&
        layerMembers(areas, area).some((card) => card.key === focusCard.key),
    );

  useEventListener("keydown", (e) => {
    if (!focusCard || isTypingTarget(e.target)) return;
    if (e.key === "Escape") showOverview();
    else if (e.key === "ArrowRight") step(1);
    else if (e.key === "ArrowLeft") step(-1);
  });

  // Opened through a ?view=overview link: frame the overview once it loads.
  const hasOverview = areas.some(isOverviewArea);
  const framedRef = useRef(false);
  useEffect(() => {
    if (framedRef.current || !isOverview || !hasOverview) return;
    framedRef.current = true;
    frameOverview();
  }, [isOverview, hasOverview, frameOverview]);

  const tab = (active) =>
    `px-3 py-1.5 rounded-md text-sm ${active ? "bg-sky-600 text-white" : ""}`;

  return (
    <div className="absolute top-4 left-1/2 -translate-x-1/2 z-20 flex items-center gap-1 rounded-lg p-1 popover-theme">
      <button className={tab(isOverview)} onClick={showOverview}>
        <i className="bi bi-grid-1x2 me-1.5" />
        {t("overview")}
      </button>
      <button className={tab(!isOverview && !focusCard)} onClick={showDetail}>
        <i className="bi bi-diagram-3 me-1.5" />
        {t("detail")}
      </button>
      {focusCard && (
        <>
          <i className="bi bi-chevron-right text-xs opacity-50" />
          {block && <span className="text-sm opacity-70">{block.name}</span>}
          {block && <i className="bi bi-chevron-right text-xs opacity-50" />}
          <span
            className="px-1 text-sm font-semibold"
            style={{ color: focusCard.color }}
          >
            {focusCard.name}
          </span>
          <button
            className="px-2 py-1.5 rounded-md"
            title={t("previous_card")}
            onClick={() => step(-1)}
          >
            <i className="bi bi-chevron-left" />
          </button>
          <button
            className="px-2 py-1.5 rounded-md"
            title={t("next_card")}
            onClick={() => step(1)}
          >
            <i className="bi bi-chevron-right" />
          </button>
          <button
            className="px-2 py-1.5 rounded-md"
            title={t("show_in_full_diagram")}
            onClick={() => showInFullDiagram(focusCard)}
          >
            <i className="bi bi-arrows-angle-expand" />
          </button>
        </>
      )}
    </div>
  );
}
