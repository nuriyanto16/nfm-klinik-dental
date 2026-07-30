CREATE TABLE billing.treatment_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE billing.treatments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID NOT NULL REFERENCES billing.treatment_categories(id),
  name TEXT NOT NULL,
  description TEXT,
  price NUMERIC(12, 2) NOT NULL,
  duration_minutes SMALLINT NOT NULL DEFAULT 30,
  image_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE scheduling.reservation_treatments
  ADD CONSTRAINT fk_reservation_treatments_treatment
  FOREIGN KEY (treatment_id) REFERENCES billing.treatments(id);

CREATE TYPE billing.payment_status AS ENUM ('pending', 'paid', 'expired', 'failed', 'refunded');

CREATE TABLE billing.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reservation_id UUID NOT NULL REFERENCES scheduling.reservations(id),
  patient_id UUID NOT NULL REFERENCES identity.patients(id),
  amount NUMERIC(12, 2) NOT NULL,
  deposit_amount NUMERIC(12, 2) NOT NULL,
  status billing.payment_status NOT NULL DEFAULT 'pending',
  provider TEXT NOT NULL DEFAULT 'xendit',
  provider_reference TEXT,
  payment_method TEXT,
  expired_at TIMESTAMPTZ,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_payments_reservation ON billing.payments(reservation_id);

CREATE TABLE billing.payment_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id UUID NOT NULL REFERENCES billing.payments(id) ON DELETE CASCADE,
  provider_event_id TEXT NOT NULL,
  payload JSONB NOT NULL,
  received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (provider_event_id)
);

CREATE TABLE billing.membership_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  min_points INT NOT NULL,
  benefits JSONB NOT NULL DEFAULT '[]'
);

CREATE TABLE billing.loyalty_points (
  patient_id UUID PRIMARY KEY REFERENCES identity.patients(id) ON DELETE CASCADE,
  points INT NOT NULL DEFAULT 0,
  tier_id UUID REFERENCES billing.membership_tiers(id),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
