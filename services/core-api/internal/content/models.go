package content

import "time"

type ArticleCategory struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

type Article struct {
	ID            string     `json:"id"`
	CategoryID    *string    `json:"categoryId"`
	CategoryName  *string    `json:"categoryName"`
	Title         string     `json:"title"`
	Slug          string     `json:"slug"`
	CoverImageURL *string    `json:"coverImageUrl"`
	Body          string     `json:"body"`
	PublishedAt   *time.Time `json:"publishedAt"`
	CreatedAt     time.Time  `json:"createdAt"`
}

type ArticleInput struct {
	CategoryID    *string `json:"categoryId"`
	Title         string  `json:"title"`
	Slug          string  `json:"slug"`
	CoverImageURL *string `json:"coverImageUrl"`
	Body          string  `json:"body"`
	Published     bool    `json:"published"`
}

type Promo struct {
	ID             string     `json:"id"`
	Title          string     `json:"title"`
	BannerImageURL *string    `json:"bannerImageUrl"`
	Description    *string    `json:"description"`
	StartsAt       *time.Time `json:"startsAt"`
	EndsAt         *time.Time `json:"endsAt"`
	IsActive       bool       `json:"isActive"`
}

type PromoInput struct {
	Title          string  `json:"title"`
	BannerImageURL *string `json:"bannerImageUrl"`
	Description    *string `json:"description"`
	StartsAt       *string `json:"startsAt"`
	EndsAt         *string `json:"endsAt"`
	IsActive       bool    `json:"isActive"`
}

type Testimonial struct {
	ID          string  `json:"id"`
	PatientName string  `json:"patientName"`
	DoctorName  *string `json:"doctorName"`
	PhotoURL    *string `json:"photoUrl"`
	Rating      int16   `json:"rating"`
	Quote       string  `json:"quote"`
}

type TestimonialInput struct {
	PatientName string  `json:"patientName"`
	StaffID     *string `json:"staffId"`
	PhotoURL    *string `json:"photoUrl"`
	Rating      int16   `json:"rating"`
	Quote       string  `json:"quote"`
}

type Video struct {
	ID           string     `json:"id"`
	Title        string     `json:"title"`
	VideoURL     string     `json:"videoUrl"`
	ThumbnailURL *string    `json:"thumbnailUrl"`
	PublishedAt  *time.Time `json:"publishedAt"`
}

type VideoInput struct {
	Title        string  `json:"title"`
	VideoURL     string  `json:"videoUrl"`
	ThumbnailURL *string `json:"thumbnailUrl"`
	Published    bool    `json:"published"`
}
