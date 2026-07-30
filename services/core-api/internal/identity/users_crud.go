package identity

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"golang.org/x/crypto/bcrypt"

	"github.com/nina-dental-care/core-api/internal/platform/dberr"
)

// StaffRoles are the roles manageable from the generic User & Role page.
// "dokter" accounts are managed from the dedicated Dokter page instead,
// since creating one also needs an identity.staff row and branch/schedule
// assignment — keeping that logic in one place avoids the two pages
// disagreeing about what a "doctor account" is.
var StaffRoles = []string{"perawat", "admin_cabang", "finance", "superadmin"}

type StaffUser struct {
	ID        string    `json:"id"`
	FullName  string    `json:"fullName"`
	Email     *string   `json:"email"`
	PhoneWA   *string   `json:"phoneWa"`
	Role      string    `json:"role"`
	IsActive  bool      `json:"isActive"`
	CreatedAt time.Time `json:"createdAt"`
}

type CreateUserInput struct {
	FullName string  `json:"fullName"`
	Email    string  `json:"email"`
	PhoneWA  *string `json:"phoneWa"`
	Role     string  `json:"role"`
	Password string  `json:"password"`
}

type UpdateUserInput struct {
	FullName string `json:"fullName"`
	Role     string `json:"role"`
	IsActive bool   `json:"isActive"`
}

var ErrEmailInUse = errors.New("email already in use")

func (r *Repository) ListUsers(ctx context.Context) ([]StaffUser, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT id, full_name, email, phone_wa, role::text, is_active, created_at
		FROM identity.users
		WHERE role <> 'patient'
		ORDER BY created_at DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	users := []StaffUser{}
	for rows.Next() {
		var u StaffUser
		if err := rows.Scan(&u.ID, &u.FullName, &u.Email, &u.PhoneWA, &u.Role, &u.IsActive, &u.CreatedAt); err != nil {
			return nil, err
		}
		users = append(users, u)
	}
	return users, rows.Err()
}

func (r *Repository) CreateUser(ctx context.Context, in CreateUserInput) (StaffUser, error) {
	var u StaffUser

	hash, err := bcrypt.GenerateFromPassword([]byte(in.Password), bcrypt.DefaultCost)
	if err != nil {
		return u, err
	}

	err = r.pool.QueryRow(ctx, `
		INSERT INTO identity.users (email, phone_wa, password_hash, full_name, role)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, full_name, email, phone_wa, role::text, is_active, created_at`,
		in.Email, in.PhoneWA, string(hash), in.FullName, in.Role,
	).Scan(&u.ID, &u.FullName, &u.Email, &u.PhoneWA, &u.Role, &u.IsActive, &u.CreatedAt)
	if dberr.IsUniqueViolation(err) {
		return u, ErrEmailInUse
	}
	return u, err
}

func (r *Repository) UpdateUser(ctx context.Context, id string, in UpdateUserInput) (StaffUser, error) {
	var u StaffUser
	err := r.pool.QueryRow(ctx, `
		UPDATE identity.users
		SET full_name = $1, role = $2, is_active = $3, updated_at = now()
		WHERE id = $4
		RETURNING id, full_name, email, phone_wa, role::text, is_active, created_at`,
		in.FullName, in.Role, in.IsActive, id,
	).Scan(&u.ID, &u.FullName, &u.Email, &u.PhoneWA, &u.Role, &u.IsActive, &u.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return u, dberr.ErrNotFound
	}
	return u, err
}

// DeactivateUser flips is_active off rather than deleting the row — staff
// users are referenced by created_by/staff.user_id all over the schema, so
// a hard delete would either cascade destructively or fail on FK.
func (r *Repository) DeactivateUser(ctx context.Context, id string) error {
	tag, err := r.pool.Exec(ctx, `UPDATE identity.users SET is_active = false, updated_at = now() WHERE id = $1`, id)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return dberr.ErrNotFound
	}
	return nil
}
