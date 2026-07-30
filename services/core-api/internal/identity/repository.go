package identity

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

func (r *Repository) ListPatients(ctx context.Context, search string, page pagination.Params) ([]Patient, int64, error) {
	query := `
		SELECT p.id, p.full_name, p.rm_number, p.relation, p.gender, p.date_of_birth,
		       u.phone_wa, u.email, u.city, p.address, p.photo_url, p.created_at,
		       count(*) OVER() AS total_count
		FROM identity.patients p
		JOIN identity.users u ON u.id = p.primary_account_user_id`

	args := []any{}
	if search != "" {
		args = append(args, "%"+search+"%")
		query += fmt.Sprintf(" WHERE p.full_name ILIKE $%d OR p.rm_number ILIKE $%d", len(args), len(args))
	}
	query += " ORDER BY p.created_at DESC"
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
	patients := []Patient{}
	for rows.Next() {
		var p Patient
		if err := rows.Scan(&p.ID, &p.FullName, &p.RMNumber, &p.Relation, &p.Gender, &p.DateOfBirth, &p.PhoneWA, &p.Email, &p.City, &p.Address, &p.PhotoURL, &p.CreatedAt, &total); err != nil {
			return nil, 0, err
		}
		patients = append(patients, p)
	}
	return patients, total, rows.Err()
}

// PatientStats backs the patient detail panel: loyalty points balance
// (billing.loyalty_points, accrued on paid transactions — see
// billing.Repository.CreatePayment), lifetime spend, visit count, and a
// 6-month spending trend for the chart.
func (r *Repository) PatientStats(ctx context.Context, patientID string) (PatientStats, error) {
	var s PatientStats

	if err := r.pool.QueryRow(ctx, `
		SELECT COALESCE(lp.points, 0)
		FROM identity.patients p
		LEFT JOIN billing.loyalty_points lp ON lp.patient_id = p.id
		WHERE p.id = $1`, patientID,
	).Scan(&s.LoyaltyPoints); err != nil {
		return s, err
	}

	if err := r.pool.QueryRow(ctx, `
		SELECT COALESCE(sum(amount), 0), count(*)
		FROM billing.payments
		WHERE patient_id = $1 AND status = 'paid'`, patientID,
	).Scan(&s.TotalSpent, &s.VisitsCount); err != nil {
		return s, err
	}

	rows, err := r.pool.Query(ctx, `
		SELECT to_char(d, 'YYYY-MM') AS period,
		       COALESCE((
		         SELECT sum(amount) FROM billing.payments
		         WHERE patient_id = $1 AND status = 'paid'
		           AND date_trunc('month', paid_at) = date_trunc('month', d)
		       ), 0) AS amount
		FROM generate_series(
			date_trunc('month', CURRENT_DATE) - 5 * interval '1 month',
			date_trunc('month', CURRENT_DATE),
			interval '1 month'
		) AS d
		ORDER BY d`, patientID)
	if err != nil {
		return s, err
	}
	defer rows.Close()
	for rows.Next() {
		var row MonthlySpendingRow
		if err := rows.Scan(&row.Period, &row.Amount); err != nil {
			return s, err
		}
		s.MonthlySpending = append(s.MonthlySpending, row)
	}
	return s, rows.Err()
}
