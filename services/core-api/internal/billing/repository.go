package billing

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

func (r *Repository) ListTreatments(ctx context.Context) ([]Treatment, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT t.id, t.category_id, t.name, c.name AS category_name, t.description, t.price, t.duration_minutes, t.image_url, t.is_active
		FROM billing.treatments t
		JOIN billing.treatment_categories c ON c.id = t.category_id
		ORDER BY c.sort_order, t.name`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	treatments := []Treatment{}
	for rows.Next() {
		var t Treatment
		if err := rows.Scan(&t.ID, &t.CategoryID, &t.Name, &t.CategoryName, &t.Description, &t.Price, &t.DurationMinutes, &t.ImageURL, &t.IsActive); err != nil {
			return nil, err
		}
		treatments = append(treatments, t)
	}
	return treatments, rows.Err()
}

func (r *Repository) ListPayments(ctx context.Context, patientID string, page pagination.Params) ([]Payment, int64, error) {
	query := `
		SELECT
			pay.id, pay.reservation_id, pay.patient_id, pay.amount, pay.deposit_amount, pay.status, pay.provider,
			pay.provider_reference, pay.payment_method, pay.promo_id, promo.title, pay.discount_amount,
			pay.paid_at, pay.expired_at, pay.created_at,
			p.full_name AS patient_name,
			b.name AS branch_name,
			count(*) OVER() AS total_count
		FROM billing.payments pay
		JOIN identity.patients p ON p.id = pay.patient_id
		JOIN scheduling.reservations r ON r.id = pay.reservation_id
		JOIN scheduling.branches b ON b.id = r.branch_id
		LEFT JOIN content.promos promo ON promo.id = pay.promo_id`

	args := []any{}
	if patientID != "" {
		args = append(args, patientID)
		query += " WHERE pay.patient_id = $1"
	}
	query += " ORDER BY pay.created_at DESC"
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
	payments := []Payment{}
	for rows.Next() {
		var p Payment
		if err := rows.Scan(&p.ID, &p.ReservationID, &p.PatientID, &p.Amount, &p.DepositAmount, &p.Status, &p.Provider, &p.ProviderReference, &p.PaymentMethod, &p.PromoID, &p.PromoTitle, &p.DiscountAmount, &p.PaidAt, &p.ExpiredAt, &p.CreatedAt, &p.PatientName, &p.BranchName, &total); err != nil {
			return nil, 0, err
		}
		p.TransactionNumber = FormatTransactionNumber(p.ID, p.CreatedAt)
		payments = append(payments, p)
	}
	return payments, total, rows.Err()
}

func (r *Repository) DashboardSummary(ctx context.Context) (DashboardSummary, error) {
	var s DashboardSummary

	if err := r.pool.QueryRow(ctx, `
		SELECT count(*) FROM scheduling.reservations WHERE scheduled_at::date = CURRENT_DATE`,
	).Scan(&s.ReservationsToday); err != nil {
		return s, err
	}

	if err := r.pool.QueryRow(ctx, `
		SELECT COALESCE(sum(amount), 0) FROM billing.payments
		WHERE status = 'paid' AND paid_at::date = CURRENT_DATE`,
	).Scan(&s.RevenueToday); err != nil {
		return s, err
	}

	if err := r.pool.QueryRow(ctx, `
		SELECT count(*) FROM scheduling.queue_tickets WHERE status IN ('waiting', 'called', 'in_service')`,
	).Scan(&s.ActiveQueue); err != nil {
		return s, err
	}

	if err := r.pool.QueryRow(ctx, `
		SELECT COALESCE(
			100.0 * count(*) FILTER (WHERE status = 'completed') / NULLIF(count(*) FILTER (WHERE status IN ('completed', 'no_show')), 0),
			0
		)
		FROM scheduling.reservations
		WHERE scheduled_at >= CURRENT_DATE - INTERVAL '7 days'`,
	).Scan(&s.AttendanceRate7d); err != nil {
		return s, err
	}

	if err := r.pool.QueryRow(ctx, `SELECT count(*) FROM identity.patients`).Scan(&s.TotalPatients); err != nil {
		return s, err
	}

	if err := r.pool.QueryRow(ctx, `
		SELECT COALESCE(sum(amount), 0) FROM billing.payments
		WHERE status = 'paid' AND date_trunc('month', paid_at) = date_trunc('month', CURRENT_DATE)`,
	).Scan(&s.RevenueThisMonth); err != nil {
		return s, err
	}

	return s, nil
}

// RevenueTrend returns one row per day for the last `days` days (including
// today), zero-filled for days with no paid transactions, oldest first —
// ready to plot as-is.
func (r *Repository) RevenueTrend(ctx context.Context, days int) ([]DailyRevenue, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT d::date::text AS date, COALESCE(sum(pay.amount), 0) AS revenue
		FROM generate_series(CURRENT_DATE - ($1::int - 1), CURRENT_DATE, interval '1 day') AS d
		LEFT JOIN billing.payments pay
			ON pay.status = 'paid' AND pay.paid_at::date = d::date
		GROUP BY d
		ORDER BY d`, days)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	trend := []DailyRevenue{}
	for rows.Next() {
		var d DailyRevenue
		if err := rows.Scan(&d.Date, &d.Revenue); err != nil {
			return nil, err
		}
		trend = append(trend, d)
	}
	return trend, rows.Err()
}

// ReservationsByStatus returns the count of reservations in each status
// value that actually occurs, most common first.
func (r *Repository) ReservationsByStatus(ctx context.Context) ([]StatusCount, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT status::text, count(*)
		FROM scheduling.reservations
		GROUP BY status
		ORDER BY count(*) DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	counts := []StatusCount{}
	for rows.Next() {
		var c StatusCount
		if err := rows.Scan(&c.Status, &c.Count); err != nil {
			return nil, err
		}
		counts = append(counts, c)
	}
	return counts, rows.Err()
}

// RevenueByBranch returns paid revenue and reservation count per branch,
// highest revenue first.
func (r *Repository) RevenueByBranch(ctx context.Context) ([]BranchRevenue, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT
			b.name AS branch_name,
			COALESCE(sum(pay.amount) FILTER (WHERE pay.status = 'paid'), 0) AS revenue,
			count(DISTINCT res.id) AS reservation_count
		FROM scheduling.branches b
		LEFT JOIN scheduling.reservations res ON res.branch_id = b.id
		LEFT JOIN billing.payments pay ON pay.reservation_id = res.id
		GROUP BY b.id, b.name
		ORDER BY revenue DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	branches := []BranchRevenue{}
	for rows.Next() {
		var b BranchRevenue
		if err := rows.Scan(&b.BranchName, &b.Revenue, &b.ReservationCount); err != nil {
			return nil, err
		}
		branches = append(branches, b)
	}
	return branches, rows.Err()
}

// TopTreatments returns the most-booked treatments (by reservation_treatments
// line items), highest first.
func (r *Repository) TopTreatments(ctx context.Context, limit int) ([]TreatmentCount, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT t.name, count(*) AS booking_count
		FROM scheduling.reservation_treatments rt
		JOIN billing.treatments t ON t.id = rt.treatment_id
		GROUP BY t.id, t.name
		ORDER BY booking_count DESC
		LIMIT $1`, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	treatments := []TreatmentCount{}
	for rows.Next() {
		var t TreatmentCount
		if err := rows.Scan(&t.TreatmentName, &t.BookingCount); err != nil {
			return nil, err
		}
		treatments = append(treatments, t)
	}
	return treatments, rows.Err()
}
