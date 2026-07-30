package billing

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"

	"github.com/nina-dental-care/core-api/internal/platform/dberr"
)

var ErrTreatmentInUse = errors.New("treatment has related bookings and cannot be deleted")

func (r *Repository) ListTreatmentCategories(ctx context.Context) ([]TreatmentCategory, error) {
	rows, err := r.pool.Query(ctx, `SELECT id, name, sort_order FROM billing.treatment_categories ORDER BY sort_order, name`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	categories := []TreatmentCategory{}
	for rows.Next() {
		var c TreatmentCategory
		if err := rows.Scan(&c.ID, &c.Name, &c.SortOrder); err != nil {
			return nil, err
		}
		categories = append(categories, c)
	}
	return categories, rows.Err()
}

func (r *Repository) CreateTreatmentCategory(ctx context.Context, name string) (TreatmentCategory, error) {
	var c TreatmentCategory
	c.Name = name
	err := r.pool.QueryRow(ctx, `
		INSERT INTO billing.treatment_categories (name, sort_order)
		VALUES ($1, (SELECT COALESCE(max(sort_order), 0) + 1 FROM billing.treatment_categories))
		RETURNING id, sort_order`, name,
	).Scan(&c.ID, &c.SortOrder)
	return c, err
}

func (r *Repository) getTreatmentByID(ctx context.Context, id string) (Treatment, error) {
	var t Treatment
	err := r.pool.QueryRow(ctx, `
		SELECT t.id, t.category_id, t.name, c.name AS category_name, t.description, t.price, t.duration_minutes, t.image_url, t.is_active
		FROM billing.treatments t
		JOIN billing.treatment_categories c ON c.id = t.category_id
		WHERE t.id = $1`, id,
	).Scan(&t.ID, &t.CategoryID, &t.Name, &t.CategoryName, &t.Description, &t.Price, &t.DurationMinutes, &t.ImageURL, &t.IsActive)
	if errors.Is(err, pgx.ErrNoRows) {
		return t, dberr.ErrNotFound
	}
	return t, err
}

func (r *Repository) CreateTreatment(ctx context.Context, in TreatmentInput) (Treatment, error) {
	var id string
	err := r.pool.QueryRow(ctx, `
		INSERT INTO billing.treatments (category_id, name, description, price, duration_minutes, image_url, is_active)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id`,
		in.CategoryID, in.Name, in.Description, in.Price, in.DurationMinutes, in.ImageURL, in.IsActive,
	).Scan(&id)
	if err != nil {
		return Treatment{}, err
	}
	return r.getTreatmentByID(ctx, id)
}

func (r *Repository) UpdateTreatment(ctx context.Context, id string, in TreatmentInput) (Treatment, error) {
	tag, err := r.pool.Exec(ctx, `
		UPDATE billing.treatments
		SET category_id = $1, name = $2, description = $3, price = $4, duration_minutes = $5, image_url = $6, is_active = $7
		WHERE id = $8`,
		in.CategoryID, in.Name, in.Description, in.Price, in.DurationMinutes, in.ImageURL, in.IsActive, id)
	if err != nil {
		return Treatment{}, err
	}
	if tag.RowsAffected() == 0 {
		return Treatment{}, dberr.ErrNotFound
	}
	return r.getTreatmentByID(ctx, id)
}

func (r *Repository) DeleteTreatment(ctx context.Context, id string) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM billing.treatments WHERE id = $1`, id)
	if err != nil {
		if dberr.IsForeignKeyViolation(err) {
			return ErrTreatmentInUse
		}
		return err
	}
	return nil
}

// TreatmentStats ranks every active-or-not treatment by how often it's been
// booked and how much revenue it's brought in — the Treatments page's
// "paling banyak dipesan" chart panel, unlike the dashboard's top-N view.
func (r *Repository) TreatmentStats(ctx context.Context) ([]TreatmentStat, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT t.id, t.name,
		       count(rt.reservation_id) AS booking_count,
		       COALESCE(sum(rt.price_at_booking) FILTER (WHERE pay.status = 'paid'), 0) AS revenue
		FROM billing.treatments t
		LEFT JOIN scheduling.reservation_treatments rt ON rt.treatment_id = t.id
		LEFT JOIN billing.payments pay ON pay.reservation_id = rt.reservation_id
		GROUP BY t.id, t.name
		ORDER BY booking_count DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	stats := []TreatmentStat{}
	for rows.Next() {
		var s TreatmentStat
		if err := rows.Scan(&s.TreatmentID, &s.TreatmentName, &s.BookingCount, &s.Revenue); err != nil {
			return nil, err
		}
		stats = append(stats, s)
	}
	return stats, rows.Err()
}
