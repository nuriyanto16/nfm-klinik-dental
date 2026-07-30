package scheduling

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"

	"github.com/nina-dental-care/core-api/internal/platform/dberr"
)

func (r *Repository) GetDoctor(ctx context.Context, id string) (DoctorDetail, error) {
	var d DoctorDetail
	err := r.pool.QueryRow(ctx, `
		SELECT s.id, u.full_name, s.specialization, s.photo_url, u.email, u.phone_wa, u.is_active
		FROM identity.staff s
		JOIN identity.users u ON u.id = s.user_id
		WHERE s.id = $1 AND s.is_doctor = true`, id,
	).Scan(&d.ID, &d.FullName, &d.Specialization, &d.PhotoURL, &d.Email, &d.PhoneWA, &d.IsActive)
	if errors.Is(err, pgx.ErrNoRows) {
		return d, dberr.ErrNotFound
	}
	if err != nil {
		return d, err
	}

	branchRows, err := r.pool.Query(ctx, `SELECT branch_id::text FROM scheduling.staff_branches WHERE staff_id = $1`, id)
	if err != nil {
		return d, err
	}
	defer branchRows.Close()
	for branchRows.Next() {
		var branchID string
		if err := branchRows.Scan(&branchID); err != nil {
			return d, err
		}
		d.BranchIDs = append(d.BranchIDs, branchID)
	}
	if err := branchRows.Err(); err != nil {
		return d, err
	}

	scheduleRows, err := r.pool.Query(ctx, `
		SELECT day_of_week, branch_id::text, start_time::text, end_time::text, slot_duration_minutes
		FROM scheduling.doctor_schedules WHERE staff_id = $1 ORDER BY day_of_week`, id)
	if err != nil {
		return d, err
	}
	defer scheduleRows.Close()
	for scheduleRows.Next() {
		var s DoctorSchedule
		if err := scheduleRows.Scan(&s.DayOfWeek, &s.BranchID, &s.StartTime, &s.EndTime, &s.SlotDurationMinutes); err != nil {
			return d, err
		}
		d.Schedules = append(d.Schedules, s)
	}
	return d, scheduleRows.Err()
}

func (r *Repository) CreateDoctor(ctx context.Context, in CreateDoctorInput) (DoctorDetail, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return DoctorDetail{}, err
	}
	defer tx.Rollback(ctx)

	var userID string
	if err := tx.QueryRow(ctx, `
		INSERT INTO identity.users (email, phone_wa, password_hash, full_name, role)
		VALUES ($1, $2, 'unset', $3, 'dokter')
		RETURNING id`,
		in.Email, in.PhoneWA, in.FullName,
	).Scan(&userID); err != nil {
		if dberr.IsUniqueViolation(err) {
			return DoctorDetail{}, ErrDoctorEmailInUse
		}
		return DoctorDetail{}, err
	}

	var staffID string
	if err := tx.QueryRow(ctx, `
		INSERT INTO identity.staff (user_id, specialization, is_doctor)
		VALUES ($1, $2, true)
		RETURNING id`,
		userID, in.Specialization,
	).Scan(&staffID); err != nil {
		return DoctorDetail{}, err
	}

	if err := insertStaffBranchesAndSchedules(ctx, tx, staffID, in.BranchIDs, in.Schedules); err != nil {
		return DoctorDetail{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return DoctorDetail{}, err
	}
	return r.GetDoctor(ctx, staffID)
}

func (r *Repository) UpdateDoctor(ctx context.Context, id string, in UpdateDoctorInput) (DoctorDetail, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return DoctorDetail{}, err
	}
	defer tx.Rollback(ctx)

	var userID string
	if err := tx.QueryRow(ctx, `SELECT user_id::text FROM identity.staff WHERE id = $1`, id).Scan(&userID); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return DoctorDetail{}, dberr.ErrNotFound
		}
		return DoctorDetail{}, err
	}

	if _, err := tx.Exec(ctx, `UPDATE identity.users SET full_name = $1, is_active = $2, updated_at = now() WHERE id = $3`,
		in.FullName, in.IsActive, userID); err != nil {
		return DoctorDetail{}, err
	}
	if _, err := tx.Exec(ctx, `UPDATE identity.staff SET specialization = $1 WHERE id = $2`, in.Specialization, id); err != nil {
		return DoctorDetail{}, err
	}

	if _, err := tx.Exec(ctx, `DELETE FROM scheduling.staff_branches WHERE staff_id = $1`, id); err != nil {
		return DoctorDetail{}, err
	}
	if _, err := tx.Exec(ctx, `DELETE FROM scheduling.doctor_schedules WHERE staff_id = $1`, id); err != nil {
		return DoctorDetail{}, err
	}
	if err := insertStaffBranchesAndSchedules(ctx, tx, id, in.BranchIDs, in.Schedules); err != nil {
		return DoctorDetail{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return DoctorDetail{}, err
	}
	return r.GetDoctor(ctx, id)
}

// DeactivateDoctor turns the login off rather than deleting the staff row —
// past reservations and schedules reference identity.staff(id), so a hard
// delete would either cascade destructively or fail on FK.
func (r *Repository) DeactivateDoctor(ctx context.Context, id string) error {
	tag, err := r.pool.Exec(ctx, `
		UPDATE identity.users SET is_active = false, updated_at = now()
		WHERE id = (SELECT user_id FROM identity.staff WHERE id = $1)`, id)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return dberr.ErrNotFound
	}
	return nil
}

func insertStaffBranchesAndSchedules(ctx context.Context, tx pgx.Tx, staffID string, branchIDs []string, schedules []DoctorSchedule) error {
	for _, branchID := range branchIDs {
		if _, err := tx.Exec(ctx, `INSERT INTO scheduling.staff_branches (staff_id, branch_id) VALUES ($1, $2)`, staffID, branchID); err != nil {
			return err
		}
	}
	for _, s := range schedules {
		if _, err := tx.Exec(ctx, `
			INSERT INTO scheduling.doctor_schedules (staff_id, branch_id, day_of_week, start_time, end_time, slot_duration_minutes)
			VALUES ($1, $2, $3, $4, $5, $6)`,
			staffID, s.BranchID, s.DayOfWeek, s.StartTime, s.EndTime, s.SlotDurationMinutes); err != nil {
			return err
		}
	}
	return nil
}

var ErrDoctorEmailInUse = errors.New("email already in use")
