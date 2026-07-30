DROP TABLE IF EXISTS billing.expenses;

ALTER TABLE billing.payments DROP COLUMN IF EXISTS discount_amount;
ALTER TABLE billing.payments DROP COLUMN IF EXISTS promo_id;

ALTER TABLE content.promos DROP COLUMN IF EXISTS discount_value;
ALTER TABLE content.promos DROP COLUMN IF EXISTS discount_type;

ALTER TABLE clinical.odontogram_entries DROP COLUMN IF EXISTS photo_url;

DROP TABLE IF EXISTS identity.staff_skills;

ALTER TABLE identity.staff DROP COLUMN IF EXISTS commission_rate;

ALTER TABLE identity.patients DROP COLUMN IF EXISTS photo_url;
