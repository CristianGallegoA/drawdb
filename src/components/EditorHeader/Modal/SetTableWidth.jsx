import { InputNumber } from "@douyinfe/semi-ui";
import { useTranslation } from "react-i18next";
import { useLayout } from "../../../hooks";
import { minTableWidth, maxTableWidth } from "../../../data/constants";

export default function SetTableWidth({ tempWidth, setTempWidth }) {
  const { layout } = useLayout();
  const { t } = useTranslation();

  return (
    <>
      <div className="text-sm mb-2 opacity-80">{t("default_table_width")}</div>
      <InputNumber
        className="w-full"
        value={tempWidth}
        min={minTableWidth}
        max={maxTableWidth}
        readonly={layout.readOnly}
        onChange={(c) => {
          if (c < minTableWidth || c > maxTableWidth) return;
          setTempWidth(c);
        }}
      />
    </>
  );
}
