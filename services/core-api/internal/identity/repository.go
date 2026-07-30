package identity

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	pool *pgxpool.Pool
}

func NewRepository(pool *pgxpool.Pool) *Repository {
	return &Repository{pool: pool}
}

func (r *Repository) ListPatients(ctx context.Context) ([]Patient, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT p.id, p.full_name, p.rm_number, p.relation, p.gender, p.date_of_birth,
		       u.phone_wa, u.email, u.city, p.address, p.created_at
		FROM identity.patients p
		JOIN identity.users u ON u.id = p.primary_account_user_id
		ORDER BY p.created_at DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	patients := []Patient{}
	for rows.Next() {
		var p Patient
		if err := rows.Scan(&p.ID, &p.FullName, &p.RMNumber, &p.Relation, &p.Gender, &p.DateOfBirth, &p.PhoneWA, &p.Email, &p.City, &p.Address, &p.CreatedAt); err != nil {
			return nil, err
		}
		patients = append(patients, p)
	}
	return patients, rows.Err()
}
