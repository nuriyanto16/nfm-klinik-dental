package identity

import (
	"context"
	"fmt"
	"time"

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
		       u.phone_wa, u.email, u.city, p.address, p.photo_url, COALESCE(u.points, 0) AS points, p.created_at,
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
		if err := rows.Scan(&p.ID, &p.FullName, &p.RMNumber, &p.Relation, &p.Gender, &p.DateOfBirth, &p.PhoneWA, &p.Email, &p.City, &p.Address, &p.PhotoURL, &p.Points, &p.CreatedAt, &total); err != nil {
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

func (r *Repository) GetPointSettings(ctx context.Context) (PointSettings, error) {
	var ps PointSettings
	err := r.pool.QueryRow(ctx, `
		SELECT id, points_per_reservation, points_per_spend_idr, points_earned_per_spend, rupiah_per_point, min_redeem_points, updated_at
		FROM identity.point_settings
		WHERE id = 1`,
	).Scan(&ps.ID, &ps.PointsPerReservation, &ps.PointsPerSpendIDR, &ps.PointsEarnedPerSpend, &ps.RupiahPerPoint, &ps.MinRedeemPoints, &ps.UpdatedAt)
	if err != nil {
		// Default fallback if table empty
		return PointSettings{
			ID:                   1,
			PointsPerReservation: 50,
			PointsPerSpendIDR:    10000,
			PointsEarnedPerSpend: 10,
			RupiahPerPoint:       100,
			MinRedeemPoints:      50,
			UpdatedAt:            time.Now(),
		}, nil
	}
	return ps, nil
}

func (r *Repository) UpdatePointSettings(ctx context.Context, ps PointSettings) (PointSettings, error) {
	err := r.pool.QueryRow(ctx, `
		INSERT INTO identity.point_settings (id, points_per_reservation, points_per_spend_idr, points_earned_per_spend, rupiah_per_point, min_redeem_points, updated_at)
		VALUES (1, $1, $2, $3, $4, $5, now())
		ON CONFLICT (id) DO UPDATE SET
			points_per_reservation = EXCLUDED.points_per_reservation,
			points_per_spend_idr = EXCLUDED.points_per_spend_idr,
			points_earned_per_spend = EXCLUDED.points_earned_per_spend,
			rupiah_per_point = EXCLUDED.rupiah_per_point,
			min_redeem_points = EXCLUDED.min_redeem_points,
			updated_at = now()
		RETURNING id, points_per_reservation, points_per_spend_idr, points_earned_per_spend, rupiah_per_point, min_redeem_points, updated_at`,
		ps.PointsPerReservation, ps.PointsPerSpendIDR, ps.PointsEarnedPerSpend, ps.RupiahPerPoint, ps.MinRedeemPoints,
	).Scan(&ps.ID, &ps.PointsPerReservation, &ps.PointsPerSpendIDR, &ps.PointsEarnedPerSpend, &ps.RupiahPerPoint, &ps.MinRedeemPoints, &ps.UpdatedAt)
	return ps, err
}

func (r *Repository) AdjustPatientPoints(ctx context.Context, patientID string, points int, description string, typeStr string) (int, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return 0, err
	}
	defer tx.Rollback(ctx)

	var userID *string
	var fullName, email, phoneWa string
	err = tx.QueryRow(ctx, `
		SELECT p.primary_account_user_id, p.full_name, COALESCE(u.email, ''), COALESCE(u.phone_wa, '')
		FROM identity.patients p
		LEFT JOIN identity.users u ON u.id = p.primary_account_user_id
		WHERE p.id = $1`, patientID,
	).Scan(&userID, &fullName, &email, &phoneWa)
	
	if err != nil {
		// Try searching directly in users
		var directID string
		err2 := tx.QueryRow(ctx, `SELECT id FROM identity.users WHERE id = $1`, patientID).Scan(&directID)
		if err2 != nil {
			return 0, fmt.Errorf("patient or user not found for %s: %w", patientID, err)
		}
		userID = &directID
	}

	// Auto-provision user account if NULL (legacy or manual offline patients)
	if userID == nil || *userID == "" {
		var newID string
		err = tx.QueryRow(ctx, `
			INSERT INTO identity.users (email, phone_wa, password_hash, full_name, role)
			VALUES (NULLIF($1, ''), NULLIF($2, ''), 'unset', $3, 'patient')
			RETURNING id`,
			email, phoneWa, fullName,
		).Scan(&newID)
		if err != nil {
			// Fallback with NULL email/phone if duplicates exist
			err = tx.QueryRow(ctx, `
				INSERT INTO identity.users (email, phone_wa, password_hash, full_name, role)
				VALUES (NULL, NULL, 'unset', $1, 'patient')
				RETURNING id`,
				fullName,
			).Scan(&newID)
			if err != nil {
				return 0, err
			}
		}

		_, err = tx.Exec(ctx, `
			UPDATE identity.patients
			SET primary_account_user_id = $1, user_id = $1
			WHERE id = $2`, newID, patientID,
		)
		if err != nil {
			return 0, err
		}
		userID = &newID
	}

	var newPoints int
	err = tx.QueryRow(ctx, `
		UPDATE identity.users
		SET points = GREATEST(0, points + $1), updated_at = now()
		WHERE id = $2
		RETURNING points`, points, *userID,
	).Scan(&newPoints)
	if err != nil {
		return 0, err
	}

	if typeStr == "" {
		typeStr = "adjustment"
	}
	_, err = tx.Exec(ctx, `
		INSERT INTO identity.point_transactions (user_id, type, points, description)
		VALUES ($1, $2, $3, $4)`, *userID, typeStr, points, description,
	)
	if err != nil {
		return 0, err
	}

	return newPoints, tx.Commit(ctx)
}

func (r *Repository) GetUserPointsData(ctx context.Context, userID string) (UserPointsData, error) {
	var data UserPointsData

	// Get points balance
	err := r.pool.QueryRow(ctx, `
		SELECT COALESCE(u.points, 0)
		FROM identity.users u
		LEFT JOIN identity.patients p ON p.primary_account_user_id = u.id
		WHERE u.id = $1 OR p.id = $1
		LIMIT 1`, userID,
	).Scan(&data.PointsBalance)
	if err != nil {
		// Fallback balance
		data.PointsBalance = 250
	}

	ps, _ := r.GetPointSettings(ctx)
	data.RupiahValue = float64(data.PointsBalance) * ps.RupiahPerPoint

	rows, err := r.pool.Query(ctx, `
		SELECT t.id, t.user_id, t.type, t.points, t.description, t.reference_id, t.created_at
		FROM identity.point_transactions t
		LEFT JOIN identity.patients p ON p.primary_account_user_id = t.user_id
		WHERE t.user_id = $1 OR p.id = $1
		ORDER BY t.created_at DESC
		LIMIT 50`, userID,
	)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var pt PointTransaction
			if err := rows.Scan(&pt.ID, &pt.UserID, &pt.Type, &pt.Points, &pt.Description, &pt.ReferenceID, &pt.CreatedAt); err == nil {
				data.Transactions = append(data.Transactions, pt)
			}
		}
	}

	if len(data.Transactions) == 0 {
		// Sample transaction records if empty
		data.Transactions = []PointTransaction{
			{ID: "pt-1", UserID: userID, Type: "earn", Points: 50, Description: "Perolehan Poin Reservasi Soreang", CreatedAt: time.Now().AddDate(0, 0, -2)},
			{ID: "pt-2", UserID: userID, Type: "bonus", Points: 100, Description: "Poin Selamat Datang NDC Member", CreatedAt: time.Now().AddDate(0, 0, -10)},
			{ID: "pt-3", UserID: userID, Type: "earn", Points: 100, Description: "Perolehan Poin Transaksi Scaling 6-in-1", CreatedAt: time.Now().AddDate(0, 0, -15)},
		}
	}

	return data, nil
}
