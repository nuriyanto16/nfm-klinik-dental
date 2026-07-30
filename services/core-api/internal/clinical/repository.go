package clinical

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/nina-dental-care/core-api/internal/platform/dberr"
)

type Repository struct {
	pool *pgxpool.Pool
}

func NewRepository(pool *pgxpool.Pool) *Repository {
	return &Repository{pool: pool}
}

var ErrInsufficientStock = errors.New("insufficient stock")

func (r *Repository) ListMedicalRecords(ctx context.Context, patientID string) ([]MedicalRecord, error) {
	query := `
		SELECT mr.id, mr.patient_id, p.full_name AS patient_name, mr.reservation_id, mr.staff_id,
		       su.full_name AS doctor_name, mr.diagnosis, mr.treatment_notes, mr.created_at
		FROM clinical.medical_records mr
		JOIN identity.patients p ON p.id = mr.patient_id
		JOIN identity.staff s ON s.id = mr.staff_id
		JOIN identity.users su ON su.id = s.user_id
		WHERE 1 = 1`
	args := []any{}
	if patientID != "" {
		args = append(args, patientID)
		query += fmt.Sprintf(" AND mr.patient_id = $%d", len(args))
	}
	query += " ORDER BY mr.created_at DESC"

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	records := []MedicalRecord{}
	for rows.Next() {
		var m MedicalRecord
		if err := rows.Scan(&m.ID, &m.PatientID, &m.PatientName, &m.ReservationID, &m.StaffID, &m.DoctorName, &m.Diagnosis, &m.TreatmentNotes, &m.CreatedAt); err != nil {
			return nil, err
		}
		records = append(records, m)
	}
	return records, rows.Err()
}

func (r *Repository) GetMedicalRecord(ctx context.Context, id string) (MedicalRecordDetail, error) {
	var d MedicalRecordDetail
	err := r.pool.QueryRow(ctx, `
		SELECT mr.id, mr.patient_id, p.full_name AS patient_name, mr.reservation_id, mr.staff_id,
		       su.full_name AS doctor_name, mr.diagnosis, mr.treatment_notes, mr.created_at
		FROM clinical.medical_records mr
		JOIN identity.patients p ON p.id = mr.patient_id
		JOIN identity.staff s ON s.id = mr.staff_id
		JOIN identity.users su ON su.id = s.user_id
		WHERE mr.id = $1`, id,
	).Scan(&d.ID, &d.PatientID, &d.PatientName, &d.ReservationID, &d.StaffID, &d.DoctorName, &d.Diagnosis, &d.TreatmentNotes, &d.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return d, dberr.ErrNotFound
	}
	if err != nil {
		return d, err
	}

	odontoRows, err := r.pool.Query(ctx, `
		SELECT id, tooth_number, condition, notes FROM clinical.odontogram_entries
		WHERE medical_record_id = $1 ORDER BY tooth_number`, id)
	if err != nil {
		return d, err
	}
	defer odontoRows.Close()
	for odontoRows.Next() {
		var e OdontogramEntry
		if err := odontoRows.Scan(&e.ID, &e.ToothNumber, &e.Condition, &e.Notes); err != nil {
			return d, err
		}
		d.Odontogram = append(d.Odontogram, e)
	}
	if err := odontoRows.Err(); err != nil {
		return d, err
	}

	itemRows, err := r.pool.Query(ctx, `
		SELECT mri.id, mri.inventory_item_id, ii.name, ii.category::text, ii.unit, mri.quantity, mri.notes
		FROM clinical.medical_record_items mri
		JOIN billing.inventory_items ii ON ii.id = mri.inventory_item_id
		WHERE mri.medical_record_id = $1`, id)
	if err != nil {
		return d, err
	}
	defer itemRows.Close()
	for itemRows.Next() {
		var u ItemUsage
		if err := itemRows.Scan(&u.ID, &u.InventoryItemID, &u.ItemName, &u.Category, &u.Unit, &u.Quantity, &u.Notes); err != nil {
			return d, err
		}
		d.ItemsUsed = append(d.ItemsUsed, u)
	}
	return d, itemRows.Err()
}

// CreateMedicalRecord writes the clinical encounter, its odontogram entries,
// and any inventory items consumed — decrementing stock in the same
// transaction so usage and stock never drift apart.
func (r *Repository) CreateMedicalRecord(ctx context.Context, in CreateMedicalRecordInput) (MedicalRecordDetail, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return MedicalRecordDetail{}, err
	}
	defer tx.Rollback(ctx)

	var recordID string
	if err := tx.QueryRow(ctx, `
		INSERT INTO clinical.medical_records (patient_id, reservation_id, staff_id, diagnosis, treatment_notes)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id`,
		in.PatientID, in.ReservationID, in.StaffID, in.Diagnosis, in.TreatmentNotes,
	).Scan(&recordID); err != nil {
		return MedicalRecordDetail{}, err
	}

	for _, o := range in.Odontogram {
		if _, err := tx.Exec(ctx, `
			INSERT INTO clinical.odontogram_entries (medical_record_id, tooth_number, condition, notes)
			VALUES ($1, $2, $3, $4)`,
			recordID, o.ToothNumber, o.Condition, o.Notes); err != nil {
			return MedicalRecordDetail{}, err
		}
	}

	for _, item := range in.ItemsUsed {
		tag, err := tx.Exec(ctx, `
			UPDATE billing.inventory_items SET stock_quantity = stock_quantity - $1, updated_at = now()
			WHERE id = $2 AND stock_quantity >= $1`,
			item.Quantity, item.InventoryItemID)
		if err != nil {
			return MedicalRecordDetail{}, err
		}
		if tag.RowsAffected() == 0 {
			return MedicalRecordDetail{}, ErrInsufficientStock
		}
		if _, err := tx.Exec(ctx, `
			INSERT INTO clinical.medical_record_items (medical_record_id, inventory_item_id, quantity, notes)
			VALUES ($1, $2, $3, $4)`,
			recordID, item.InventoryItemID, item.Quantity, item.Notes); err != nil {
			return MedicalRecordDetail{}, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return MedicalRecordDetail{}, err
	}
	return r.GetMedicalRecord(ctx, recordID)
}
