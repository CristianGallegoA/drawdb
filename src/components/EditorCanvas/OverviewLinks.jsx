import { useDiagram, useSettings } from "../../hooks";
import { renderedHeight, linkRoute } from "../../utils/blocks";
import { roundedPolyline } from "../../utils/calcPath";
import { darkBgTheme } from "../../data/constants";

const markerId = (color) => `overview-arrow-${color.replace("#", "")}`;

/**
 * The arrows of the overview, drawn from what each card says it points to.
 * Never inferred: the story they tell is the designer's.
 */
export default function OverviewLinks({ cards }) {
  const { tables } = useDiagram();
  const { settings } = useSettings();
  const background = settings.mode === "dark" ? darkBgTheme : "white";

  const byKey = new Map(
    cards
      .filter((card) => card.key)
      .map((card) => [
        card.key,
        { ...card, height: renderedHeight(card, tables) },
      ]),
  );
  const colors = [...new Set(cards.map((card) => card.color))];

  return (
    <g className="pointer-events-none select-none">
      <defs>
        {colors.map((color) => (
          <marker
            key={color}
            id={markerId(color)}
            viewBox="0 0 10 10"
            refX="9"
            refY="5"
            markerWidth="7"
            markerHeight="7"
            orient="auto-start-reverse"
          >
            <path d="M 0 0 L 10 5 L 0 10 z" fill={color} />
          </marker>
        ))}
      </defs>
      {cards.flatMap((card) => {
        const from = byKey.get(card.key);
        if (!from) return [];
        return (card.links ?? []).map((link, i) => {
          const to = byKey.get(link.to);
          // A link to a deleted card is skipped, not drawn to nowhere.
          if (!to) return null;
          const { points, label } = linkRoute(from, to);
          return (
            <g key={`${card.key}-${i}`}>
              <path
                d={roundedPolyline(points, 12)}
                fill="none"
                stroke={card.color}
                strokeWidth={2.5}
                strokeDasharray={link.dashed ? "8 6" : undefined}
                markerEnd={`url(#${markerId(card.color)})`}
              />
              {link.label && (
                <text
                  x={label.x}
                  y={label.y}
                  textAnchor="middle"
                  dominantBaseline="middle"
                  fontSize={13}
                  fontWeight={600}
                  className="fill-current text-color"
                  stroke={background}
                  strokeWidth={5}
                  paintOrder="stroke"
                >
                  {link.label}
                </text>
              )}
            </g>
          );
        });
      })}
    </g>
  );
}
