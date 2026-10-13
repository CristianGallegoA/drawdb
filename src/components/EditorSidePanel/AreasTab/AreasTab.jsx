import { Button } from "@douyinfe/semi-ui";
import { IconPlus } from "@douyinfe/semi-icons";
import Empty from "../Empty";
import { useAreas, useLayout, useView } from "../../../hooks";
import { isOverviewArea } from "../../../utils/blocks";
import SearchBar from "./SearchBar";
import AreaInfo from "./AreaDetails";
import { useTranslation } from "react-i18next";
import { View } from "../../../data/constants";

export default function AreasTab() {
  const { areas, addArea } = useAreas();
  const { layout } = useLayout();
  const { view } = useView();
  const { t } = useTranslation();

  // Each level manages its own areas: the overview's blocks and cards, or the
  // detail's plain areas. The stored id stays the undo handle, not the index.
  const visible = areas.filter(
    (area) => isOverviewArea(area) === (view === View.OVERVIEW),
  );

  return (
    <div>
      <div className="flex gap-2">
        <SearchBar />
        <div>
          <Button
            icon={<IconPlus />}
            block
            onClick={() => addArea()}
            disabled={layout.readOnly}
          >
            {t("add_area")}
          </Button>
        </div>
      </div>
      {visible.length <= 0 ? (
        <Empty
          title={t("no_subject_areas")}
          text={t("no_subject_areas_text")}
        />
      ) : (
        <div className="p-2">
          {visible.map((a) => (
            <AreaInfo data={a} key={"area_" + a.id} i={a.id} />
          ))}
        </div>
      )}
    </div>
  );
}
