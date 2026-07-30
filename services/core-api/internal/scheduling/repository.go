package scheduling

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/nina-dental-care/core-api/internal/platform/pagination"
)

type Repository struct {
	pool *pgxpool.Pool
}

func NewRepository(pool *pgxpool.Pool) *Repository {
	return &Repository{pool: pool}
}

func (r *Repository) ListBranches(ctx context.Context) ([]Branch, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT id, name, slug, address, city, phone, opens_at::text, closes_at::text, is_active
		FROM scheduling.branches
		ORDER BY name`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	branches := []Branch{}
	for rows.Next() {
		var b Branch
		if err := rows.Scan(&b.ID, &b.Name, &b.Slug, &b.Address, &b.City, &b.Phone, &b.OpensAt, &b.ClosesAt, &b.IsActive); err != nil {
			return nil, err
		}
		branches = append(branches, b)
	}
	return branches, rows.Err()
}

// ListDoctors is the public/booking list — active doctors only.
func (r *Repository) ListDoctors(ctx context.Context) ([]Doctor, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT s.id, u.full_name, s.specialization, s.photo_url
		FROM identity.staff s
		JOIN identity.users u ON u.id = s.user_id
		WHERE s.is_doctor = true AND u.is_active = true
		ORDER BY u.full_name`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	doctors := []Doctor{}
	for rows.Next() {
		var d Doctor
		if err := rows.Scan(&d.ID, &d.FullName, &d.Specialization, &d.PhotoURL); err != nil {
			return nil, err
		}
		doctors = append(doctors, d)
	}
	return doctors, rows.Err()
}

// ListDoctorsAdmin is the management list — includes deactivated doctors so
// staff can reactivate them.
func (r *Repository) ListDoctorsAdmin(ctx context.Context, page pagination.Params) ([]DoctorDetail, int64, error) {
	query := `
		SELECT s.id, u.full_name, s.specialization, s.photo_url, u.email, u.phone_wa, u.is_active, count(*) OVER() AS total_count
		FROM identity.staff s
		JOIN identity.users u ON u.id = s.user_id
		WHERE s.is_doctor = true
		ORDER BY u.full_name`
	args := []any{}
	if page.Enabled {
		args = append(args, page.Limit())
		query += fmt.Sprintf(" LIMIT $%d", len(args))
		args = append(args, page.Offset())
		query += fmt.Sprintf(" OFFSET $%d", len(args))
	}

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var total int64
	doctors := []DoctorDetail{}
	for rows.Next() {
		var d DoctorDetail
		if err := rows.Scan(&d.ID, &d.FullName, &d.Specialization, &d.PhotoURL, &d.Email, &d.PhoneWA, &d.IsActive, &total); err != nil {
			return nil, 0, err
		}
		doctors = append(doctors, d)
	}
	return doctors, total, rows.Err()
}

func (r *Repository) ListReservations(ctx context.Context, filter ReservationFilter, page pagination.Params) ([]Reservation, int64, error) {
	query := `
		SELECT
			res.id, res.patient_id, res.branch_id, res.staff_id, res.scheduled_at, res.status, res.complaint_note,
			p.full_name AS patient_name,
			b.name AS branch_name,
			su.full_name AS doctor_name,
			COALESCE(string_agg(t.name, ', ' ORDER BY t.name), '') AS treatments,
			count(*) OVER() AS total_count
		FROM scheduling.reservations res
		JOIN identity.patients p ON p.id = res.patient_id
		JOIN scheduling.branches b ON b.id = res.branch_id
		JOIN identity.staff s ON s.id = res.staff_id
		JOIN identity.users su ON su.id = s.user_id
		LEFT JOIN scheduling.reservation_treatments rt ON rt.reservation_id = res.id
		LEFT JOIN billing.treatments t ON t.id = rt.treatment_id
		WHERE 1 = 1`

	args := []any{}
	if filter.BranchID != "" {
		args = append(args, filter.BranchID)
		query += fmt.Sprintf(" AND res.branch_id = $%d", len(args))
	}
	if filter.Status != "" {
		args = append(args, filter.Status)
		query += fmt.Sprintf(" AND res.status = $%d", len(args))
	}
	if filter.From != "" {
		args = append(args, filter.From)
		query += fmt.Sprintf(" AND res.scheduled_at >= $%d::date", len(args))
	}
	if filter.To != "" {
		args = append(args, filter.To)
		query += fmt.Sprintf(" AND res.scheduled_at < ($%d::date + interval '1 day')", len(args))
	}
	if filter.PatientID != "" {
		args = append(args, filter.PatientID)
		query += fmt.Sprintf(" AND res.patient_id = $%d", len(args))
	}
	query += " GROUP BY res.id, p.full_name, b.name, su.full_name ORDER BY res.scheduled_at DESC"
	if page.Enabled {
		args = append(args, page.Limit())
		query += fmt.Sprintf(" LIMIT $%d", len(args))
		args = append(args, page.Offset())
		query += fmt.Sprintf(" OFFSET $%d", len(args))
	}

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var total int64
	reservations := []Reservation{}
	for rows.Next() {
		var res Reservation
		if err := rows.Scan(&res.ID, &res.PatientID, &res.BranchID, &res.StaffID, &res.ScheduledAt, &res.Status, &res.ComplaintNote, &res.PatientName, &res.BranchName, &res.DoctorName, &res.Treatments, &total); err != nil {
			return nil, 0, err
		}
		reservations = append(reservations, res)
	}
	return reservations, total, rows.Err()
}

