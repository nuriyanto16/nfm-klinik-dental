package scheduling

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
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
func (r *Repository) ListDoctorsAdmin(ctx context.Context) ([]DoctorDetail, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT s.id, u.full_name, s.specialization, s.photo_url, u.email, u.phone_wa, u.is_active
		FROM identity.staff s
		JOIN identity.users u ON u.id = s.user_id
		WHERE s.is_doctor = true
		ORDER BY u.full_name`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	doctors := []DoctorDetail{}
	for rows.Next() {
		var d DoctorDetail
		if err := rows.Scan(&d.ID, &d.FullName, &d.Specialization, &d.PhotoURL, &d.Email, &d.PhoneWA, &d.IsActive); err != nil {
			return nil, err
		}
		doctors = append(doctors, d)
	}
	return doctors, rows.Err()
}

func (r *Repository) ListReservations(ctx context.Context, filter ReservationFilter) ([]Reservation, error) {
	query := `
		SELECT
			res.id, res.patient_id, res.branch_id, res.staff_id, res.scheduled_at, res.status, res.complaint_note,
			p.full_name AS patient_name,
			b.name AS branch_name,
			su.full_name AS doctor_name,
			COALESCE(string_agg(t.name, ', ' ORDER BY t.name), '') AS treatments
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

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	reservations := []Reservation{}
	for rows.Next() {
		var res Reservation
		if err := rows.Scan(&res.ID, &res.PatientID, &res.BranchID, &res.StaffID, &res.ScheduledAt, &res.Status, &res.ComplaintNote, &res.PatientName, &res.BranchName, &res.DoctorName, &res.Treatments); err != nil {
			return nil, err
		}
		reservations = append(reservations, res)
	}
	return reservations, rows.Err()
}
