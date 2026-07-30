-- Inventory (alat & obat) used during a clinical encounter (tindakan
-- pemeriksaan), so office/klinis staff can track consumption per medical
-- record and see stock levels — the "penggunaan alat, obat dari tindakan
-- pemeriksaan" module.
CREATE TYPE billing.inventory_category AS ENUM ('obat', 'alat');

CREATE TABLE billing.inventory_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  category billing.inventory_category NOT NULL,
  unit TEXT NOT NULL DEFAULT 'pcs',
  stock_quantity NUMERIC(12, 2) NOT NULL DEFAULT 0,
  unit_price NUMERIC(12, 2) NOT NULL DEFAULT 0,
  reorder_threshold NUMERIC(12, 2) NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- One row per item used while recording a medical record (the clinical
-- encounter). Recording a usage decrements inventory_items.stock_quantity
-- in the same transaction (application-level, see internal/clinical).
CREATE TABLE clinical.medical_record_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  medical_record_id UUID NOT NULL REFERENCES clinical.medical_records(id) ON DELETE CASCADE,
  inventory_item_id UUID NOT NULL REFERENCES billing.inventory_items(id),
  quantity NUMERIC(12, 2) NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_medical_record_items_record ON clinical.medical_record_items(medical_record_id);
