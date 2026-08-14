DROP TABLE IF EXISTS identity.point_transactions;
DROP TABLE IF EXISTS identity.point_settings;
ALTER TABLE identity.users DROP COLUMN IF EXISTS points;
