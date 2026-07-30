package billing

import "context"

type FinancialSummary struct {
	TotalRevenue      float64 `json:"totalRevenue"`
	TotalTransactions int64   `json:"totalTransactions"`
	AvgTransaction    float64 `json:"avgTransaction"`
	TotalRefunded     float64 `json:"totalRefunded"`
	TotalPending      float64 `json:"totalPending"`
}

type PaymentMethodRevenue struct {
	Method  string  `json:"method"`
	Revenue float64 `json:"revenue"`
	Count   int64   `json:"count"`
}

// FinancialSummary aggregates payments in [from, to] (inclusive dates,
// YYYY-MM-DD).
func (r *Repository) FinancialSummaryReport(ctx context.Context, from, to string) (FinancialSummary, error) {
	var s FinancialSummary
	err := r.pool.QueryRow(ctx, `
		SELECT
			COALESCE(sum(amount) FILTER (WHERE status = 'paid'), 0),
			count(*) FILTER (WHERE status = 'paid'),
			COALESCE(avg(amount) FILTER (WHERE status = 'paid'), 0),
			COALESCE(sum(amount) FILTER (WHERE status = 'refunded'), 0),
			COALESCE(sum(amount) FILTER (WHERE status = 'pending'), 0)
		FROM billing.payments
		WHERE created_at::date BETWEEN $1::date AND $2::date`,
		from, to,
	).Scan(&s.TotalRevenue, &s.TotalTransactions, &s.AvgTransaction, &s.TotalRefunded, &s.TotalPending)
	return s, err
}

// RevenueTrendRange is like RevenueTrend but for an explicit [from, to]
// range instead of "last N days" — used by the financial reports page,
// which lets staff pick a custom period.
func (r *Repository) RevenueTrendRange(ctx context.Context, from, to string) ([]DailyRevenue, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT d::date::text AS date, COALESCE(sum(pay.amount), 0) AS revenue
		FROM generate_series($1::date, $2::date, interval '1 day') AS d
		LEFT JOIN billing.payments pay
			ON pay.status = 'paid' AND pay.paid_at::date = d::date
		GROUP BY d
		ORDER BY d`, from, to)
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

func (r *Repository) RevenueByPaymentMethod(ctx context.Context, from, to string) ([]PaymentMethodRevenue, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT COALESCE(payment_method, 'lainnya'), sum(amount), count(*)
		FROM billing.payments
		WHERE status = 'paid' AND paid_at::date BETWEEN $1::date AND $2::date
		GROUP BY payment_method
		ORDER BY sum(amount) DESC`, from, to)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	methods := []PaymentMethodRevenue{}
	for rows.Next() {
		var m PaymentMethodRevenue
		if err := rows.Scan(&m.Method, &m.Revenue, &m.Count); err != nil {
			return nil, err
		}
		methods = append(methods, m)
	}
	return methods, rows.Err()
}
