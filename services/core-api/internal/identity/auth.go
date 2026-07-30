package identity

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"golang.org/x/crypto/bcrypt"
)

var ErrInvalidCredentials = errors.New("invalid email or password")

type AuthUser struct {
	ID       string  `json:"id"`
	FullName string  `json:"fullName"`
	Email    string  `json:"email"`
	PhoneWA  *string `json:"phoneWa"`
	Role     string  `json:"role"`
}

type UpdateOwnProfileInput struct {
	FullName string  `json:"fullName"`
	PhoneWA  *string `json:"phoneWa"`
}

type ChangePasswordInput struct {
	CurrentPassword string `json:"currentPassword"`
	NewPassword     string `json:"newPassword"`
}

// Authenticate checks email+password against identity.users for staff
// accounts (role != 'patient' — the mobile app's patient records never get
// a real password, see patients_crud.go). Returns ErrInvalidCredentials for
// both "no such user" and "wrong password" so the response never reveals
// which one it was.
func (r *Repository) Authenticate(ctx context.Context, email, password string) (AuthUser, error) {
	var u AuthUser
	var passwordHash string
	err := r.pool.QueryRow(ctx, `
		SELECT id, full_name, email, role::text, password_hash
		FROM identity.users
		WHERE email = $1 AND role != 'patient' AND is_active = true`, email,
	).Scan(&u.ID, &u.FullName, &u.Email, &u.Role, &passwordHash)
	if errors.Is(err, pgx.ErrNoRows) {
		return u, ErrInvalidCredentials
	}
	if err != nil {
		return u, err
	}
	if bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(password)) != nil {
		return u, ErrInvalidCredentials
	}
	return u, nil
}

func (r *Repository) GetAuthUser(ctx context.Context, id string) (AuthUser, error) {
	var u AuthUser
	err := r.pool.QueryRow(ctx, `
		SELECT id, full_name, email, phone_wa, role::text
		FROM identity.users
		WHERE id = $1 AND role != 'patient' AND is_active = true`, id,
	).Scan(&u.ID, &u.FullName, &u.Email, &u.PhoneWA, &u.Role)
	if errors.Is(err, pgx.ErrNoRows) {
		return u, ErrInvalidCredentials
	}
	return u, err
}

func (r *Repository) UpdateOwnProfile(ctx context.Context, userID string, in UpdateOwnProfileInput) (AuthUser, error) {
	tag, err := r.pool.Exec(ctx, `
		UPDATE identity.users SET full_name = $1, phone_wa = $2, updated_at = now()
		WHERE id = $3 AND role != 'patient'`,
		in.FullName, in.PhoneWA, userID)
	if err != nil {
		return AuthUser{}, err
	}
	if tag.RowsAffected() == 0 {
		return AuthUser{}, ErrInvalidCredentials
	}
	return r.GetAuthUser(ctx, userID)
}

func (r *Repository) ChangeOwnPassword(ctx context.Context, userID string, in ChangePasswordInput) error {
	var currentHash string
	if err := r.pool.QueryRow(ctx, `
		SELECT password_hash FROM identity.users WHERE id = $1 AND role != 'patient'`, userID,
	).Scan(&currentHash); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrInvalidCredentials
		}
		return err
	}
	if bcrypt.CompareHashAndPassword([]byte(currentHash), []byte(in.CurrentPassword)) != nil {
		return ErrInvalidCredentials
	}
	newHash, err := bcrypt.GenerateFromPassword([]byte(in.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	_, err = r.pool.Exec(ctx, `UPDATE identity.users SET password_hash = $1, updated_at = now() WHERE id = $2`, string(newHash), userID)
	return err
}
