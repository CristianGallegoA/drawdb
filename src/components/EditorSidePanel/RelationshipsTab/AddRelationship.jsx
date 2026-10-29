import { useState } from "react";
import { Button, Modal, Select, Toast } from "@douyinfe/semi-ui";
import { IconPlus } from "@douyinfe/semi-icons";
import { useTranslation } from "react-i18next";
import { useDiagram, useLayout, useSelect } from "../../../hooks";
import { ObjectType } from "../../../data/constants";
import { areFieldsCompatible } from "../../../utils/utils";
import { buildRelationship } from "../../../utils/autoRelationships";

const unset = { tableId: null, fieldId: null };

/**
 * Picks both ends of a relationship from lists, for when the tables are too
 * far apart (or too many) to drag a line between them on the canvas.
 */
export default function AddRelationship() {
  const { tables, database, addRelationship } = useDiagram();
  const { setSelectedElement } = useSelect();
  const { layout } = useLayout();
  const { t } = useTranslation();
  const [visible, setVisible] = useState(false);
  // Same convention as the canvas: start is the foreign side, end the primary.
  const [start, setStart] = useState(unset);
  const [end, setEnd] = useState(unset);

  const tableOptions = tables.map((table) => ({
    label: table.name,
    value: table.id,
  }));
  const fieldOptions = (tableId) =>
    (tables.find((table) => table.id === tableId)?.fields ?? []).map(
      (field) => ({ label: `${field.name} (${field.type})`, value: field.id }),
    );

  const resolve = ({ tableId, fieldId }) => {
    const table = tables.find((tb) => tb.id === tableId);
    return { table, field: table?.fields.find((f) => f.id === fieldId) };
  };

  const close = () => {
    setVisible(false);
    setStart(unset);
    setEnd(unset);
  };

  const add = () => {
    const from = resolve(start);
    const to = resolve(end);
    if (!areFieldsCompatible(database, from.field.type, to.field.type)) {
      Toast.info(t("cannot_connect"));
      return;
    }
    const relationship = buildRelationship(
      from.table,
      from.field,
      to.table,
      to.field,
    );
    addRelationship(relationship);
    setSelectedElement((prev) => ({
      ...prev,
      element: ObjectType.RELATIONSHIP,
      id: relationship.id,
      open: true,
    }));
    close();
  };

  const complete =
    resolve(start).field !== undefined &&
    resolve(end).field !== undefined &&
    !(start.tableId === end.tableId && start.fieldId === end.fieldId);

  const side = (label, value, setValue, pickPrimaryKey) => (
    <div className="mb-4">
      <div className="font-semibold mb-1">{label}:</div>
      <div className="grid grid-cols-2 gap-2">
        <Select
          filter
          className="w-full"
          placeholder={t("select_table")}
          optionList={tableOptions}
          value={value.tableId ?? undefined}
          onChange={(tableId) => {
            const table = tables.find((tb) => tb.id === tableId);
            // The referenced side is nearly always the primary key.
            const key = pickPrimaryKey
              ? table?.fields.find((f) => f.primary)
              : undefined;
            setValue({ tableId, fieldId: key?.id ?? null });
          }}
        />
        <Select
          filter
          className="w-full"
          placeholder={t("select_field")}
          disabled={value.tableId === null}
          optionList={fieldOptions(value.tableId)}
          value={value.fieldId ?? undefined}
          onChange={(fieldId) => setValue({ ...value, fieldId })}
        />
      </div>
    </div>
  );

  return (
    <>
      <Button
        block
        icon={<IconPlus />}
        onClick={() => setVisible(true)}
        disabled={layout.readOnly || tables.length === 0}
      >
        {t("add_relationship")}
      </Button>
      <Modal
        title={t("add_relationship")}
        visible={visible}
        onOk={add}
        onCancel={close}
        okText={t("add")}
        cancelText={t("cancel")}
        okButtonProps={{ disabled: !complete }}
        centered
      >
        {side(t("foreign"), start, setStart, false)}
        {side(t("primary"), end, setEnd, true)}
      </Modal>
    </>
  );
}
