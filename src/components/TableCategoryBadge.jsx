import { readableTextColor } from "../utils/utils";

/**
 * Small colored chip in front of a table name (core, stg, ref, erp, view...),
 * carrying the table's own color.
 */
export default function TableCategoryBadge({ category, color, className = "" }) {
  if (!category) return null;

  return (
    <span
      className={`shrink-0 rounded px-1.5 py-[2px] text-[10px] font-bold uppercase leading-none tracking-wide ${className}`}
      style={{ backgroundColor: color, color: readableTextColor(color) }}
      title={category}
    >
      {category}
    </span>
  );
}
