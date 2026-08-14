package settings

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/nina-dental-care/core-api/internal/platform/dberr"
)

type Repository struct {
	db *pgxpool.Pool
}

func NewRepository(db *pgxpool.Pool) *Repository {
	return &Repository{db: db}
}

// GetAll returns all public settings as a map
func (r *Repository) GetAll(ctx context.Context) (map[string]string, error) {
	rows, err := r.db.Query(ctx, `SELECT key_name, value_data FROM app_settings`)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return make(map[string]string), nil
		}
		return nil, err
	}
	defer rows.Close()

	result := make(map[string]string)
	for rows.Next() {
		var key, val string
		if err := rows.Scan(&key, &val); err != nil {
			return nil, err
		}
		result[key] = val
	}
	return result, nil
}

// GetList returns all settings as array (for admin panel)
func (r *Repository) GetList(ctx context.Context) ([]AppSetting, error) {
	rows, err := r.db.Query(ctx, `SELECT id, key_name, value_data, description, updated_at FROM app_settings ORDER BY key_name ASC`)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return []AppSetting{}, nil
		}
		return nil, err
	}
	defer rows.Close()

	var settings []AppSetting
	for rows.Next() {
		var s AppSetting
		if err := rows.Scan(&s.ID, &s.KeyName, &s.ValueData, &s.Description, &s.UpdatedAt); err != nil {
			return nil, err
		}
		settings = append(settings, s)
	}
	return settings, nil
}

// Update updates a specific setting by key_name
func (r *Repository) Update(ctx context.Context, keyName string, in UpdateSettingInput) (*AppSetting, error) {
	query := `
		UPDATE app_settings 
		SET value_data = $1, updated_at = CURRENT_TIMESTAMP
		WHERE key_name = $2
		RETURNING id, key_name, value_data, description, updated_at
	`
	var s AppSetting
	if err := r.db.QueryRow(ctx, query, in.ValueData, keyName).Scan(&s.ID, &s.KeyName, &s.ValueData, &s.Description, &s.UpdatedAt); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, dberr.ErrNotFound
		}
		return nil, err
	}
	return &s, nil
}
