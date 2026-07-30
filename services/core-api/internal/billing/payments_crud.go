package billing

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"

	"github.com/nina-dental-care/core-api/internal/platform/dberr"
)

// CreatePaymentInput records an office/walk-in transaction — a front-desk
// staff member taking cash or a manual bank transfer for a reservation,
// as opposed to the patient paying through the Xendit flow in
// payment-service. `provider` is always "manual" for these.
type CreatePaymentInput struct {
	ReservationID string  `json:"reservationId"`
	Amount        float64 `json:"amount"`
	DepositAmount float64 `json:"depositAmount"`
	PaymentMethod string  `json:"paymentMethod"`
	Status        string  `json:"status"`
}

func (r *Repository) CreatePayment(ctx context.Context, in CreatePaymentInput) (Payment, error) {
	var id string
	err := r.pool.QueryRow(ctx, `
		INSERT INTO billing.payments (reservation_id, patient_id, amount, deposit_amount, status, provider, payment_method, paid_at)
		VALUES (
			$1,
			(SELECT patient_id FROM scheduling.reservations WHERE id = $1),
			$2, $3, $4::billing.payment_status, 'manual', $5,
			CASE WHEN $4::billing.payment_status = 'paid' THEN now() ELSE NULL END
		)
		RETURNING id`,
		in.ReservationID, in.Amount, in.DepositAmount, in.Status, in.PaymentMethod,
	).Scan(&id)
	if err != nil {
		return Payment{}, err
	}
	return r.GetPayment(ctx, id)
}

func (r *Repository) GetPayment(ctx context.Context, id string) (Payment, error) {
	var p Payment
	err := r.pool.QueryRow(ctx, `
		SELECT
			pay.id, pay.reservation_id, pay.patient_id, pay.amount, pay.deposit_amount, pay.status, pay.provider,
			pay.provider_reference, pay.payment_method, pay.paid_at, pay.expired_at, pay.created_at,
			p.full_name AS patient_name,
			b.name AS branch_name
		FROM billing.payments pay
		JOIN identity.patients p ON p.id = pay.patient_id
		JOIN scheduling.reservations r ON r.id = pay.reservation_id
		JOIN scheduling.branches b ON b.id = r.branch_id
		WHERE pay.id = $1`, id,
	).Scan(&p.ID, &p.ReservationID, &p.PatientID, &p.Amount, &p.DepositAmount, &p.Status, &p.Provider, &p.ProviderReference, &p.PaymentMethod, &p.PaidAt, &p.ExpiredAt, &p.CreatedAt, &p.PatientName, &p.BranchName)
	if errors.Is(err, pgx.ErrNoRows) {
		return p, dberr.ErrNotFound
	}
	return p, err
}

// InvoiceDetail is everything the printable invoice/receipt view needs in
// one call.
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
		return InvoiceDetail{}, err
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
		return inv, err
	}

	rows, err := r.pool.Query(ctx, `
		SELECT t.name, rt.price_at_booking
		FROM billing.payments pay
		JOIN scheduling.reservation_treatments rt ON rt.reservation_id = pay.reservation_id
		JOIN billing.treatments t ON t.id = rt.treatment_id
		WHERE pay.id = $1`, paymentID)
	if err != nil {
		return inv, err
	}
	defer rows.Close()
	for rows.Next() {
		var li LineItem
		if err := rows.Scan(&li.Name, &li.Price); err != nil {
			return inv, err
		}
		inv.Treatments = append(inv.Treatments, li)
	}
	return inv, rows.Err()
}
