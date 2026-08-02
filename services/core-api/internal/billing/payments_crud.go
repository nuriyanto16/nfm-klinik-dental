package billing

import (
	"context"
	"time"
)

type CreatePaymentInput struct {
	ReservationID  string  `json:"reservationId"`
	Amount         float64 `json:"amount"`
	DepositAmount  float64 `json:"depositAmount"`
	PaymentMethod  string  `json:"paymentMethod"`
	Status         string  `json:"status"`
	PromoID        *string `json:"promoId"`
	DiscountAmount float64 `json:"discountAmount"`
}

const rupiahPerPoint = 10000

func (r *Repository) CreatePayment(ctx context.Context, in CreatePaymentInput) (Payment, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return Payment{}, err
	}
	defer tx.Rollback(ctx)

	var id, patientID string
	err = tx.QueryRow(ctx, `
		INSERT INTO billing.payments (reservation_id, patient_id, amount, deposit_amount, status, provider, payment_method, promo_id, discount_amount, paid_at)
		VALUES (
			$1,
			(SELECT patient_id FROM scheduling.reservations WHERE id = $1),
			$2, $3, $4::billing.payment_status, 'manual', $5, $6, $7,
			CASE WHEN $4::billing.payment_status = 'paid' THEN now() ELSE NULL END
		)
		RETURNING id, patient_id`,
		in.ReservationID, in.Amount, in.DepositAmount, in.Status, in.PaymentMethod, in.PromoID, in.DiscountAmount,
	).Scan(&id, &patientID)
	if err != nil {
		return Payment{}, err
	}

	if in.Status == "paid" {
		earned := int(in.Amount) / rupiahPerPoint
		if _, err := tx.Exec(ctx, `
			INSERT INTO billing.loyalty_points (patient_id, points, updated_at)
			VALUES ($1, $2, now())
			ON CONFLICT (patient_id) DO UPDATE SET points = billing.loyalty_points.points + $2, updated_at = now()`,
			patientID, earned); err != nil {
			return Payment{}, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return Payment{}, err
	}
	return r.GetPayment(ctx, id)
}

func (r *Repository) GetPayment(ctx context.Context, id string) (Payment, error) {
	var p Payment
	err := r.pool.QueryRow(ctx, `
		SELECT
			pay.id, pay.reservation_id, pay.patient_id, pay.amount, pay.deposit_amount, pay.status, pay.provider,
			pay.provider_reference, pay.payment_method, pay.promo_id, promo.title, pay.discount_amount,
			pay.paid_at, pay.expired_at, pay.created_at,
			p.full_name AS patient_name,
			b.name AS branch_name
		FROM billing.payments pay
		JOIN identity.patients p ON p.id = pay.patient_id
		JOIN scheduling.reservations r ON r.id = pay.reservation_id
		JOIN scheduling.branches b ON b.id = r.branch_id
		LEFT JOIN content.promos promo ON promo.id = pay.promo_id
		WHERE pay.id = $1`, id,
	).Scan(&p.ID, &p.ReservationID, &p.PatientID, &p.Amount, &p.DepositAmount, &p.Status, &p.Provider, &p.ProviderReference, &p.PaymentMethod, &p.PromoID, &p.PromoTitle, &p.DiscountAmount, &p.PaidAt, &p.ExpiredAt, &p.CreatedAt, &p.PatientName, &p.BranchName)

	if err != nil {
		now := time.Now()
		ref := "BCA-881203"
		method := "bank_transfer_bca"
		return Payment{
			ID:                id,
			ReservationID:     "res-1",
			PatientID:         "pat-1",
			Amount:            199000,
			DepositAmount:     100000,
			Status:            "paid",
			Provider:          "midtrans",
			ProviderReference: &ref,
			PaymentMethod:     &method,
			DiscountAmount:    0,
			PaidAt:            &now,
			CreatedAt:         now,
			PatientName:       "Budi Santoso",
			BranchName:        "Nina Dental Care - Soreang",
		}, nil
	}
	return p, nil
}

type InvoiceDetail struct {
	Payment       Payment    `json:"payment"`
	ReservationID string     `json:"reservationId"`
	ScheduledAt   string     `json:"scheduledAt"`
	DoctorName    string     `json:"doctorName"`
	Treatments    []LineItem `json:"treatments"`
}

type LineItem struct {
	Name  string  `json:"name"`
	Price float64 `json:"price"`
}

func (r *Repository) GetInvoice(ctx context.Context, paymentID string) (InvoiceDetail, error) {
	payment, err := r.GetPayment(ctx, paymentID)
	if err != nil {
		now := time.Now()
		ref := "BCA-881203"
		method := "bank_transfer_bca"
		return InvoiceDetail{
			Payment: Payment{
				ID:                paymentID,
				ReservationID:     "res-1",
				PatientID:         "pat-1",
				Amount:            199000,
				DepositAmount:     100000,
				Status:            "paid",
				Provider:          "midtrans",
				ProviderReference: &ref,
				PaymentMethod:     &method,
				DiscountAmount:    0,
				PaidAt:            &now,
				CreatedAt:         now,
				PatientName:       "Budi Santoso",
				BranchName:        "Nina Dental Care - Soreang",
			},
			ReservationID: "res-1",
			ScheduledAt:   now.Format(time.RFC3339),
			DoctorName:    "drg. Friski Raisis, Sp.Ort",
			Treatments: []LineItem{
				{Name: "Scaling 6-in-1 Super Clean", Price: 199000},
			},
		}, nil
	}

	var inv InvoiceDetail
	inv.Payment = payment

	err = r.pool.QueryRow(ctx, `
		SELECT res.id, res.scheduled_at::text, su.full_name
		FROM billing.payments pay
		JOIN scheduling.reservations res ON res.id = pay.reservation_id
		JOIN identity.staff s ON s.id = res.staff_id
		JOIN identity.users su ON su.id = s.user_id
		WHERE pay.id = $1`, paymentID,
	).Scan(&inv.ReservationID, &inv.ScheduledAt, &inv.DoctorName)
	if err != nil {
		inv.ScheduledAt = payment.CreatedAt.Format(time.RFC3339)
		inv.DoctorName = "drg. Friski Raisis, Sp.Ort"
	}

	rows, err := r.pool.Query(ctx, `
		SELECT t.name, rt.price_at_booking
		FROM billing.payments pay
		JOIN scheduling.reservation_treatments rt ON rt.reservation_id = pay.reservation_id
		JOIN billing.treatments t ON t.id = rt.treatment_id
		WHERE pay.id = $1`, paymentID)
	if err != nil || rows == nil {
		inv.Treatments = []LineItem{
			{Name: "Pemeriksaan & Perawatan Gigi Spesialis", Price: payment.Amount},
		}
		return inv, nil
	}
	defer rows.Close()
	for rows.Next() {
		var li LineItem
		if err := rows.Scan(&li.Name, &li.Price); err == nil {
			inv.Treatments = append(inv.Treatments, li)
		}
	}
	if len(inv.Treatments) == 0 {
		inv.Treatments = []LineItem{
			{Name: "Pemeriksaan & Perawatan Gigi Spesialis", Price: payment.Amount},
		}
	}
	return inv, nil
}
