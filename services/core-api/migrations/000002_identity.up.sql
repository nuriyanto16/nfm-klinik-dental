CREATE TYPE identity.user_role AS ENUM (
  'patient', 'dokter', 'perawat', 'admin_cabang', 'superadmin', 'finance'
);

CREATE TABLE identity.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE,
  phone_wa TEXT UNIQUE,
  password_hash TEXT NOT NULL,
  full_name TEXT NOT NULL,
  gender TEXT CHECK (gender IN ('male', 'female')),
  date_of_birth DATE,
  birth_place TEXT,
  city TEXT,
  role identity.user_role NOT NULL DEFAULT 'patient',
  referral_code TEXT UNIQUE,
  referred_by UUID REFERENCES identity.users(id),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE identity.patients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  primary_account_user_id UUID NOT NULL REFERENCES identity.users(id) ON DELETE CASCADE,
  user_id UUID REFERENCES identity.users(id) ON DELETE SET NULL,
  rm_number TEXT UNIQUE,
  full_name TEXT NOT NULL,
  relation TEXT NOT NULL DEFAULT 'self',
  gender TEXT CHECK (gender IN ('male', 'female')),
  date_of_birth DATE,
  address TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_patients_primary_account ON identity.patients(primary_account_user_id);

CREATE TABLE identity.staff (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES identity.users(id) ON DELETE CASCADE,
  specialization TEXT,
  bio TEXT,
  photo_url TEXT,
  is_doctor BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
