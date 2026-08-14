-- Migration for Point System (Settings, User Point Balance, & Point Transaction History)

-- 1. Add points balance column to identity.users
ALTER TABLE identity.users ADD COLUMN IF NOT EXISTS points INT NOT NULL DEFAULT 0;

-- 2. Point settings table (single configuration row with id = 1)
CREATE TABLE IF NOT EXISTS identity.point_settings (
  id INT PRIMARY KEY DEFAULT 1,
  points_per_reservation INT NOT NULL DEFAULT 50,
  points_per_spend_idr NUMERIC(12, 2) NOT NULL DEFAULT 10000,
  points_earned_per_spend INT NOT NULL DEFAULT 10,
  rupiah_per_point NUMERIC(12, 2) NOT NULL DEFAULT 100,
  min_redeem_points INT NOT NULL DEFAULT 50,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Seed default point settings row if not exists
INSERT INTO identity.point_settings (id, points_per_reservation, points_per_spend_idr, points_earned_per_spend, rupiah_per_point, min_redeem_points)
VALUES (1, 50, 10000, 10, 100, 50)
ON CONFLICT (id) DO NOTHING;

-- 3. Point transaction history ledger
CREATE TABLE IF NOT EXISTS identity.point_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES identity.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('earn', 'redeem', 'adjustment', 'bonus')),
  points INT NOT NULL,
  description TEXT NOT NULL,
  reference_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_point_transactions_user ON identity.point_transactions(user_id);
