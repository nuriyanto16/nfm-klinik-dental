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
	PhotoURL             *string `json:"photoUrl"`
}

type UpdatePatientInput struct {
	FullName    string  `json:"fullName"`
	Relation    string  `json:"relation"`
	Gender      *string `json:"gender"`
	DateOfBirth *string `json:"dateOfBirth"`
	Address     *string `json:"address"`
	RMNumber    *string `json:"rmNumber"`
	PhoneWA     *string `json:"phoneWa"`
	Email       *string `json:"email"`
	City        *string `json:"city"`
	PhotoURL    *string `json:"photoUrl"`
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
			VALUES ($1, $2, 'unset', $3, $4, NULLIF($5, '')::date, $6, 'patient')
			RETURNING id`,
			in.Email, in.PhoneWA, in.FullName, in.Gender, in.DateOfBirth, in.City,
		).Scan(&id); err != nil {
			return p, err
		}
		newUserID = &id
		primaryUserID = &id
	}

	var dob *string
	if in.DateOfBirth != nil && *in.DateOfBirth != "" {
		dob = in.DateOfBirth
	}

	if err := tx.QueryRow(ctx, `
		INSERT INTO identity.patients (primary_account_user_id, user_id, full_name, relation, gender, date_of_birth, address, photo_url)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id`,
		primaryUserID, newUserID, in.FullName, in.Relation, in.Gender, dob, in.Address, in.PhotoURL,
	).Scan(&p.ID); err != nil {
		return p, err
	}

	if err := tx.Commit(ctx); err != nil {
		return p, err
	}

	return r.getPatientByID(ctx, p.ID)
}

func (r *Repository) UpdatePatient(ctx context.Context, id string, in UpdatePatientInput) (Patient, error) {
	var dob *string
	if in.DateOfBirth != nil && *in.DateOfBirth != "" {
		dob = in.DateOfBirth
	}

	var rmn *string
	if in.RMNumber != nil && *in.RMNumber != "" {
		rmn = in.RMNumber
	}

	var photo *string
	if in.PhotoURL != nil && *in.PhotoURL != "" {
		photo = in.PhotoURL
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return Patient{}, err
	}
	defer tx.Rollback(ctx)

	_, err = tx.Exec(ctx, `
		UPDATE identity.patients
		SET full_name = $1, relation = $2, gender = $3, date_of_birth = $4, address = $5,
		    rm_number = $6, photo_url = $7, updated_at = now()
		WHERE id = $8`,
		in.FullName, in.Relation, in.Gender, dob, in.Address, rmn, photo, id,
	)
	if err != nil {
		return Patient{}, err
	}

	var primaryUserID *string
	err = tx.QueryRow(ctx, `SELECT primary_account_user_id FROM identity.patients WHERE id = $1`, id).Scan(&primaryUserID)
	if err == nil && primaryUserID != nil && *primaryUserID != "" {
		_, _ = tx.Exec(ctx, `
			UPDATE identity.users
			SET full_name = $1,
			    phone_wa = COALESCE(NULLIF($2, ''), phone_wa),
			    email = COALESCE(NULLIF($3, ''), email),
			    updated_at = now()
			WHERE id = $4`,
			in.FullName, in.PhoneWA, in.Email, *primaryUserID,
		)
	} else if err == nil {
		var newID string
		err = tx.QueryRow(ctx, `
			INSERT INTO identity.users (email, phone_wa, password_hash, full_name, role)
			VALUES (NULLIF($1, ''), NULLIF($2, ''), 'unset', $3, 'patient')
			RETURNING id`,
			in.Email, in.PhoneWA, in.FullName,
		).Scan(&newID)
		if err != nil {
			_ = tx.QueryRow(ctx, `
				INSERT INTO identity.users (email, phone_wa, password_hash, full_name, role)
				VALUES (NULL, NULL, 'unset', $1, 'patient')
				RETURNING id`,
				in.FullName,
			).Scan(&newID)
		}
		if newID != "" {
			_, _ = tx.Exec(ctx, `
				UPDATE identity.patients
				SET primary_account_user_id = $1, user_id = $1
				WHERE id = $2`,
				newID, id,
			)
		}
	}

	if err := tx.Commit(ctx); err != nil {
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
		       u.phone_wa, u.email, u.city, p.address, p.photo_url, COALESCE(u.points, 0) AS points, p.created_at
		FROM identity.patients p
		JOIN identity.users u ON u.id = p.primary_account_user_id
		WHERE p.id = $1`, id,
	).Scan(&p.ID, &p.FullName, &p.RMNumber, &p.Relation, &p.Gender, &p.DateOfBirth, &p.PhoneWA, &p.Email, &p.City, &p.Address, &p.PhotoURL, &p.Points, &p.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return p, dberr.ErrNotFound
	}
	return p, err
}
