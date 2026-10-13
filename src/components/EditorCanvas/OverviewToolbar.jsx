import { nanoid } from "nanoid";
import { Divider, Modal, Popover, Toast } from "@douyinfe/semi-ui";
import { useTranslation } from "react-i18next";
import {
  useAreas,
  useDiagram,
  useLayout,
  useSelect,
  useTransform,
  useViewNavigation,
} from "../../hooks";
import {
  CARD,
  LAYER,
  cardContentHeight,
  cardFromSelection,
  generateOverview,
  isCard,
  isOverviewArea,
  suggestLinks,
  tablesWithoutCard,
} from "../../utils/blocks";
import { ObjectType, defaultBlue } from "../../data/constants";

const reindex = (areas) => areas.map((area, i) => ({ ...area, id: i }));

/**
 * The tools of the overview: build a first draft from the model, add cards and
 * blocks by hand, and accept the arrows the foreign keys suggest.
 */
export default function OverviewToolbar() {
  const { t } = useTranslation();
  const { areas, commitAreas } = useAreas();
  const { tables, relationships } = useDiagram();
  const { transform } = useTransform();
  const { layout } = useLayout();
  const { setSelectedElement, bulkSelectedElements, setBulkSelectedElements } =
    useSelect();
  const { frameOverview } = useViewNavigation();

  const cards = areas.filter(isCard);
  const hasOverview = areas.some(isOverviewArea);
  const orphans = tablesWithoutCard(tables, areas);
  const suggestions = suggestLinks(relationships, cards);
  const selectedTableIds = bulkSelectedElements
    .filter((el) => el.type === ObjectType.TABLE)
    .map((el) => el.id);

  const generate = () => {
    if (layout.readOnly) return;
    const run = () => {
      const result = generateOverview(tables, areas, {
        uncategorized: t("no_category"),
      });
      if (result.cards === 0) {
        Toast.info(t("no_tables_for_overview"));
        return;
      }
      commitAreas(result.areas, t("generate_overview"));
      frameOverview(result.areas);
      Toast.success(
        t("overview_generated", {
          blocks: result.blocks,
          cards: result.cards,
        }),
      );
    };
    if (!hasOverview) return run();
    Modal.confirm({
      title: t("generate_overview"),
      content: t("regenerate_overview_confirm"),
      onOk: run,
    });
  };

  const addOverviewArea = (kind) => {
    if (layout.readOnly) return;
    const base = {
      kind,
      key: nanoid(8),
      name: kind === CARD ? t("new_card").toUpperCase() : t("new_block"),
      color: defaultBlue,
      locked: false,
      x: Math.round(transform.pan.x - 160),
      y: Math.round(transform.pan.y - 100),
      width: 320,
      height: 200,
    };
    const card =
      kind === CARD
        ? {
            ...base,
            category: "",
            description: "",
            tableIds: [],
            links: [],
          }
        : base;
    if (kind === CARD) card.height = cardContentHeight(card, tables);
    const next = reindex([...areas, card]);
    commitAreas(next, kind === CARD ? t("new_card") : t("new_block"));
    setSelectedElement((prev) => ({
      ...prev,
      element: ObjectType.AREA,
      id: next.length - 1,
      open: false,
    }));
  };

  const cardFromOrphans = () => {
    if (layout.readOnly || orphans.length === 0) return;
    const result = cardFromSelection(
      tables,
      areas,
      orphans.map((table) => table.id),
      { at: { x: transform.pan.x - 160, y: transform.pan.y - 100 } },
    );
    if (!result.card) return;
    commitAreas(result.areas, t("create_card"));
    Toast.success(t("card_created", { count: result.card.tableIds.length }));
  };

  const cardFromSelected = () => {
    if (layout.readOnly || selectedTableIds.length === 0) return;
    const result = cardFromSelection(tables, areas, selectedTableIds);
    if (!result.card) return;
    commitAreas(result.areas, t("create_card"));
    setBulkSelectedElements([]);
    Toast.success(t("card_created", { count: result.card.tableIds.length }));
  };

  const acceptSuggestion = ({ from, to }) => {
    if (layout.readOnly) return;
    commitAreas(
      areas.map((area) =>
        area.id === from.id
          ? {
              ...area,
              links: [
                ...(area.links ?? []),
                { to: to.key, label: "", dashed: false },
              ],
            }
          : area,
      ),
      t("edit_area", { areaName: from.name, extra: "[links]" }),
    );
  };

  const row =
    "px-2 py-1.5 text-start rounded-md disabled:opacity-40 hover:bg-[rgba(var(--semi-grey-2),1)]";

  return (
    <Popover
      position="right"
      trigger="click"
      content={
        <div className="popover-theme flex flex-col py-1 min-w-[260px] max-h-[70vh] overflow-y-auto">
          {!hasOverview && (
            <div className="px-2 py-1 text-xs opacity-70">
              {t("empty_overview")}
            </div>
          )}
          <button className={row} onClick={generate} disabled={layout.readOnly}>
            <i className="bi bi-magic me-2" />
            {t("generate_overview")}
          </button>
          <Divider className="!my-1" />
          <button
            className={row}
            onClick={() => addOverviewArea(CARD)}
            disabled={layout.readOnly}
          >
            <i className="bi bi-plus-square me-2" />
            {t("new_card")}
          </button>
          <button
            className={row}
            onClick={() => addOverviewArea(LAYER)}
            disabled={layout.readOnly}
          >
            <i className="bi bi-bounding-box me-2" />
            {t("new_block")}
          </button>
          {selectedTableIds.length > 0 && (
            <button
              className={row}
              onClick={cardFromSelected}
              disabled={layout.readOnly}
            >
              <i className="bi bi-collection me-2" />
              {t("create_card_from_selection", {
                count: selectedTableIds.length,
              })}
            </button>
          )}
          {orphans.length > 0 && (
            <button
              className={row}
              onClick={cardFromOrphans}
              disabled={layout.readOnly}
            >
              <i className="bi bi-collection me-2" />
              {t("create_card_from_orphans", { count: orphans.length })}
            </button>
          )}
          {suggestions.length > 0 && (
            <>
              <Divider className="!my-1" />
              <div className="px-2 py-1 text-xs opacity-70">
                {t("suggested_links")}
              </div>
              {suggestions.map((s) => (
                <button
                  key={`${s.from.key}-${s.to.key}`}
                  className={`${row} flex items-center gap-2`}
                  onClick={() => acceptSuggestion(s)}
                  disabled={layout.readOnly}
                >
                  <span className="grow text-start text-xs truncate">
                    {s.from.name} → {s.to.name}
                  </span>
                  <span className="text-xs opacity-60 shrink-0">
                    {t("fk_count", { count: s.count })}
                  </span>
                  <i className="bi bi-plus-lg shrink-0" />
                </button>
              ))}
            </>
          )}
        </div>
      }
    >
      <button
        aria-label={t("overview")}
        title={t("overview")}
        className="px-3 py-2 rounded-md"
      >
        <i className="bi bi-magic" />
      </button>
    </Popover>
  );
}
