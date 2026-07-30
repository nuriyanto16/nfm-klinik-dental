package content

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/nina-dental-care/core-api/internal/platform/dberr"
)

type Repository struct {
	pool *pgxpool.Pool
}

func NewRepository(pool *pgxpool.Pool) *Repository {
	return &Repository{pool: pool}
}

// --- Article categories ---

func (r *Repository) ListArticleCategories(ctx context.Context) ([]ArticleCategory, error) {
	rows, err := r.pool.Query(ctx, `SELECT id, name FROM content.article_categories ORDER BY name`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	categories := []ArticleCategory{}
	for rows.Next() {
		var c ArticleCategory
		if err := rows.Scan(&c.ID, &c.Name); err != nil {
			return nil, err
		}
		categories = append(categories, c)
	}
	return categories, rows.Err()
}

func (r *Repository) CreateArticleCategory(ctx context.Context, name string) (ArticleCategory, error) {
	var c ArticleCategory
	err := r.pool.QueryRow(ctx, `INSERT INTO content.article_categories (name) VALUES ($1) RETURNING id, name`, name).Scan(&c.ID, &c.Name)
	return c, err
}

// --- Articles ---

func (r *Repository) ListArticles(ctx context.Context) ([]Article, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT a.id, a.category_id, c.name, a.title, a.slug, a.cover_image_url, a.body, a.published_at, a.created_at
		FROM content.articles a
		LEFT JOIN content.article_categories c ON c.id = a.category_id
		ORDER BY a.created_at DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	articles := []Article{}
	for rows.Next() {
		var a Article
		if err := rows.Scan(&a.ID, &a.CategoryID, &a.CategoryName, &a.Title, &a.Slug, &a.CoverImageURL, &a.Body, &a.PublishedAt, &a.CreatedAt); err != nil {
			return nil, err
		}
		articles = append(articles, a)
	}
	return articles, rows.Err()
}

func (r *Repository) CreateArticle(ctx context.Context, in ArticleInput) (Article, error) {
	var a Article
	err := r.pool.QueryRow(ctx, `
		INSERT INTO content.articles (category_id, title, slug, cover_image_url, body, published_at)
		VALUES ($1, $2, $3, $4, $5, CASE WHEN $6 THEN now() ELSE NULL END)
		RETURNING id, category_id, title, slug, cover_image_url, body, published_at, created_at`,
		in.CategoryID, in.Title, in.Slug, in.CoverImageURL, in.Body, in.Published,
	).Scan(&a.ID, &a.CategoryID, &a.Title, &a.Slug, &a.CoverImageURL, &a.Body, &a.PublishedAt, &a.CreatedAt)
	return a, err
}

func (r *Repository) UpdateArticle(ctx context.Context, id string, in ArticleInput) (Article, error) {
	var a Article
	err := r.pool.QueryRow(ctx, `
		UPDATE content.articles
		SET category_id = $1, title = $2, slug = $3, cover_image_url = $4, body = $5,
		    published_at = CASE WHEN $6 AND published_at IS NULL THEN now() WHEN NOT $6 THEN NULL ELSE published_at END
		WHERE id = $7
		RETURNING id, category_id, title, slug, cover_image_url, body, published_at, created_at`,
		in.CategoryID, in.Title, in.Slug, in.CoverImageURL, in.Body, in.Published, id,
	).Scan(&a.ID, &a.CategoryID, &a.Title, &a.Slug, &a.CoverImageURL, &a.Body, &a.PublishedAt, &a.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return a, dberr.ErrNotFound
	}
	return a, err
}

func (r *Repository) DeleteArticle(ctx context.Context, id string) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM content.articles WHERE id = $1`, id)
	return err
}

// --- Promos ---

func (r *Repository) ListPromos(ctx context.Context) ([]Promo, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT id, title, banner_image_url, description, starts_at, ends_at, is_active
		FROM content.promos ORDER BY starts_at DESC NULLS LAST`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	promos := []Promo{}
	for rows.Next() {
		var p Promo
		if err := rows.Scan(&p.ID, &p.Title, &p.BannerImageURL, &p.Description, &p.StartsAt, &p.EndsAt, &p.IsActive); err != nil {
			return nil, err
		}
		promos = append(promos, p)
	}
	return promos, rows.Err()
}

func (r *Repository) CreatePromo(ctx context.Context, in PromoInput) (Promo, error) {
	var p Promo
	err := r.pool.QueryRow(ctx, `
		INSERT INTO content.promos (title, banner_image_url, description, starts_at, ends_at, is_active)
		VALUES ($1, $2, $3, NULLIF($4, '')::timestamptz, NULLIF($5, '')::timestamptz, $6)
		RETURNING id, title, banner_image_url, description, starts_at, ends_at, is_active`,
		in.Title, in.BannerImageURL, in.Description, in.StartsAt, in.EndsAt, in.IsActive,
	).Scan(&p.ID, &p.Title, &p.BannerImageURL, &p.Description, &p.StartsAt, &p.EndsAt, &p.IsActive)
	return p, err
}

