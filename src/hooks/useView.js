import { useContext } from "react";
import { ViewContext } from "../context/ViewContext";

export default function useView() {
  return useContext(ViewContext);
}
