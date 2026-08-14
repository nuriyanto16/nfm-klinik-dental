-- 000012_reservation_draft_soft_delete.down.sql
DROP INDEX IF EXISTS scheduling.idx_reservations_deleted_at;
ALTER TABLE scheduling.reservations DROP COLUMN IF EXISTS deleted_at;