func (r *Repository) UpdatePromo(ctx context.Context, id string, in PromoInput) (Promo, error) {
	var p Promo
	err := r.pool.QueryRow(ctx, `
		UPDATE content.promos
		SET title = $1, banner_image_url = $2, description = $3,
		    starts_at = NULLIF($4, '')::timestamptz, ends_at = NULLIF($5, '')::timestamptz, is_active = $6
		WHERE id = $7
		RETURNING id, title, banner_image_url, description, starts_at, ends_at, is_active`,
		in.Title, in.BannerImageURL, in.Description, in.StartsAt, in.EndsAt, in.IsActive, id,
	).Scan(&p.ID, &p.Title, &p.BannerImageURL, &p.Description, &p.StartsAt, &p.EndsAt, &p.IsActive)
	if errors.Is(err, pgx.ErrNoRows) {
		return p, dberr.ErrNotFound
	}
	return p, err
}

func (r *Repository) DeletePromo(ctx context.Context, id string) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM content.promos WHERE id = $1`, id)
	return err
}

// --- Testimonials ---

func (r *Repository) ListTestimonials(ctx context.Context) ([]Testimonial, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT t.id, t.patient_name, su.full_name, t.photo_url, t.rating, t.quote
		FROM content.testimonials t
		LEFT JOIN identity.staff s ON s.id = t.staff_id
		LEFT JOIN identity.users su ON su.id = s.user_id
		ORDER BY t.created_at DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	testimonials := []Testimonial{}
	for rows.Next() {
		var t Testimonial
		if err := rows.Scan(&t.ID, &t.PatientName, &t.DoctorName, &t.PhotoURL, &t.Rating, &t.Quote); err != nil {
			return nil, err
		}
		testimonials = append(testimonials, t)
	}
	return testimonials, rows.Err()
}

func (r *Repository) CreateTestimonial(ctx context.Context, in TestimonialInput) (Testimonial, error) {
	var id string
	err := r.pool.QueryRow(ctx, `
		INSERT INTO content.testimonials (patient_name, staff_id, photo_url, rating, quote)
		VALUES ($1, $2, $3, $4, $5) RETURNING id`,
		in.PatientName, in.StaffID, in.PhotoURL, in.Rating, in.Quote,
	).Scan(&id)
	if err != nil {
		return Testimonial{}, err
	}
	return r.getTestimonial(ctx, id)
}

func (r *Repository) UpdateTestimonial(ctx context.Context, id string, in TestimonialInput) (Testimonial, error) {
	tag, err := r.pool.Exec(ctx, `
		UPDATE content.testimonials SET patient_name = $1, staff_id = $2, photo_url = $3, rating = $4, quote = $5
		WHERE id = $6`,
		in.PatientName, in.StaffID, in.PhotoURL, in.Rating, in.Quote, id)
	if err != nil {
		return Testimonial{}, err
	}
	if tag.RowsAffected() == 0 {
		return Testimonial{}, dberr.ErrNotFound
	}
	return r.getTestimonial(ctx, id)
}

func (r *Repository) getTestimonial(ctx context.Context, id string) (Testimonial, error) {
	var t Testimonial
	err := r.pool.QueryRow(ctx, `
		SELECT t.id, t.patient_name, su.full_name, t.photo_url, t.rating, t.quote
		FROM content.testimonials t
		LEFT JOIN identity.staff s ON s.id = t.staff_id
		LEFT JOIN identity.users su ON su.id = s.user_id
		WHERE t.id = $1`, id,
	).Scan(&t.ID, &t.PatientName, &t.DoctorName, &t.PhotoURL, &t.Rating, &t.Quote)
	return t, err
}

func (r *Repository) DeleteTestimonial(ctx context.Context, id string) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM content.testimonials WHERE id = $1`, id)
	return err
}

// --- Videos ---

func (r *Repository) ListVideos(ctx context.Context) ([]Video, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT id, title, video_url, thumbnail_url, published_at
		FROM content.videos ORDER BY published_at DESC NULLS LAST`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	videos := []Video{}
	for rows.Next() {
		var v Video
		if err := rows.Scan(&v.ID, &v.Title, &v.VideoURL, &v.ThumbnailURL, &v.PublishedAt); err != nil {
			return nil, err
		}
		videos = append(videos, v)
	}
	return videos, rows.Err()
}

func (r *Repository) CreateVideo(ctx context.Context, in VideoInput) (Video, error) {
	var v Video
	err := r.pool.QueryRow(ctx, `
		INSERT INTO content.videos (title, video_url, thumbnail_url, published_at)
		VALUES ($1, $2, $3, CASE WHEN $4 THEN now() ELSE NULL END)
		RETURNING id, title, video_url, thumbnail_url, published_at`,
		in.Title, in.VideoURL, in.ThumbnailURL, in.Published,
	).Scan(&v.ID, &v.Title, &v.VideoURL, &v.ThumbnailURL, &v.PublishedAt)
	return v, err
}

func (r *Repository) DeleteVideo(ctx context.Context, id string) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM content.videos WHERE id = $1`, id)
	return err
}
