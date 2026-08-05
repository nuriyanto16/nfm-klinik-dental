-- Dummy/demo data for Nina Dental Care so the admin panel has something
-- real to render (branches, doctors, patients, treatments, reservations,
-- and payment transactions in a mix of statuses). Not a schema migration —
-- run it with `make seed` after `make migrate-up`. Safe to re-run: it wipes
-- and re-inserts its own rows first (see bottom section), it never touches
-- unrelated data.

BEGIN;

-- Clean slate for seeded rows (children first, respecting FKs).
DELETE FROM billing.expenses;
DELETE FROM billing.loyalty_points;
DELETE FROM identity.staff_skills;
DELETE FROM clinical.medical_record_items;
DELETE FROM clinical.odontogram_entries;
DELETE FROM clinical.medical_records;
DELETE FROM billing.inventory_items;
DELETE FROM content.testimonials;
DELETE FROM content.promos;
DELETE FROM content.articles;
DELETE FROM content.article_categories;
DELETE FROM content.videos;
DELETE FROM scheduling.queue_tickets;
DELETE FROM billing.payment_events;
DELETE FROM billing.payments;
DELETE FROM scheduling.reservation_treatments;
DELETE FROM scheduling.reservations;
DELETE FROM scheduling.doctor_schedules;
DELETE FROM scheduling.staff_branches;
DELETE FROM scheduling.branches;
DELETE FROM billing.treatments;
DELETE FROM billing.treatment_categories;
DELETE FROM identity.patients;
DELETE FROM identity.staff;
DELETE FROM identity.users;

-- === Branches (Soreang & Baleendah, per @ninadental.ndc) ===
INSERT INTO scheduling.branches (id, name, slug, address, city, phone, opens_at, closes_at, is_active) VALUES
  ('10000000-0000-0000-0000-000000000001', 'Nina Dental Care - Soreang', 'soreang', 'Jl. Raya Soreang No. 12, Kab. Bandung', 'Kab. Bandung', '+62811234501', '08:00', '21:00', true),
  ('10000000-0000-0000-0000-000000000002', 'Nina Dental Care - Baleendah', 'baleendah', 'Jl. Raya Baleendah No. 45, Kab. Bandung', 'Kab. Bandung', '+62811234502', '08:00', '21:00', true);

