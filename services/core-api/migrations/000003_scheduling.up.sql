CREATE TABLE scheduling.branches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  address TEXT NOT NULL,
  city TEXT NOT NULL,
  phone TEXT,
  latitude NUMERIC(9, 6),
  longitude NUMERIC(9, 6),
  opens_at TIME NOT NULL DEFAULT '08:00',
  closes_at TIME NOT NULL DEFAULT '21:00',
  photos JSONB NOT NULL DEFAULT '[]',
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE scheduling.staff_branches (
  staff_id UUID NOT NULL REFERENCES identity.staff(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES scheduling.branches(id) ON DELETE CASCADE,
  PRIMARY KEY (staff_id, branch_id)
);

CREATE TABLE scheduling.doctor_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id UUID NOT NULL REFERENCES identity.staff(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES scheduling.branches(id) ON DELETE CASCADE,
  day_of_week SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  slot_duration_minutes SMALLINT NOT NULL DEFAULT 30,
  is_active BOOLEAN NOT NULL DEFAULT true
);

CREATE TYPE scheduling.reservation_status AS ENUM (
  'pending', 'confirmed', 'checked_in', 'in_progress', 'completed', 'cancelled', 'no_show'
);

CREATE TABLE scheduling.reservations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES identity.patients(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES scheduling.branches(id),
  staff_id UUID NOT NULL REFERENCES identity.staff(id),
  scheduled_at TIMESTAMPTZ NOT NULL,
  status scheduling.reservation_status NOT NULL DEFAULT 'pending',
  complaint_note TEXT,
  created_by UUID NOT NULL REFERENCES identity.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_reservations_branch_scheduled ON scheduling.reservations(branch_id, scheduled_at);
CREATE INDEX idx_reservations_patient ON scheduling.reservations(patient_id);

-- treatment_id references billing.treatments, added via ALTER in the billing
-- migration since billing.treatments does not exist yet at this point.
CREATE TABLE scheduling.reservation_treatments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reservation_id UUID NOT NULL REFERENCES scheduling.reservations(id) ON DELETE CASCADE,
  treatment_id UUID NOT NULL,
  price_at_booking NUMERIC(12, 2) NOT NULL
);

CREATE TABLE scheduling.queue_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reservation_id UUID NOT NULL REFERENCES scheduling.reservations(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES scheduling.branches(id),
  ticket_number INT NOT NULL,
  status TEXT NOT NULL DEFAULT 'waiting' CHECK (status IN ('waiting', 'called', 'in_service', 'done', 'skipped')),
  called_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_queue_tickets_branch_status ON scheduling.queue_tickets(branch_id, status);