// DoctorStats backs the doctor detail panel's chart/commission section:
// revenue attributed to this doctor's reservations, monthly trend for the
// last `months` months, and their most-performed treatments.
func (r *Repository) DoctorStats(ctx context.Context, staffID string, months int) (DoctorStats, error) {
	var s DoctorStats

	if err := r.pool.QueryRow(ctx, `
		SELECT
			COALESCE(sum(pay.amount) FILTER (WHERE pay.status = 'paid'), 0),
			COALESCE(sum(pay.amount) FILTER (WHERE pay.status = 'paid'), 0) * st.commission_rate / 100,
			count(DISTINCT res.id),
			count(DISTINCT res.patient_id)
		FROM identity.staff st
		LEFT JOIN scheduling.reservations res ON res.staff_id = st.id
		LEFT JOIN billing.payments pay ON pay.reservation_id = res.id
		WHERE st.id = $1
		GROUP BY st.commission_rate`, staffID,
	).Scan(&s.TotalRevenue, &s.CommissionEarned, &s.ReservationsCount, &s.PatientsServed); err != nil {
		return s, err
	}

	trendRows, err := r.pool.Query(ctx, `
		SELECT to_char(d, 'YYYY-MM') AS period,
		       COALESCE((
		         SELECT sum(pay.amount)
		         FROM billing.payments pay
		         JOIN scheduling.reservations res ON res.id = pay.reservation_id
		         WHERE res.staff_id = $1 AND pay.status = 'paid'
		           AND date_trunc('month', pay.paid_at) = date_trunc('month', d)
		       ), 0) AS revenue
		FROM generate_series(
			date_trunc('month', CURRENT_DATE) - ($2::int - 1) * interval '1 month',
			date_trunc('month', CURRENT_DATE),
			interval '1 month'
		) AS d
		ORDER BY d`, staffID, months)
	if err != nil {
		return s, err
	}
	defer trendRows.Close()
	for trendRows.Next() {
		var p DailyRevenuePair
		if err := trendRows.Scan(&p.Period, &p.Revenue); err != nil {
			return s, err
		}
		s.MonthlyRevenue = append(s.MonthlyRevenue, p)
	}
	if err := trendRows.Err(); err != nil {
		return s, err
	}

	treatmentRows, err := r.pool.Query(ctx, `
		SELECT t.name, count(*)
		FROM scheduling.reservation_treatments rt
		JOIN scheduling.reservations res ON res.id = rt.reservation_id
		JOIN billing.treatments t ON t.id = rt.treatment_id
		WHERE res.staff_id = $1
		GROUP BY t.name
		ORDER BY count(*) DESC
		LIMIT 8`, staffID)
	if err != nil {
		return s, err
	}
	defer treatmentRows.Close()
	for treatmentRows.Next() {
		var t TreatmentCountPair
		if err := treatmentRows.Scan(&t.TreatmentName, &t.Count); err != nil {
			return s, err
		}
		s.TopTreatments = append(s.TopTreatments, t)
	}
	return s, treatmentRows.Err()
}
