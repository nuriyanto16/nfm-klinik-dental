package identity

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"golang.org/x/crypto/bcrypt"
)

var ErrInvalidCredentials = errors.New("invalid email or password")

type AuthUser struct {
	ID       string `json:"id"`
	FullName string `json:"fullName"`
	Email    string `json:"email"`
	Role     string `json:"role"`
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
		SELECT id, full_name, email, role::text
		FROM identity.users
		WHERE id = $1 AND role != 'patient' AND is_active = true`, id,
	).Scan(&u.ID, &u.FullName, &u.Email, &u.Role)
	if errors.Is(err, pgx.ErrNoRows) {
		return u, ErrInvalidCredentials
	}
	return u, err
}
