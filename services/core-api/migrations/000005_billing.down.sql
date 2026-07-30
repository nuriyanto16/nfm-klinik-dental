DROP TABLE IF EXISTS billing.loyalty_points;
DROP TABLE IF EXISTS billing.membership_tiers;
DROP TABLE IF EXISTS billing.payment_events;
DROP TABLE IF EXISTS billing.payments;
DROP TYPE IF EXISTS billing.payment_status;
ALTER TABLE scheduling.reservation_treatments DROP CONSTRAINT IF EXISTS fk_reservation_treatments_treatment;
DROP TABLE IF EXISTS billing.treatments;
DROP TABLE IF EXISTS billing.treatment_categories;
