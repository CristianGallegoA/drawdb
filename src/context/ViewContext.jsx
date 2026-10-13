import { createContext, useRef, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { View } from "../data/constants";

export const ViewContext = createContext(null);

/**
 * Which level of the diagram is on screen. Navigation only: switching levels
 * never edits the document, so it never dirties or saves it.
 */
export default function ViewContextProvider({ children }) {
  const [searchParams] = useSearchParams();
  const [view, setView] = useState(() =>
    searchParams.get("view") === View.OVERVIEW ? View.OVERVIEW : View.DETAIL,
  );
  // Key of the card being drilled into; null shows the whole level.
  const [focusKey, setFocusKey] = useState(null);
  // Camera per level, so coming back lands where you left.
  const cameras = useRef({});

  return (
    <ViewContext.Provider
      value={{ view, setView, focusKey, setFocusKey, cameras }}
    >
      {children}
    </ViewContext.Provider>
  );
}
