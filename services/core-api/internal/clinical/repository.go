package clinical

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/nina-dental-care/core-api/internal/platform/dberr"
	"github.com/nina-dental-care/core-api/internal/platform/pagination"
)

type Repository struct {
	pool *pgxpool.Pool
}

func NewRepository(pool *pgxpool.Pool) *Repository {
	return &Repository{pool: pool}
}

var ErrInsufficientStock = errors.New("insufficient stock")

func (r *Repository) ListMedicalRecords(ctx context.Context, patientID string, page pagination.Params) ([]MedicalRecord, int64, error) {
	query := `
		SELECT mr.id, mr.patient_id, p.full_name AS patient_name, mr.reservation_id, mr.staff_id,
		       su.full_name AS doctor_name, mr.diagnosis, mr.treatment_notes,
		       mr.nik, mr.occupation, mr.emergency_contact, mr.chief_complaint, mr.present_illness_history,
		       mr.has_hypertension, mr.has_heart_disease, mr.has_diabetes, mr.has_hepatitis, mr.has_hiv, mr.has_bleeding_disorder,
		       mr.drug_allergies, mr.food_allergies, mr.is_pregnant, mr.routine_medications,
		       mr.vital_blood_pressure, mr.vital_pulse, mr.vital_temperature, mr.extra_oral_exam,
		       mr.tooth_number, mr.soap_s, mr.soap_o, mr.soap_p, mr.prescription,
		       mr.created_at, count(*) OVER() AS total_count
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
	records := []MedicalRecord{}
	for rows.Next() {
		var m MedicalRecord
		if err := rows.Scan(
			&m.ID, &m.PatientID, &m.PatientName, &m.ReservationID, &m.StaffID, &m.DoctorName, &m.Diagnosis, &m.TreatmentNotes,
			&m.NIK, &m.Occupation, &m.EmergencyContact, &m.ChiefComplaint, &m.PresentIllnessHistory,
			&m.HasHypertension, &m.HasHeartDisease, &m.HasDiabetes, &m.HasHepatitis, &m.HasHiv, &m.HasBleedingDisorder,
			&m.DrugAllergies, &m.FoodAllergies, &m.IsPregnant, &m.RoutineMedications,
			&m.VitalBloodPressure, &m.VitalPulse, &m.VitalTemperature, &m.ExtraOralExam,
			&m.ToothNumber, &m.SoapS, &m.SoapO, &m.SoapP, &m.Prescription,
			&m.CreatedAt, &total,
		); err != nil {
			return nil, 0, err
		}
		records = append(records, m)
	}
	return records, total, rows.Err()
}

func (r *Repository) GetMedicalRecord(ctx context.Context, id string) (MedicalRecordDetail, error) {
	var d MedicalRecordDetail
	err := r.pool.QueryRow(ctx, `
		SELECT mr.id, mr.patient_id, p.full_name AS patient_name, mr.reservation_id, mr.staff_id,
		       su.full_name AS doctor_name, mr.diagnosis, mr.treatment_notes,
		       mr.nik, mr.occupation, mr.emergency_contact, mr.chief_complaint, mr.present_illness_history,
		       mr.has_hypertension, mr.has_heart_disease, mr.has_diabetes, mr.has_hepatitis, mr.has_hiv, mr.has_bleeding_disorder,
		       mr.drug_allergies, mr.food_allergies, mr.is_pregnant, mr.routine_medications,
		       mr.vital_blood_pressure, mr.vital_pulse, mr.vital_temperature, mr.extra_oral_exam,
		       mr.tooth_number, mr.soap_s, mr.soap_o, mr.soap_p, mr.prescription,
		       mr.created_at
		FROM clinical.medical_records mr
		JOIN identity.patients p ON p.id = mr.patient_id
		JOIN identity.staff s ON s.id = mr.staff_id
		JOIN identity.users su ON su.id = s.user_id
		WHERE mr.id = $1`, id,
	).Scan(
		&d.ID, &d.PatientID, &d.PatientName, &d.ReservationID, &d.StaffID, &d.DoctorName, &d.Diagnosis, &d.TreatmentNotes,
		&d.NIK, &d.Occupation, &d.EmergencyContact, &d.ChiefComplaint, &d.PresentIllnessHistory,
		&d.HasHypertension, &d.HasHeartDisease, &d.HasDiabetes, &d.HasHepatitis, &d.HasHiv, &d.HasBleedingDisorder,
		&d.DrugAllergies, &d.FoodAllergies, &d.IsPregnant, &d.RoutineMedications,
		&d.VitalBloodPressure, &d.VitalPulse, &d.VitalTemperature, &d.ExtraOralExam,
		&d.ToothNumber, &d.SoapS, &d.SoapO, &d.SoapP, &d.Prescription,
		&d.CreatedAt,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return d, dberr.ErrNotFound
	}
	if err != nil {
		return d, err
	}

	odontoRows, err := r.pool.Query(ctx, `
		SELECT id, tooth_number, condition, notes, photo_url FROM clinical.odontogram_entries
		WHERE medical_record_id = $1 ORDER BY tooth_number`, id)
	if err != nil {
		return d, err
	}
	defer odontoRows.Close()
	for odontoRows.Next() {
		var e OdontogramEntry
		if err := odontoRows.Scan(&e.ID, &e.ToothNumber, &e.Condition, &e.Notes, &e.PhotoURL); err != nil {
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

// PatientOdontogramTimeline returns every medical record for a patient that
// has at least one odontogram entry with a photo, oldest first — the
// frontend picks the first and last entries to render a before/after
// comparison (e.g. braces progression).
func (r *Repository) PatientOdontogramTimeline(ctx context.Context, patientID string) ([]PatientOdontogramTimeline, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT mr.id, mr.created_at
		FROM clinical.medical_records mr
		WHERE mr.patient_id = $1
		  AND EXISTS (
		    SELECT 1 FROM clinical.odontogram_entries oe
		    WHERE oe.medical_record_id = mr.id AND oe.photo_url IS NOT NULL
		  )
		ORDER BY mr.created_at ASC`, patientID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	timeline := []PatientOdontogramTimeline{}
	for rows.Next() {
		var t PatientOdontogramTimeline
		if err := rows.Scan(&t.MedicalRecordID, &t.CreatedAt); err != nil {
			return nil, err
		}
		timeline = append(timeline, t)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	for i := range timeline {
		entryRows, err := r.pool.Query(ctx, `
			SELECT id, tooth_number, condition, notes, photo_url
			FROM clinical.odontogram_entries
			WHERE medical_record_id = $1 AND photo_url IS NOT NULL
			ORDER BY tooth_number`, timeline[i].MedicalRecordID)
		if err != nil {
			return nil, err
		}
		for entryRows.Next() {
			var e OdontogramEntry
			if err := entryRows.Scan(&e.ID, &e.ToothNumber, &e.Condition, &e.Notes, &e.PhotoURL); err != nil {
				entryRows.Close()
				return nil, err
			}
			timeline[i].Odontogram = append(timeline[i].Odontogram, e)
		}
		if err := entryRows.Err(); err != nil {
			entryRows.Close()
			return nil, err
		}
		entryRows.Close()
	}

	return timeline, nil
}

// CreateMedicalRecord writes the clinical encounter, its odontogram entries,
// CreateMedicalRecord writes the clinical encounter, its odontogram entries,
// and any inventory items consumed — decrementing stock in the same
// transaction so usage and stock never drift apart.
func (r *Repository) CreateMedicalRecord(ctx context.Context, in CreateMedicalRecordInput) (MedicalRecordDetail, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return MedicalRecordDetail{}, err
	}
	defer tx.Rollback(ctx)

	var resID *string
	if in.ReservationID != nil && *in.ReservationID != "" {
		resID = in.ReservationID
	}

	var recordID string
	if err := tx.QueryRow(ctx, `
		INSERT INTO clinical.medical_records (
			patient_id, reservation_id, staff_id, diagnosis, treatment_notes,
			nik, occupation, emergency_contact, chief_complaint, present_illness_history,
			has_hypertension, has_heart_disease, has_diabetes, has_hepatitis, has_hiv, has_bleeding_disorder,
			drug_allergies, food_allergies, is_pregnant, routine_medications,
			vital_blood_pressure, vital_pulse, vital_temperature, extra_oral_exam,
			tooth_number, soap_s, soap_o, soap_p, prescription
		)
		VALUES (
			$1, $2, $3, $4, $5,
			$6, $7, $8, $9, $10,
			$11, $12, $13, $14, $15, $16,
			$17, $18, $19, $20,
			$21, $22, $23, $24,
			$25, $26, $27, $28, $29
		)
		RETURNING id`,
		in.PatientID, resID, in.StaffID, in.Diagnosis, in.TreatmentNotes,
		in.NIK, in.Occupation, in.EmergencyContact, in.ChiefComplaint, in.PresentIllnessHistory,
		in.HasHypertension, in.HasHeartDisease, in.HasDiabetes, in.HasHepatitis, in.HasHiv, in.HasBleedingDisorder,
		in.DrugAllergies, in.FoodAllergies, in.IsPregnant, in.RoutineMedications,
		in.VitalBloodPressure, in.VitalPulse, in.VitalTemperature, in.ExtraOralExam,
		in.ToothNumber, in.SoapS, in.SoapO, in.SoapP, in.Prescription,
	).Scan(&recordID); err != nil {
		return MedicalRecordDetail{}, err
	}

	for _, o := range in.Odontogram {
		if _, err := tx.Exec(ctx, `
			INSERT INTO clinical.odontogram_entries (medical_record_id, tooth_number, condition, notes, photo_url)
			VALUES ($1, $2, $3, $4, $5)`,
			recordID, o.ToothNumber, o.Condition, o.Notes, o.PhotoURL); err != nil {
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

// UpdateMedicalRecord updates an existing medical record, its diagnosis, notes,
// and odontogram entries.
func (r *Repository) UpdateMedicalRecord(ctx context.Context, id string, in UpdateMedicalRecordInput) (MedicalRecordDetail, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return MedicalRecordDetail{}, err
	}
	defer tx.Rollback(ctx)

	var resID *string
	if in.ReservationID != nil && *in.ReservationID != "" {
		resID = in.ReservationID
	}

	tag, err := tx.Exec(ctx, `
		UPDATE clinical.medical_records
		SET patient_id = $1, reservation_id = $2, staff_id = $3, diagnosis = $4, treatment_notes = $5,
		    nik = $6, occupation = $7, emergency_contact = $8, chief_complaint = $9, present_illness_history = $10,
		    has_hypertension = $11, has_heart_disease = $12, has_diabetes = $13, has_hepatitis = $14, has_hiv = $15, has_bleeding_disorder = $16,
		    drug_allergies = $17, food_allergies = $18, is_pregnant = $19, routine_medications = $20,
		    vital_blood_pressure = $21, vital_pulse = $22, vital_temperature = $23, extra_oral_exam = $24,
		    tooth_number = $25, soap_s = $26, soap_o = $27, soap_p = $28, prescription = $29
		WHERE id = $30`,
		in.PatientID, resID, in.StaffID, in.Diagnosis, in.TreatmentNotes,
		in.NIK, in.Occupation, in.EmergencyContact, in.ChiefComplaint, in.PresentIllnessHistory,
		in.HasHypertension, in.HasHeartDisease, in.HasDiabetes, in.HasHepatitis, in.HasHiv, in.HasBleedingDisorder,
		in.DrugAllergies, in.FoodAllergies, in.IsPregnant, in.RoutineMedications,
		in.VitalBloodPressure, in.VitalPulse, in.VitalTemperature, in.ExtraOralExam,
		in.ToothNumber, in.SoapS, in.SoapO, in.SoapP, in.Prescription,
		id,
	)
	if err != nil {
		return MedicalRecordDetail{}, err
	}
	if tag.RowsAffected() == 0 {
		return MedicalRecordDetail{}, dberr.ErrNotFound
	}

	// Update odontogram entries if provided (allow empty to clear or keep if we do edit)
	// We delete and re-insert anyway to reflect current state
	if _, err := tx.Exec(ctx, `DELETE FROM clinical.odontogram_entries WHERE medical_record_id = $1`, id); err != nil {
		return MedicalRecordDetail{}, err
	}
	for _, o := range in.Odontogram {
		if _, err := tx.Exec(ctx, `
			INSERT INTO clinical.odontogram_entries (medical_record_id, tooth_number, condition, notes, photo_url)
			VALUES ($1, $2, $3, $4, $5)`,
			id, o.ToothNumber, o.Condition, o.Notes, o.PhotoURL); err != nil {
			return MedicalRecordDetail{}, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return MedicalRecordDetail{}, err
	}
	return r.GetMedicalRecord(ctx, id)
}

// DeleteMedicalRecord removes a medical record and its associated odontogram and usage items.
func (r *Repository) DeleteMedicalRecord(ctx context.Context, id string) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	_, _ = tx.Exec(ctx, `DELETE FROM clinical.odontogram_entries WHERE medical_record_id = $1`, id)
	_, _ = tx.Exec(ctx, `DELETE FROM clinical.medical_record_items WHERE medical_record_id = $1`, id)
	tag, err := tx.Exec(ctx, `DELETE FROM clinical.medical_records WHERE id = $1`, id)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return dberr.ErrNotFound
	}

	return tx.Commit(ctx)
}

