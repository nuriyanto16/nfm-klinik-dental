package content

import "time"

// AppVersion represents a released app build that clients can update to.
type AppVersion struct {
	ID           int64      `json:"id"`
	Platform     string     `json:"platform"`     // "android" | "ios"
	VersionName  string     `json:"versionName"`  // semver string e.g. "1.1.0"
	VersionCode  int        `json:"versionCode"`  // monotonically increasing int
	DownloadURL  string     `json:"downloadUrl"`  // direct APK/IPA download link
	ReleaseNotes *string    `json:"releaseNotes"` // markdown changelog
	IsMandatory  bool       `json:"isMandatory"`  // force update if true
	CreatedAt    time.Time  `json:"createdAt"`
}

type AppVersionInput struct {
	Platform     string  `json:"platform"`
	VersionName  string  `json:"versionName"`
	VersionCode  int     `json:"versionCode"`
	DownloadURL  string  `json:"downloadUrl"`
	ReleaseNotes *string `json:"releaseNotes"`
	IsMandatory  bool    `json:"isMandatory"`
}

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

// NotificationTemplate/Log model the WA/push/email broadcast module. There's
// no real 3rd-party gateway wired up yet (see docs/architecture.md §7), so
// "sending" here writes a log row immediately as 'sent' — enough to build
// and demo the template/log management UI without an external dependency.
type NotificationTemplate struct {
	ID        string    `json:"id"`
	Code      string    `json:"code"`
	Channel   string    `json:"channel"`
	Subject   *string   `json:"subject"`
	Body      string    `json:"body"`
	UpdatedAt time.Time `json:"updatedAt"`
}

type NotificationTemplateInput struct {
	Code    string  `json:"code"`
	Channel string  `json:"channel"`
	Subject *string `json:"subject"`
	Body    string  `json:"body"`
}

type NotificationLog struct {
	ID           string    `json:"id"`
	TemplateCode string    `json:"templateCode"`
	Channel      string    `json:"channel"`
	Recipient    string    `json:"recipient"`
	Status       string    `json:"status"`
	ErrorMessage *string   `json:"errorMessage"`
	SentAt       time.Time `json:"sentAt"`
}

type SendNotificationInput struct {
	TemplateCode string `json:"templateCode"`
	Recipient    string `json:"recipient"`
}
