-- Nina Dental Care operates in WIB (Asia/Jakarta, UTC+7). All "today"/date
-- based logic (dashboard KPIs, doctor schedules, reservation dates) must be
-- computed in the clinic's local calendar day, not UTC — otherwise
-- CURRENT_DATE flips to the next day at 07:00 WIB instead of midnight WIB.
ALTER DATABASE nina_dental SET timezone TO 'Asia/Jakarta';
