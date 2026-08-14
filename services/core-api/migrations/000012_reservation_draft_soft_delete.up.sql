-- 000012_reservation_draft_soft_delete.up.sql
ALTER TYPE scheduling.reservation_status ADD VALUE IF NOT EXISTS 'draft' BEFORE 'pending';
ALTER TYPE scheduling.reservation_status ADD VALUE IF NOT EXISTS 'deleted';

ALTER TABLE scheduling.reservations ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;
CREATE INDEX IF NOT EXISTS idx_reservations_deleted_at ON scheduling.reservations(deleted_at);
