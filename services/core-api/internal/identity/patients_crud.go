package identity

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"

	"github.com/nina-dental-care/core-api/internal/platform/dberr"
)

type CreatePatientInput struct {
	FullName             string  `json:"fullName"`
	Relation             string  `json:"relation"`
	Gender               *string `json:"gender"`
	DateOfBirth          *string `json:"dateOfBirth"`
	Address              *string `json:"address"`
	PrimaryAccountUserID *string `json:"primaryAccountUserId"`
	Email                *string `json:"email"`
	PhoneWA              *string `json:"phoneWa"`
	City                 *string `json:"city"`
}

type UpdatePatientInput struct {
	FullName    string  `json:"fullName"`
	Relation    string  `json:"relation"`
	Gender      *string `json:"gender"`
	DateOfBirth *string `json:"dateOfBirth"`
	Address     *string `json:"address"`
	RMNumber    *string `json:"rmNumber"`
}

var ErrPatientInUse = errors.New("patient has related records and cannot be deleted")

// CreatePatient either adds a family member under an existing account
// (PrimaryAccountUserID set) or creates a brand new primary account +
// patient in one go (PrimaryAccountUserID empty).
func (r *Repository) CreatePatient(ctx context.Context, in CreatePatientInput) (Patient, error) {
	var p Patient

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return p, err
	}
	defer tx.Rollback(ctx)

	primaryUserID := in.PrimaryAccountUserID
	var newUserID *string
	if primaryUserID == nil {
		var id string
		if err := tx.QueryRow(ctx, `
			INSERT INTO identity.users (email, phone_wa, password_hash, full_name, gender, date_of_birth, city, role)
			VALUES ($1, $2, 'unset', $3, $4, $5, $6, 'patient')
			RETURNING id`,
			in.Email, in.PhoneWA, in.FullName, in.Gender, in.DateOfBirth, in.City,
		).Scan(&id); err != nil {
			return p, err
		}
		newUserID = &id
		primaryUserID = &id
	}

	if err := tx.QueryRow(ctx, `
		INSERT INTO identity.patients (primary_account_user_id, user_id, full_name, relation, gender, date_of_birth, address)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id`,
		primaryUserID, newUserID, in.FullName, in.Relation, in.Gender, in.DateOfBirth, in.Address,
	).Scan(&p.ID); err != nil {
		return p, err
	}

	if err := tx.Commit(ctx); err != nil {
		return p, err
	}

	return r.getPatientByID(ctx, p.ID)
}

func (r *Repository) UpdatePatient(ctx context.Context, id string, in UpdatePatientInput) (Patient, error) {
	_, err := r.pool.Exec(ctx, `
		UPDATE identity.patients
		SET full_name = $1, relation = $2, gender = $3, date_of_birth = $4, address = $5,
		    rm_number = $6, updated_at = now()
		WHERE id = $7`,
		in.FullName, in.Relation, in.Gender, in.DateOfBirth, in.Address, in.RMNumber, id,
	)
	if err != nil {
		return Patient{}, err
	}
	return r.getPatientByID(ctx, id)
}

func (r *Repository) DeletePatient(ctx context.Context, id string) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM identity.patients WHERE id = $1`, id)
	if err != nil {
		if dberr.IsForeignKeyViolation(err) {
			return ErrPatientInUse
		}
		return err
	}
	return nil
}

func (r *Repository) getPatientByID(ctx context.Context, id string) (Patient, error) {
	var p Patient
	err := r.pool.QueryRow(ctx, `
		SELECT p.id, p.full_name, p.rm_number, p.relation, p.gender, p.date_of_birth,
		       u.phone_wa, u.email, u.city, p.address, p.created_at
		FROM identity.patients p
		JOIN identity.users u ON u.id = p.primary_account_user_id
		WHERE p.id = $1`, id,
	).Scan(&p.ID, &p.FullName, &p.RMNumber, &p.Relation, &p.Gender, &p.DateOfBirth, &p.PhoneWA, &p.Email, &p.City, &p.Address, &p.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return p, dberr.ErrNotFound
	}
	return p, err
}
