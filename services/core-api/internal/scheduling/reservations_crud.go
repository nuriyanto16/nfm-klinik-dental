package scheduling

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"

	"github.com/nina-dental-care/core-api/internal/platform/dberr"
)

// CreateReservation books treatments for a patient. `created_by` is set to
// the patient's own primary account — there's no staff session to attribute
// it to yet (no auth), and "staff booked this on behalf of the patient" is
// the closest honest reading until Fase 1 auth exists.
func (r *Repository) CreateReservation(ctx context.Context, in CreateReservationInput) (Reservation, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return Reservation{}, err
	}
	defer tx.Rollback(ctx)

	status := in.Status
	if status == "" {
		status = "pending"
	}

	var reservationID string
	err = tx.QueryRow(ctx, `
		INSERT INTO scheduling.reservations (patient_id, branch_id, staff_id, scheduled_at, complaint_note, status, created_by)
		VALUES ($1, $2, $3, $4, $5, $6::scheduling.reservation_status, (SELECT primary_account_user_id FROM identity.patients WHERE id = $1))
		RETURNING id`,
		in.PatientID, in.BranchID, in.StaffID, in.ScheduledAt, in.ComplaintNote, status,
	).Scan(&reservationID)
	if err != nil {
		return Reservation{}, err
	}

	for _, treatmentID := range in.TreatmentIDs {
		if _, err := tx.Exec(ctx, `
			INSERT INTO scheduling.reservation_treatments (reservation_id, treatment_id, price_at_booking)
			VALUES ($1, $2, COALESCE((SELECT price FROM billing.treatments WHERE id = $2), 0))`,
			reservationID, treatmentID); err != nil {
			return Reservation{}, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return Reservation{}, err
	}
	return r.getReservationByID(ctx, reservationID)
}

func (r *Repository) GetReservation(ctx context.Context, id string) (Reservation, error) {
	return r.getReservationByID(ctx, id)
}

func (r *Repository) UpdateReservation(ctx context.Context, id string, in UpdateReservationInput) (Reservation, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return Reservation{}, err
	}
	defer tx.Rollback(ctx)

	// Fetch current reservation
	var current Reservation
	err = tx.QueryRow(ctx, `SELECT id, patient_id, branch_id, staff_id, scheduled_at, status, complaint_note FROM scheduling.reservations WHERE id = $1 AND deleted_at IS NULL`, id).
		Scan(&current.ID, &current.PatientID, &current.BranchID, &current.StaffID, &current.ScheduledAt, &current.Status, &current.ComplaintNote)
	if errors.Is(err, pgx.ErrNoRows) {
		return Reservation{}, dberr.ErrNotFound
	}
	if err != nil {
		return Reservation{}, err
	}

	patientID := current.PatientID
	if in.PatientID != nil && *in.PatientID != "" {
		patientID = *in.PatientID
	}
	branchID := current.BranchID
	if in.BranchID != nil && *in.BranchID != "" {
		branchID = *in.BranchID
	}
	staffID := current.StaffID
	if in.StaffID != nil && *in.StaffID != "" {
		staffID = *in.StaffID
	}
	scheduledAt := current.ScheduledAt
	if in.ScheduledAt != nil && !in.ScheduledAt.IsZero() {
		scheduledAt = *in.ScheduledAt
	}
	complaintNote := current.ComplaintNote
	if in.ComplaintNote != nil {
		complaintNote = in.ComplaintNote
	}
	status := current.Status
	if in.Status != nil && *in.Status != "" {
		status = *in.Status
	}

	_, err = tx.Exec(ctx, `
		UPDATE scheduling.reservations
		SET patient_id = $1, branch_id = $2, staff_id = $3, scheduled_at = $4, complaint_note = $5, status = $6::scheduling.reservation_status, updated_at = now()
		WHERE id = $7`,
		patientID, branchID, staffID, scheduledAt, complaintNote, status, id,
	)
	if err != nil {
		return Reservation{}, err
	}

	if in.TreatmentIDs != nil {
		if _, err := tx.Exec(ctx, `DELETE FROM scheduling.reservation_treatments WHERE reservation_id = $1`, id); err != nil {
			return Reservation{}, err
		}
		for _, treatmentID := range in.TreatmentIDs {
			if _, err := tx.Exec(ctx, `
				INSERT INTO scheduling.reservation_treatments (reservation_id, treatment_id, price_at_booking)
				VALUES ($1, $2, COALESCE((SELECT price FROM billing.treatments WHERE id = $2), 0))`,
				id, treatmentID); err != nil {
				return Reservation{}, err
			}
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return Reservation{}, err
	}
	return r.getReservationByID(ctx, id)
}

func (r *Repository) SoftDeleteReservation(ctx context.Context, id string) error {
	tag, err := r.pool.Exec(ctx, `UPDATE scheduling.reservations SET deleted_at = now(), status = 'cancelled', updated_at = now() WHERE id = $1 AND deleted_at IS NULL`, id)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return dberr.ErrNotFound
	}
	return nil
}

func (r *Repository) UpdateReservationStatus(ctx context.Context, id string, status string) (Reservation, error) {
	tag, err := r.pool.Exec(ctx, `UPDATE scheduling.reservations SET status = $1, updated_at = now() WHERE id = $2 AND deleted_at IS NULL`, status, id)
	if err != nil {
		return Reservation{}, err
	}
	if tag.RowsAffected() == 0 {
		return Reservation{}, dberr.ErrNotFound
	}
	return r.getReservationByID(ctx, id)
}

func (r *Repository) getReservationByID(ctx context.Context, id string) (Reservation, error) {
	var res Reservation
	err := r.pool.QueryRow(ctx, `
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
		WHERE res.id = $1
		GROUP BY res.id, p.full_name, b.name, su.full_name`, id,
	).Scan(&res.ID, &res.PatientID, &res.BranchID, &res.StaffID, &res.ScheduledAt, &res.Status, &res.ComplaintNote, &res.PatientName, &res.BranchName, &res.DoctorName, &res.Treatments)
	if errors.Is(err, pgx.ErrNoRows) {
		return res, dberr.ErrNotFound
	}
	return res, err
}

