package billing

import (
	"context"
	"time"
)

// Expense is an operating cost (rent, utilities, supplies restock, staff
// non-commission pay, etc.) — the missing half of "laporan keuntungan"
// (profit = revenue - expenses - commission), which had no cost tracking
// at all before this.
type Expense struct {
	ID          string    `json:"id"`
	BranchID    *string   `json:"branchId"`
	BranchName  *string   `json:"branchName"`
	Category    string    `json:"category"`
	Description *string   `json:"description"`
	Amount      float64   `json:"amount"`
	ExpenseDate string    `json:"expenseDate"`
	CreatedAt   time.Time `json:"createdAt"`
}

type ExpenseInput struct {
	BranchID    *string `json:"branchId"`
	Category    string  `json:"category"`
	Description *string `json:"description"`
	Amount      float64 `json:"amount"`
	ExpenseDate string  `json:"expenseDate"`
}

func (r *Repository) ListExpenses(ctx context.Context, from, to string) ([]Expense, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT e.id, e.branch_id, b.name, e.category, e.description, e.amount, e.expense_date::text, e.created_at
		FROM billing.expenses e
		LEFT JOIN scheduling.branches b ON b.id = e.branch_id
		WHERE e.expense_date BETWEEN $1::date AND $2::date
		ORDER BY e.expense_date DESC, e.created_at DESC`, from, to)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	expenses := []Expense{}
	for rows.Next() {
		var e Expense
		if err := rows.Scan(&e.ID, &e.BranchID, &e.BranchName, &e.Category, &e.Description, &e.Amount, &e.ExpenseDate, &e.CreatedAt); err != nil {
			return nil, err
		}
		expenses = append(expenses, e)
	}
	return expenses, rows.Err()
}

func (r *Repository) CreateExpense(ctx context.Context, in ExpenseInput) (Expense, error) {
	var id string
	if err := r.pool.QueryRow(ctx, `
		INSERT INTO billing.expenses (branch_id, category, description, amount, expense_date)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id`,
		in.BranchID, in.Category, in.Description, in.Amount, in.ExpenseDate,
	).Scan(&id); err != nil {
		return Expense{}, err
	}
	return r.getExpenseByID(ctx, id)
}

func (r *Repository) UpdateExpense(ctx context.Context, id string, in ExpenseInput) (Expense, error) {
	_, err := r.pool.Exec(ctx, `
		UPDATE billing.expenses
		SET branch_id = $1, category = $2, description = $3, amount = $4, expense_date = $5
		WHERE id = $6`,
		in.BranchID, in.Category, in.Description, in.Amount, in.ExpenseDate, id)
	if err != nil {
		return Expense{}, err
	}
	return r.getExpenseByID(ctx, id)
}

func (r *Repository) DeleteExpense(ctx context.Context, id string) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM billing.expenses WHERE id = $1`, id)
	return err
}

func (r *Repository) getExpenseByID(ctx context.Context, id string) (Expense, error) {
	var e Expense
	err := r.pool.QueryRow(ctx, `
		SELECT e.id, e.branch_id, b.name, e.category, e.description, e.amount, e.expense_date::text, e.created_at
		FROM billing.expenses e
		LEFT JOIN scheduling.branches b ON b.id = e.branch_id
		WHERE e.id = $1`, id,
	).Scan(&e.ID, &e.BranchID, &e.BranchName, &e.Category, &e.Description, &e.Amount, &e.ExpenseDate, &e.CreatedAt)
	return e, err
}

// ExpensesByCategory backs the "laporan pembiayaan" chart — total cost per
// category within [from, to].
type ExpenseCategoryTotal struct {
	Category string  `json:"category"`
	Total    float64 `json:"total"`
}

func (r *Repository) ExpensesByCategory(ctx context.Context, from, to string) ([]ExpenseCategoryTotal, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT category, sum(amount)
		FROM billing.expenses
		WHERE expense_date BETWEEN $1::date AND $2::date
		GROUP BY category
		ORDER BY sum(amount) DESC`, from, to)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	totals := []ExpenseCategoryTotal{}
	for rows.Next() {
		var t ExpenseCategoryTotal
		if err := rows.Scan(&t.Category, &t.Total); err != nil {
			return nil, err
		}
		totals = append(totals, t)
	}
	return totals, rows.Err()
}

// CommissionByDoctor is the commission report — each doctor's attributed
// revenue and computed commission (revenue * their commission_rate) within
// [from, to].
type CommissionRow struct {
	StaffID        string  `json:"staffId"`
	DoctorName     string  `json:"doctorName"`
	Revenue        float64 `json:"revenue"`
	CommissionRate float64 `json:"commissionRate"`
	Commission     float64 `json:"commission"`
}

func (r *Repository) CommissionByDoctor(ctx context.Context, from, to string) ([]CommissionRow, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT s.id, u.full_name, COALESCE(sum(pay.amount), 0), s.commission_rate,
		       COALESCE(sum(pay.amount), 0) * s.commission_rate / 100
		FROM identity.staff s
		JOIN identity.users u ON u.id = s.user_id
		LEFT JOIN scheduling.reservations res ON res.staff_id = s.id
		LEFT JOIN billing.payments pay ON pay.reservation_id = res.id
		  AND pay.status = 'paid' AND pay.paid_at::date BETWEEN $1::date AND $2::date
		WHERE s.is_doctor = true
		GROUP BY s.id, u.full_name, s.commission_rate
		ORDER BY sum(pay.amount) DESC NULLS LAST`, from, to)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	rowsOut := []CommissionRow{}
	for rows.Next() {
		var c CommissionRow
		if err := rows.Scan(&c.StaffID, &c.DoctorName, &c.Revenue, &c.CommissionRate, &c.Commission); err != nil {
			return nil, err
		}
		rowsOut = append(rowsOut, c)
	}
	return rowsOut, rows.Err()
}

// ProfitReport ties revenue, total commission payable, and total expenses
// together into the bottom-line "laporan keuntungan" for [from, to].
type ProfitReport struct {
	TotalRevenue    float64 `json:"totalRevenue"`
	TotalCommission float64 `json:"totalCommission"`
	TotalExpenses   float64 `json:"totalExpenses"`
	NetProfit       float64 `json:"netProfit"`
}

func (r *Repository) GetProfitReport(ctx context.Context, from, to string) (ProfitReport, error) {
	var p ProfitReport

	if err := r.pool.QueryRow(ctx, `
		SELECT COALESCE(sum(amount), 0) FROM billing.payments
		WHERE status = 'paid' AND paid_at::date BETWEEN $1::date AND $2::date`, from, to,
	).Scan(&p.TotalRevenue); err != nil {
		return p, err
	}

	if err := r.pool.QueryRow(ctx, `
		SELECT COALESCE(sum(pay.amount * s.commission_rate / 100), 0)
		FROM billing.payments pay
		JOIN scheduling.reservations res ON res.id = pay.reservation_id
		JOIN identity.staff s ON s.id = res.staff_id
		WHERE pay.status = 'paid' AND pay.paid_at::date BETWEEN $1::date AND $2::date`, from, to,
	).Scan(&p.TotalCommission); err != nil {
		return p, err
	}

	if err := r.pool.QueryRow(ctx, `
		SELECT COALESCE(sum(amount), 0) FROM billing.expenses
		WHERE expense_date BETWEEN $1::date AND $2::date`, from, to,
	).Scan(&p.TotalExpenses); err != nil {
		return p, err
	}

	p.NetProfit = p.TotalRevenue - p.TotalCommission - p.TotalExpenses
	return p, nil
}
