-- Enrichment round: doctor profile depth (skills/commission), patient
-- profile depth (photo/loyalty), promo-aware billing, and expense tracking
-- for the profit/commission reports — see docs/architecture.md.

ALTER TABLE identity.patients ADD COLUMN photo_url TEXT;

ALTER TABLE identity.staff ADD COLUMN commission_rate NUMERIC(5, 2) NOT NULL DEFAULT 0;

-- A doctor's declared capabilities (e.g. "Ortodonti" / "Bedah Mulut"), shown
-- as a radar-style skill chart on the doctor detail panel.
CREATE TABLE identity.staff_skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id UUID NOT NULL REFERENCES identity.staff(id) ON DELETE CASCADE,
  skill_name TEXT NOT NULL,
  proficiency SMALLINT NOT NULL CHECK (proficiency BETWEEN 1 AND 5),
  years_experience SMALLINT
);

CREATE INDEX idx_staff_skills_staff ON identity.staff_skills(staff_id);

-- Photo per odontogram entry lets the patient panel show a "before vs
-- after" comparison across the earliest and latest medical record for a
-- patient (e.g. braces progression) without a separate attachments system.
ALTER TABLE clinical.odontogram_entries ADD COLUMN photo_url TEXT;

-- Promo support in billing: a payment can reference the promo that was
-- applied at checkout (POS or online) and the resulting discount.
ALTER TABLE content.promos ADD COLUMN discount_type TEXT CHECK (discount_type IN ('percentage', 'fixed'));
ALTER TABLE content.promos ADD COLUMN discount_value NUMERIC(12, 2);

ALTER TABLE billing.payments ADD COLUMN promo_id UUID REFERENCES content.promos(id);
ALTER TABLE billing.payments ADD COLUMN discount_amount NUMERIC(12, 2) NOT NULL DEFAULT 0;

-- Operating costs, for the "laporan pembiayaan"/profit report (revenue -
-- expenses - commission).
CREATE TABLE billing.expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID REFERENCES scheduling.branches(id),
  category TEXT NOT NULL,
  description TEXT,
  amount NUMERIC(12, 2) NOT NULL,
  expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_expenses_date ON billing.expenses(expense_date);