-- === Office panel login (superadmin) ===
-- Password: NinaDental#2026 — the only seeded user with a real bcrypt hash
-- (others use the placeholder 'seed-no-auth-yet' and can't log in), since
-- this is the account used to demo/test the admin panel login screen.
INSERT INTO identity.users (id, email, phone_wa, password_hash, full_name, gender, city, role) VALUES
  ('1f000000-0000-0000-0000-000000000001', 'admin@ninadentalcare.com', '+62811300000', '$2a$10$wqr289W6tEnIZgURHSsenuJuPJs8NXduCGsbN7JzbfmkE4z2vaCim', 'Admin Nina Dental Care', 'female', 'Kab. Bandung', 'superadmin');

-- === Doctor users + staff ===
INSERT INTO identity.users (id, email, phone_wa, password_hash, full_name, gender, date_of_birth, city, role) VALUES
  ('20000000-0000-0000-0000-000000000001', 'drg.nina@ninadentalcare.com', '+62811300001', 'seed-no-auth-yet', 'drg. Nina Marlina, Sp.KG', 'female', '1985-03-12', 'Kab. Bandung', 'dokter'),
  ('20000000-0000-0000-0000-000000000002', 'drg.fajar@ninadentalcare.com', '+62811300002', 'seed-no-auth-yet', 'drg. Fajar Ramadhan', 'male', '1990-07-22', 'Kab. Bandung', 'dokter'),
  ('20000000-0000-0000-0000-000000000003', 'drg.siti@ninadentalcare.com', '+62811300003', 'seed-no-auth-yet', 'drg. Siti Rahmawati', 'female', '1992-11-05', 'Kab. Bandung', 'dokter'),
  ('20000000-0000-0000-0000-000000000004', 'drg.yoga@ninadentalcare.com', '+62811300004', 'seed-no-auth-yet', 'drg. Yoga Pratama', 'male', '1993-01-18', 'Kab. Bandung', 'dokter');

INSERT INTO identity.staff (id, user_id, specialization, bio, photo_url, commission_rate, is_doctor) VALUES
  ('21000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'Konservasi Gigi (Sp.KG)', 'Spesialis konservasi gigi dengan 12 tahun pengalaman menangani tambal & saluran akar.', 'https://i.pravatar.cc/300?img=47', 12.5, true),
  ('21000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', 'Dokter Gigi Umum', 'Dokter gigi umum, fokus pada scaling, tambal, dan cabut gigi dewasa.', 'https://i.pravatar.cc/300?img=12', 10, true),
  ('21000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000003', 'Ortodonti (Behel)', 'Menangani pemasangan & perawatan behel metal maupun clear aligner.', 'https://i.pravatar.cc/300?img=45', 15, true),
  ('21000000-0000-0000-0000-000000000004', '20000000-0000-0000-0000-000000000004', 'Dokter Gigi Anak (Nina Kidz)', 'Spesialis perawatan gigi anak, pengalaman menangani pasien program Nina Kidz.', 'https://i.pravatar.cc/300?img=33', 10, true);

INSERT INTO identity.staff_skills (staff_id, skill_name, proficiency, years_experience) VALUES
  ('21000000-0000-0000-0000-000000000001', 'Perawatan Saluran Akar', 5, 12),
  ('21000000-0000-0000-0000-000000000001', 'Tambal Estetik', 4, 12),
  ('21000000-0000-0000-0000-000000000001', 'Bedah Mulut', 3, 8),
  ('21000000-0000-0000-0000-000000000002', 'Scaling & Whitening', 5, 6),
  ('21000000-0000-0000-0000-000000000002', 'Tambal Gigi', 4, 6),
  ('21000000-0000-0000-0000-000000000002', 'Cabut Gigi', 4, 6),
  ('21000000-0000-0000-0000-000000000003', 'Behel Metal', 5, 9),
  ('21000000-0000-0000-0000-000000000003', 'Clear Aligner', 4, 5),
  ('21000000-0000-0000-0000-000000000003', 'Evaluasi Ortodonti', 5, 9),
  ('21000000-0000-0000-0000-000000000004', 'Perawatan Gigi Anak', 5, 7),
  ('21000000-0000-0000-0000-000000000004', 'Sedasi Ringan', 3, 4),
  ('21000000-0000-0000-0000-000000000004', 'Edukasi Orang Tua', 4, 7);

INSERT INTO scheduling.staff_branches (staff_id, branch_id) VALUES
  ('21000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001'),
  ('21000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001'),
  ('21000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002'),
  ('21000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001'),
  ('21000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000002');

INSERT INTO scheduling.doctor_schedules (staff_id, branch_id, day_of_week, start_time, end_time, slot_duration_minutes) VALUES
  ('21000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 1, '09:00', '17:00', 30),
  ('21000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 3, '09:00', '17:00', 30),
  ('21000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', 1, '08:00', '20:00', 30),
  ('21000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', 2, '08:00', '20:00', 30),
  ('21000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', 2, '10:00', '18:00', 30),
  ('21000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000002', 4, '09:00', '15:00', 20);

-- === Patients (mix of self accounts + one linked "child" family member) ===
INSERT INTO identity.users (id, email, phone_wa, password_hash, full_name, gender, date_of_birth, city, role) VALUES
  ('30000000-0000-0000-0000-000000000001', 'budi.santoso@example.com', '+62812340001', 'seed-no-auth-yet', 'Budi Santoso', 'male', '1988-05-14', 'Soreang', 'patient'),
  ('30000000-0000-0000-0000-000000000002', 'siti.aminah@example.com', '+62812340002', 'seed-no-auth-yet', 'Siti Aminah', 'female', '1991-09-02', 'Soreang', 'patient'),
  ('30000000-0000-0000-0000-000000000003', 'ahmad.fauzi@example.com', '+62812340003', 'seed-no-auth-yet', 'Ahmad Fauzi', 'male', '1995-02-27', 'Baleendah', 'patient'),
  ('30000000-0000-0000-0000-000000000004', 'dewi.lestari@example.com', '+62812340004', 'seed-no-auth-yet', 'Dewi Lestari', 'female', '1998-12-09', 'Baleendah', 'patient'),
  ('30000000-0000-0000-0000-000000000005', 'rina.marlina@example.com', '+62812340005', 'seed-no-auth-yet', 'Rina Marlina', 'female', '1993-06-30', 'Soreang', 'patient');

INSERT INTO identity.patients (id, primary_account_user_id, user_id, rm_number, full_name, relation, gender, date_of_birth, address, photo_url) VALUES
  ('31000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'RM-0001', 'Budi Santoso', 'self', 'male', '1988-05-14', 'Jl. Melati No. 3, Soreang', 'https://i.pravatar.cc/300?img=51'),
  ('31000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000002', 'RM-0002', 'Siti Aminah', 'self', 'female', '1991-09-02', 'Jl. Kenanga No. 8, Soreang', 'https://i.pravatar.cc/300?img=32'),
  ('31000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000002', NULL, 'RM-0003', 'Kayla Aminah', 'child', 'female', '2019-04-11', 'Jl. Kenanga No. 8, Soreang', NULL),
  ('31000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000003', 'RM-0004', 'Ahmad Fauzi', 'self', 'male', '1995-02-27', 'Jl. Anggrek No. 15, Baleendah', 'https://i.pravatar.cc/300?img=13'),
  ('31000000-0000-0000-0000-000000000005', '30000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000004', 'RM-0005', 'Dewi Lestari', 'self', 'female', '1998-12-09', 'Jl. Mawar No. 21, Baleendah', 'https://i.pravatar.cc/300?img=25'),
  ('31000000-0000-0000-0000-000000000006', '30000000-0000-0000-0000-000000000005', '30000000-0000-0000-0000-000000000005', NULL, 'Rina Marlina', 'self', 'female', '1993-06-30', 'Jl. Dahlia No. 5, Soreang', 'https://i.pravatar.cc/300?img=44');

-- === Treatment categories & treatments ===
INSERT INTO billing.treatment_categories (id, name, sort_order) VALUES
  ('40000000-0000-0000-0000-000000000001', 'Umum', 1),
  ('40000000-0000-0000-0000-000000000002', 'Behel & Ortodonti', 2),
  ('40000000-0000-0000-0000-000000000003', 'Nina Kidz (Gigi Anak)', 3),
  ('40000000-0000-0000-0000-000000000004', 'Gigi Palsu', 4);

INSERT INTO billing.treatments (id, category_id, name, description, price, duration_minutes, is_active) VALUES
  ('41000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', 'Scaling Gigi (Pembersihan Karang Gigi)', 'Pembersihan karang gigi menyeluruh', 350000, 30, true),
  ('41000000-0000-0000-0000-000000000002', '40000000-0000-0000-0000-000000000001', 'Tambal Gigi (Komposit)', 'Tambal gigi berlubang dengan resin komposit', 250000, 30, true),
  ('41000000-0000-0000-0000-000000000003', '40000000-0000-0000-0000-000000000001', 'Cabut Gigi Dewasa', 'Pencabutan gigi dewasa non-bedah', 300000, 30, true),
  ('41000000-0000-0000-0000-000000000004', '40000000-0000-0000-0000-000000000001', 'Bleaching (Pemutihan Gigi)', 'Pemutihan gigi profesional in-office', 1500000, 60, true),
  ('41000000-0000-0000-0000-000000000005', '40000000-0000-0000-0000-000000000002', 'Behel Metal Konvensional', 'Pemasangan behel metal rahang atas & bawah', 6500000, 60, true),
  ('41000000-0000-0000-0000-000000000006', '40000000-0000-0000-0000-000000000002', 'Behel Self-Ligating', 'Behel tanpa karet, kontrol lebih jarang', 9500000, 60, true),
  ('41000000-0000-0000-0000-000000000007', '40000000-0000-0000-0000-000000000002', 'Behel Keramik (Sapphire)', 'Behel estetik warna transparan', 12500000, 60, true),
  ('41000000-0000-0000-0000-000000000008', '40000000-0000-0000-0000-000000000002', 'Kontrol Behel Bulanan', 'Kontrol rutin bulanan pasien behel', 150000, 20, true),
  ('41000000-0000-0000-0000-000000000009', '40000000-0000-0000-0000-000000000003', 'Pemeriksaan Gigi Anak (Nina Kidz)', 'General checkup gigi untuk anak', 100000, 20, true),
  ('41000000-0000-0000-0000-000000000010', '40000000-0000-0000-0000-000000000003', 'Vitamin Gigi Anak', 'Aplikasi vitamin penguat gigi anak', 75000, 15, true),
  ('41000000-0000-0000-0000-000000000011', '40000000-0000-0000-0000-000000000003', 'Fluoride Treatment Anak', 'Perlindungan enamel gigi anak', 200000, 20, true),
  ('41000000-0000-0000-0000-000000000012', '40000000-0000-0000-0000-000000000004', 'Gigi Palsu Akrilik (per gigi)', 'Gigi palsu lepasan berbahan akrilik', 350000, 45, true),
  ('41000000-0000-0000-0000-000000000013', '40000000-0000-0000-0000-000000000004', 'Gigi Palsu Valplast (per rahang)', 'Gigi palsu fleksibel tanpa kawat', 3500000, 60, true);

-- === Reservations (past/completed, today/in-progress, future/pending) ===
INSERT INTO scheduling.reservations (id, patient_id, branch_id, staff_id, scheduled_at, status, complaint_note, created_by) VALUES
  ('50000000-0000-0000-0000-000000000001', '31000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '21000000-0000-0000-0000-000000000002', date_trunc('day', now()) - interval '3 days' + time '10:00', 'completed', 'Sakit gigi geraham bawah', '30000000-0000-0000-0000-000000000001'),
  ('50000000-0000-0000-0000-000000000002', '31000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '21000000-0000-0000-0000-000000000003', date_trunc('day', now()) - interval '2 days' + time '14:00', 'completed', 'Kontrol behel bulanan', '30000000-0000-0000-0000-000000000002'),
  ('50000000-0000-0000-0000-000000000003', '31000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000002', '21000000-0000-0000-0000-000000000004', date_trunc('day', now()) - interval '1 days' + time '09:00', 'no_show', 'Checkup rutin Nina Kidz', '30000000-0000-0000-0000-000000000002'),
  ('50000000-0000-0000-0000-000000000004', '31000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001', '21000000-0000-0000-0000-000000000001', date_trunc('day', now()) - interval '1 days' + time '16:00', 'cancelled', 'Konsultasi tambal gigi', '30000000-0000-0000-0000-000000000003'),
  ('50000000-0000-0000-0000-000000000005', '31000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000002', '21000000-0000-0000-0000-000000000002', date_trunc('day', now()) + time '09:00', 'completed', 'Scaling rutin', '30000000-0000-0000-0000-000000000004'),
  ('50000000-0000-0000-0000-000000000006', '31000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000001', '21000000-0000-0000-0000-000000000003', date_trunc('day', now()) + time '11:00', 'checked_in', 'Konsultasi behel', '30000000-0000-0000-0000-000000000005'),
  ('50000000-0000-0000-0000-000000000007', '31000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '21000000-0000-0000-0000-000000000001', date_trunc('day', now()) + time '15:00', 'in_progress', 'Bleaching', '30000000-0000-0000-0000-000000000001'),
  ('50000000-0000-0000-0000-000000000008', '31000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', '21000000-0000-0000-0000-000000000004', date_trunc('day', now()) + time '17:00', 'confirmed', 'Checkup anak', '30000000-0000-0000-0000-000000000002'),
  ('50000000-0000-0000-0000-000000000009', '31000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001', '21000000-0000-0000-0000-000000000002', date_trunc('day', now()) + interval '1 days' + time '10:00', 'confirmed', 'Cabut gigi', '30000000-0000-0000-0000-000000000003'),
  ('50000000-0000-0000-0000-000000000010', '31000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000002', '21000000-0000-0000-0000-000000000003', date_trunc('day', now()) + interval '3 days' + time '13:00', 'pending', 'Konsultasi behel keramik', '30000000-0000-0000-0000-000000000004');

INSERT INTO scheduling.reservation_treatments (reservation_id, treatment_id, price_at_booking) VALUES
  ('50000000-0000-0000-0000-000000000001', '41000000-0000-0000-0000-000000000002', 250000),
  ('50000000-0000-0000-0000-000000000002', '41000000-0000-0000-0000-000000000008', 150000),
  ('50000000-0000-0000-0000-000000000003', '41000000-0000-0000-0000-000000000009', 100000),
  ('50000000-0000-0000-0000-000000000004', '41000000-0000-0000-0000-000000000002', 250000),
  ('50000000-0000-0000-0000-000000000005', '41000000-0000-0000-0000-000000000001', 350000),
  ('50000000-0000-0000-0000-000000000006', '41000000-0000-0000-0000-000000000005', 6500000),
  ('50000000-0000-0000-0000-000000000007', '41000000-0000-0000-0000-000000000004', 1500000),
  ('50000000-0000-0000-0000-000000000008', '41000000-0000-0000-0000-000000000009', 100000),
  ('50000000-0000-0000-0000-000000000009', '41000000-0000-0000-0000-000000000003', 300000),
  ('50000000-0000-0000-0000-000000000010', '41000000-0000-0000-0000-000000000007', 12500000);

-- === Payments (dummy transactions covering every status) ===
INSERT INTO billing.payments (id, reservation_id, patient_id, amount, deposit_amount, status, provider, provider_reference, payment_method, expired_at, paid_at, created_at) VALUES
  ('60000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', '31000000-0000-0000-0000-000000000001', 250000, 100000, 'paid', 'xendit', 'xnd-inv-1001', 'bank_transfer_bca', NULL, date_trunc('day', now()) - interval '3 days' + time '08:00', date_trunc('day', now()) - interval '3 days' + time '08:00'),
  ('60000000-0000-0000-0000-000000000002', '50000000-0000-0000-0000-000000000002', '31000000-0000-0000-0000-000000000002', 150000, 100000, 'paid', 'xendit', 'xnd-inv-1002', 'ewallet_ovo', NULL, date_trunc('day', now()) - interval '2 days' + time '13:00', date_trunc('day', now()) - interval '2 days' + time '13:00'),
  ('60000000-0000-0000-0000-000000000003', '50000000-0000-0000-0000-000000000003', '31000000-0000-0000-0000-000000000003', 100000, 100000, 'paid', 'xendit', 'xnd-inv-1003', 'qris', NULL, date_trunc('day', now()) - interval '1 days' + time '08:00', date_trunc('day', now()) - interval '1 days' + time '08:00'),
  ('60000000-0000-0000-0000-000000000004', '50000000-0000-0000-0000-000000000004', '31000000-0000-0000-0000-000000000004', 100000, 100000, 'refunded', 'xendit', 'xnd-inv-1004', 'bank_transfer_mandiri', NULL, date_trunc('day', now()) - interval '1 days' + time '15:00', date_trunc('day', now()) - interval '1 days' + time '15:00'),
  ('60000000-0000-0000-0000-000000000005', '50000000-0000-0000-0000-000000000005', '31000000-0000-0000-0000-000000000005', 350000, 100000, 'paid', 'xendit', 'xnd-inv-1005', 'ewallet_dana', NULL, date_trunc('day', now()) + time '08:30', date_trunc('day', now()) + time '08:30'),
  ('60000000-0000-0000-0000-000000000006', '50000000-0000-0000-0000-000000000006', '31000000-0000-0000-0000-000000000006', 100000, 100000, 'paid', 'xendit', 'xnd-inv-1006', 'qris', NULL, date_trunc('day', now()) + time '10:30', date_trunc('day', now()) + time '10:30'),
  ('60000000-0000-0000-0000-000000000007', '50000000-0000-0000-0000-000000000007', '31000000-0000-0000-0000-000000000001', 100000, 100000, 'paid', 'xendit', 'xnd-inv-1007', 'bank_transfer_bni', NULL, date_trunc('day', now()) + time '14:30', date_trunc('day', now()) + time '14:30'),
  ('60000000-0000-0000-0000-000000000008', '50000000-0000-0000-0000-000000000008', '31000000-0000-0000-0000-000000000002', 100000, 100000, 'failed', 'xendit', 'xnd-inv-1008', 'ewallet_shopeepay', now() + interval '15 minutes', NULL, now() - interval '10 minutes'),
  ('60000000-0000-0000-0000-000000000009', '50000000-0000-0000-0000-000000000009', '31000000-0000-0000-0000-000000000004', 100000, 100000, 'pending', 'xendit', 'xnd-inv-1009', NULL, now() + interval '15 minutes', NULL, now()),
  ('60000000-0000-0000-0000-000000000010', '50000000-0000-0000-0000-000000000010', '31000000-0000-0000-0000-000000000005', 100000, 100000, 'expired', 'xendit', 'xnd-inv-1010', NULL, now() - interval '1 days', NULL, now() - interval '1 days' - interval '15 minutes');

-- === Queue tickets (today's checked-in / in-progress patients) ===
INSERT INTO scheduling.queue_tickets (reservation_id, branch_id, ticket_number, status, called_at) VALUES
  ('50000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000001', 4, 'in_service', date_trunc('day', now()) + time '15:05'),
  ('50000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000001', 5, 'waiting', NULL);

-- === Riwayat transaksi tambahan (30 hari terakhir) — supaya dashboard,
-- laporan keuangan, dan tren revenue punya data yang cukup padat untuk
-- ditampilkan, bukan cuma beberapa baris. Deterministik (bukan random()),
-- supaya seed tetap idempoten & hasilnya sama tiap kali dijalankan.
DO $$
DECLARE
  patient_ids uuid[] := ARRAY[
    '31000000-0000-0000-0000-000000000001', '31000000-0000-0000-0000-000000000002',
    '31000000-0000-0000-0000-000000000004', '31000000-0000-0000-0000-000000000005',
    '31000000-0000-0000-0000-000000000006'
  ];
  -- branch_ids[i]/staff_ids[i] pairs (parallel arrays, not a true 2D array —
  -- Postgres single-subscript indexing on a genuine 2D array returns NULL,
  -- not "row i", so this avoids that gotcha) that are valid per staff_branches above.
  branch_ids uuid[] := ARRAY[
    '10000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002'
  ];
  staff_ids uuid[] := ARRAY[
    '21000000-0000-0000-0000-000000000001', '21000000-0000-0000-0000-000000000002',
    '21000000-0000-0000-0000-000000000003', '21000000-0000-0000-0000-000000000002',
    '21000000-0000-0000-0000-000000000004'
  ];
  treatment_ids uuid[] := ARRAY[
    '41000000-0000-0000-0000-000000000001', '41000000-0000-0000-0000-000000000002',
    '41000000-0000-0000-0000-000000000003', '41000000-0000-0000-0000-000000000004',
    '41000000-0000-0000-0000-000000000005', '41000000-0000-0000-0000-000000000008',
    '41000000-0000-0000-0000-000000000009', '41000000-0000-0000-0000-000000000010',
    '41000000-0000-0000-0000-000000000012'
  ];
  methods text[] := ARRAY['bank_transfer_bca', 'ewallet_dana', 'qris', 'cash', 'ewallet_ovo', 'bank_transfer_bni', 'manual_transfer'];
  i int;
  pair_idx int;
  day_offset int;
  branch_id uuid;
  staff_id uuid;
  patient_id uuid;
  treatment_id uuid;
  treatment_price numeric;
  reservation_id uuid;
  payment_status text;
  method text;
  ts timestamptz;
BEGIN
  FOR i IN 1..40 LOOP
    day_offset := (i * 7 + 3) % 30;
    pair_idx := 1 + (i % array_length(branch_ids, 1));
    branch_id := branch_ids[pair_idx];
    staff_id := staff_ids[pair_idx];
    patient_id := patient_ids[1 + (i % array_length(patient_ids, 1))];
    treatment_id := treatment_ids[1 + (i % array_length(treatment_ids, 1))];
    method := methods[1 + (i % array_length(methods, 1))];
    ts := date_trunc('day', now()) - (day_offset || ' days')::interval + ((8 + (i % 10)) || ' hours')::interval;

    SELECT price INTO treatment_price FROM billing.treatments WHERE id = treatment_id;

    INSERT INTO scheduling.reservations (id, patient_id, branch_id, staff_id, scheduled_at, status, created_by)
    VALUES (
      gen_random_uuid(), patient_id, branch_id, staff_id, ts, 'completed',
      (SELECT primary_account_user_id FROM identity.patients WHERE id = patient_id)
    )
    RETURNING id INTO reservation_id;

    INSERT INTO scheduling.reservation_treatments (reservation_id, treatment_id, price_at_booking)
    VALUES (reservation_id, treatment_id, treatment_price);

    payment_status := CASE WHEN i % 11 = 0 THEN 'refunded' WHEN i % 13 = 0 THEN 'pending' ELSE 'paid' END;

    INSERT INTO billing.payments (reservation_id, patient_id, amount, deposit_amount, status, provider, payment_method, paid_at, created_at)
    VALUES (
      reservation_id, patient_id, treatment_price, LEAST(treatment_price, 100000), payment_status::billing.payment_status, 'manual', method,
      CASE WHEN payment_status = 'paid' THEN ts + interval '30 minutes' ELSE NULL END,
      ts + interval '30 minutes'
    );
  END LOOP;
END $$;

-- === Inventory (alat & obat) ===
INSERT INTO billing.inventory_items (id, name, category, unit, stock_quantity, unit_price, reorder_threshold, is_active) VALUES
  ('90000000-0000-0000-0000-000000000001', 'Lidocaine Injeksi 2%', 'obat', 'ampul', 200, 8000, 30, true),
  ('90000000-0000-0000-0000-000000000002', 'Povidone Iodine 10%', 'obat', 'botol', 50, 25000, 10, true),
  ('90000000-0000-0000-0000-000000000003', 'Eugenol', 'obat', 'botol', 30, 45000, 5, true),
  ('90000000-0000-0000-0000-000000000004', 'Kalsium Hidroksida', 'obat', 'tube', 20, 60000, 5, true),
  ('90000000-0000-0000-0000-000000000005', 'Sarung Tangan Medis', 'alat', 'pasang', 500, 2000, 100, true),
  ('90000000-0000-0000-0000-000000000006', 'Masker Medis', 'alat', 'pcs', 1000, 1500, 200, true),
  ('90000000-0000-0000-0000-000000000007', 'Jarum Suntik Sekali Pakai', 'alat', 'pcs', 300, 3000, 50, true),
  ('90000000-0000-0000-0000-000000000008', 'Cotton Roll', 'alat', 'pack', 100, 15000, 20, true);

-- === Rekam medis (untuk reservasi yang sudah completed) ===
INSERT INTO clinical.medical_records (id, patient_id, reservation_id, staff_id, diagnosis, treatment_notes, created_at) VALUES
  ('a0000000-0000-0000-0000-000000000001', '31000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', '21000000-0000-0000-0000-000000000002', 'Karies dentin pada gigi 36', 'Dilakukan penambalan komposit pada gigi 36. Pasien tidak ada keluhan pasca tindakan.', date_trunc('day', now()) - interval '3 days' + time '10:30'),
  ('a0000000-0000-0000-0000-000000000002', '31000000-0000-0000-0000-000000000002', '50000000-0000-0000-0000-000000000002', '21000000-0000-0000-0000-000000000003', 'Kontrol rutin behel bulan ke-3', 'Penggantian karet behel, evaluasi pergerakan gigi sesuai rencana perawatan — progres baik, gigi mulai rapi.', date_trunc('day', now()) - interval '2 days' + time '14:20'),
  ('a0000000-0000-0000-0000-000000000003', '31000000-0000-0000-0000-000000000005', '50000000-0000-0000-0000-000000000005', '21000000-0000-0000-0000-000000000002', 'Akumulasi plak & kalkulus ringan', 'Scaling ultrasonik seluruh regio, edukasi oral hygiene.', date_trunc('day', now()) + time '09:30'),
  ('a0000000-0000-0000-0000-000000000004', '31000000-0000-0000-0000-000000000002', NULL, '21000000-0000-0000-0000-000000000003', 'Gigi berjejal, indikasi behel metal', 'Pemasangan behel metal awal, rencana kontrol tiap bulan.', date_trunc('day', now()) - interval '90 days' + time '11:00');

INSERT INTO clinical.odontogram_entries (medical_record_id, tooth_number, condition, notes, photo_url) VALUES
  ('a0000000-0000-0000-0000-000000000001', 36, 'filled', 'Tambal komposit', NULL),
  ('a0000000-0000-0000-0000-000000000004', 11, 'braces_initial', 'Kondisi awal sebelum behel — gigi berjejal', 'https://placehold.co/400x300/1e3a8a/white?text=Sebelum+Behel'),
  ('a0000000-0000-0000-0000-000000000002', 11, 'braces_progress', 'Progres bulan ke-3 — mulai rapi', 'https://placehold.co/400x300/16a34a/white?text=Progres+Bulan+ke-3');

INSERT INTO clinical.medical_record_items (medical_record_id, inventory_item_id, quantity, notes) VALUES
  ('a0000000-0000-0000-0000-000000000001', '90000000-0000-0000-0000-000000000001', 1, NULL),
  ('a0000000-0000-0000-0000-000000000001', '90000000-0000-0000-0000-000000000005', 2, NULL),
  ('a0000000-0000-0000-0000-000000000001', '90000000-0000-0000-0000-000000000006', 1, NULL),
  ('a0000000-0000-0000-0000-000000000002', '90000000-0000-0000-0000-000000000005', 2, NULL),
  ('a0000000-0000-0000-0000-000000000002', '90000000-0000-0000-0000-000000000006', 1, NULL),
  ('a0000000-0000-0000-0000-000000000003', '90000000-0000-0000-0000-000000000002', 1, NULL),
  ('a0000000-0000-0000-0000-000000000003', '90000000-0000-0000-0000-000000000005', 2, NULL),
  ('a0000000-0000-0000-0000-000000000003', '90000000-0000-0000-0000-000000000006', 1, NULL);

UPDATE billing.inventory_items SET stock_quantity = stock_quantity - 1 WHERE id = '90000000-0000-0000-0000-000000000001';
UPDATE billing.inventory_items SET stock_quantity = stock_quantity - 6 WHERE id = '90000000-0000-0000-0000-000000000005';
UPDATE billing.inventory_items SET stock_quantity = stock_quantity - 3 WHERE id = '90000000-0000-0000-0000-000000000006';
UPDATE billing.inventory_items SET stock_quantity = stock_quantity - 1 WHERE id = '90000000-0000-0000-0000-000000000002';

-- === CMS: kategori artikel, artikel, promo, testimoni, video ===
INSERT INTO content.article_categories (id, name) VALUES
  ('b0000000-0000-0000-0000-000000000001', 'Perawatan Gigi'),
  ('b0000000-0000-0000-0000-000000000002', 'Tips Kesehatan'),
  ('b0000000-0000-0000-0000-000000000003', 'Ortodonti'),
  ('b0000000-0000-0000-0000-000000000004', 'Nina Kidz');

INSERT INTO content.articles (category_id, title, slug, cover_image_url, body, published_at) VALUES
  ('b0000000-0000-0000-0000-000000000003', 'Kapan Harus Behel Gigi? Kenali 5 Tanda Utama Ini!', 'kapan-harus-behel', 'https://images.unsplash.com/photo-1598256989800-fe5f95da9787?w=800&auto=format&fit=crop&q=80', 'Gigi berjejal, gigitan tidak rata, atau rahang tidak simetris bisa jadi tanda kamu butuh behel. Konsultasikan dengan dokter gigi spesialis ortodonti di Nina Dental Care untuk rencana perawatan yang tepat.', now() - interval '2 days'),
  ('b0000000-0000-0000-0000-000000000002', '5 Kebiasaan Sehari-hari yang Tanpa Disadari Merusak Enamel Gigi', '5-kebiasaan-perusak-enamel', 'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=800&auto=format&fit=crop&q=80', 'Minum soda berlebihan, menggigit kuku, dan sikat gigi terlalu keras adalah beberapa kebiasaan yang perlahan merusak enamel gigi tanpa disadari.', now() - interval '5 days'),
  ('b0000000-0000-0000-0000-000000000004', 'Program Nina Kidz: Menjaga Gigi Anak Sehat & Bebas Karies Sejak Dini', 'program-nina-kidz', 'https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?w=800&auto=format&fit=crop&q=80', 'Nina Kidz adalah program pemeriksaan gigi anak dengan pendekatan ramah anak, termasuk vitamin gigi dan fluoride treatment untuk mencegah karies sejak dini.', now() - interval '7 days'),
  ('b0000000-0000-0000-0000-000000000001', 'Prosedur Bleaching Gigi Instant: Rahasia Senyum Cerah Cemerlang', 'prosedur-bleaching-gigi', 'https://images.unsplash.com/photo-1571772996211-2f02c9727629?w=800&auto=format&fit=crop&q=80', 'Bleaching (In-Office Whitening) adalah solusi tercepat untuk mencerahkan warna gigi hingga 4-8 tingkat lebih putih hanya dalam waktu 60 menit di klinik Nina Dental Care.', now() - interval '10 days'),
  ('b0000000-0000-0000-0000-000000000002', 'Cara Memilih Sikat Gigi yang Tepat untuk Berbagai Usia', 'cara-memilih-sikat-gigi', 'https://images.unsplash.com/photo-1559590656-b3f4d32c5869?w=800&auto=format&fit=crop&q=80', 'Memilih sikat gigi yang tepat sangat penting untuk menjaga kesehatan gigi dan gusi. Panduan lengkap untuk semua usia dari anak-anak hingga dewasa.', now() - interval '12 days'),
  ('b0000000-0000-0000-0000-000000000001', 'Veneer Gigi: Solusi Senyum Sempurna untuk Gigi Bernoda & Tidak Rata', 'veneer-gigi-solusi-senyum', 'https://images.unsplash.com/photo-1629909615184-74f495363b67?w=800&auto=format&fit=crop&q=80', 'Veneer porselen adalah lapisan tipis yang ditempel pada permukaan gigi untuk memperbaiki penampilan gigi bernoda, retak, atau tidak rata secara estetis.', now() - interval '15 days'),
  ('b0000000-0000-0000-0000-000000000003', 'Behel Transparan vs Metal: Mana yang Lebih Cocok untuk Anda?', 'behel-transparan-vs-metal', 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800&auto=format&fit=crop&q=80', 'Perbandingan lengkap antara behel metal konvensional dan clear aligner transparan dari segi efektivitas, kenyamanan, dan biaya.', now() - interval '18 days');

INSERT INTO content.promos (title, banner_image_url, description, starts_at, ends_at, is_active, discount_type, discount_value) VALUES
  ('Promo Scaling 6-in-1 Super Clean', 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=800&auto=format&fit=crop&q=80', 'Paket scaling lengkap pembersihan karang gigi + polishing + fluoridasi hanya Rp149.000, berlaku di cabang Soreang & Baleendah.', now() - interval '5 days', now() + interval '25 days', true, 'fixed', 50000),
  ('Diskon Pemasangan Behel Metal 10%', 'https://images.unsplash.com/photo-1598256989800-fe5f95da9787?w=800&auto=format&fit=crop&q=80', 'Diskon 10% untuk pemasangan behel metal konvensional, khusus reservasi online lewat aplikasi mobile.', now() - interval '2 days', now() + interval '13 days', true, 'percentage', 10),
  ('Bleaching Premium 50% OFF', 'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=800&auto=format&fit=crop&q=80', 'Gigi putih cemerlang dalam 60 menit! Diskon 50% untuk paket bleaching in-office di bulan Agustus ini.', now() - interval '1 day', now() + interval '20 days', true, 'percentage', 50),
  ('Voucher New Patient Senyum Sehat', 'https://images.unsplash.com/photo-1571772996211-2f02c9727629?w=800&auto=format&fit=crop&q=80', 'Potongan Rp 30.000 khusus pasien baru pertama kali berkunjung ke Nina Dental Care. Berlaku untuk semua perawatan.', now() - interval '10 days', now() + interval '30 days', true, 'fixed', 30000),
  ('Pemasangan Veneer Porselen Diskon 15%', 'https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?w=800&auto=format&fit=crop&q=80', 'Miliki senyum sempurna dengan veneer porselen berkualitas tinggi, diskon 15% untuk reservasi online.', now() - interval '3 days', now() + interval '17 days', true, 'percentage', 15);

INSERT INTO content.testimonials (patient_name, staff_id, photo_url, rating, quote) VALUES
  ('Budi Santoso', '21000000-0000-0000-0000-000000000002', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&auto=format&fit=crop&q=80', 5, 'Pelayanan ramah, klinik sangat bersih dan dokter komunikatif! Tambal giginya rapi dan gak sakit sama sekali.'),
  ('Siti Aminah', '21000000-0000-0000-0000-000000000003', 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=300&auto=format&fit=crop&q=80', 5, 'Behel anak saya ditangani dengan sabar, dokter anak di Nina Kidz sangat ramah sehingga anak tidak takut dokter gigi.'),
  ('Dewi Lestari', '21000000-0000-0000-0000-000000000002', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&auto=format&fit=crop&q=80', 5, 'Scaling-nya bersih banget, proses cepat dan reservasi lewat aplikasi sangat mempermudah tidak perlu antre lama.'),
  ('Ahmad Fauzi', '21000000-0000-0000-0000-000000000001', 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=300&auto=format&fit=crop&q=80', 5, 'Perawatan saluran akar di Nina Dental Care sangat profesional. Dokternya sabar menjelaskan prosedur dengan detail.'),
  ('Rina Marlina', '21000000-0000-0000-0000-000000000004', 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=300&auto=format&fit=crop&q=80', 5, 'Nina Kidz program yang luar biasa! Anak saya yang tadinya takut dokter gigi sekarang semangat kontrol rutin.'),
  ('Yoga Pratama', '21000000-0000-0000-0000-000000000003', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300&auto=format&fit=crop&q=80', 4, 'Behel metalnya terpasang rapi dan progres per bulannya terasa signifikan. Sangat puas dengan hasilnya!');

INSERT INTO content.videos (title, video_url, thumbnail_url, published_at) VALUES
  ('SERU ABISSS GRAND OPENING NINA DENTAL CARE!', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'https://images.unsplash.com/photo-1629909615184-74f495363b67?w=800&auto=format&fit=crop&q=80', now() - interval '20 days'),
  ('Edukasi: Cara Sikat Gigi yang Benar Mencegah Karang', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=800&auto=format&fit=crop&q=80', now() - interval '7 days');

-- === Pembiayaan operasional (laporan keuntungan/pembiayaan) ===
INSERT INTO billing.expenses (branch_id, category, description, amount, expense_date) VALUES
  ('10000000-0000-0000-0000-000000000001', 'Sewa', 'Sewa ruko bulan berjalan', 8000000, date_trunc('month', now())::date),
  ('10000000-0000-0000-0000-000000000002', 'Sewa', 'Sewa ruko bulan berjalan', 7000000, date_trunc('month', now())::date),
  ('10000000-0000-0000-0000-000000000001', 'Listrik & Air', 'Tagihan listrik & air bulan berjalan', 1500000, now()::date - 5),
  ('10000000-0000-0000-0000-000000000002', 'Listrik & Air', 'Tagihan listrik & air bulan berjalan', 1200000, now()::date - 5),
  (NULL, 'Restock Alat/Obat', 'Restock bahan tambal & obat anestesi', 4500000, now()::date - 10),
  ('10000000-0000-0000-0000-000000000001', 'Gaji Non-Komisi', 'Gaji staf front office & perawat', 12000000, date_trunc('month', now())::date),
  (NULL, 'Marketing', 'Promosi Instagram Ads bulan berjalan', 1000000, now()::date - 15);

-- === Poin loyalitas (rewards) — dihitung manual di sini karena payments di
-- atas diinsert langsung lewat SQL, bukan lewat billing.CreatePayment yang
-- biasanya mengakumulasi poin otomatis saat status jadi 'paid'. ===
INSERT INTO billing.loyalty_points (patient_id, points) VALUES
  ('31000000-0000-0000-0000-000000000001', 145),
  ('31000000-0000-0000-0000-000000000002', 320),
  ('31000000-0000-0000-0000-000000000004', 80),
  ('31000000-0000-0000-0000-000000000005', 210),
  ('31000000-0000-0000-0000-000000000006', 55);

COMMIT;
