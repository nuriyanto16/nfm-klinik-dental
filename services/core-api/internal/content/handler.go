package content

import (
	"errors"

	"github.com/gofiber/fiber/v2"

	"github.com/nina-dental-care/core-api/internal/platform/apperr"
	"github.com/nina-dental-care/core-api/internal/platform/dberr"
)

type Handler struct {
	repo *Repository
}

func NewHandler(repo *Repository) *Handler {
	return &Handler{repo: repo}
}

// RegisterRoutes wires up this domain's endpoints (CMS).
//
// NOTE: unauthenticated for now — see docs/architecture.md §5, auth/RBAC
// lands in Fase 1. Cover/banner/photo/thumbnail fields are plain URLs (no
// upload) since object storage is deferred — see docs/architecture.md §2.
func (h *Handler) RegisterRoutes(router fiber.Router) {
	router.Get("/content/article-categories", h.listArticleCategories)
	router.Post("/content/article-categories", h.createArticleCategory)

	router.Get("/content/articles", h.listArticles)
	router.Post("/content/articles", h.createArticle)
	router.Put("/content/articles/:id", h.updateArticle)
	router.Delete("/content/articles/:id", h.deleteArticle)

	router.Get("/content/promos", h.listPromos)
	router.Post("/content/promos", h.createPromo)
	router.Put("/content/promos/:id", h.updatePromo)
	router.Delete("/content/promos/:id", h.deletePromo)

	router.Get("/content/testimonials", h.listTestimonials)
	router.Post("/content/testimonials", h.createTestimonial)
	router.Put("/content/testimonials/:id", h.updateTestimonial)
	router.Delete("/content/testimonials/:id", h.deleteTestimonial)

	router.Get("/content/videos", h.listVideos)
	router.Post("/content/videos", h.createVideo)
	router.Delete("/content/videos/:id", h.deleteVideo)

	router.Get("/notifications/templates", h.listNotificationTemplates)
	router.Post("/notifications/templates", h.createNotificationTemplate)
	router.Put("/notifications/templates/:id", h.updateNotificationTemplate)
	router.Delete("/notifications/templates/:id", h.deleteNotificationTemplate)
	router.Get("/notifications/logs", h.listNotificationLogs)
	router.Post("/notifications/send", h.sendNotification)

	// App version check — public, no auth required (mobile app calls this on startup)
	router.Get("/app/version", h.getLatestAppVersion)
}

// RegisterAppAdminRoutes registers admin-only version management endpoints.
func (h *Handler) RegisterAppAdminRoutes(admin fiber.Router) {
	admin.Get("/app/versions", h.listAppVersions)
	admin.Post("/app/versions", h.createAppVersion)
}

func (h *Handler) listNotificationTemplates(c *fiber.Ctx) error {
	templates, err := h.repo.ListNotificationTemplates(c.Context())
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(templates)
}

func (h *Handler) createNotificationTemplate(c *fiber.Ctx) error {
	var in NotificationTemplateInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	if in.Code == "" || in.Channel == "" || in.Body == "" {
		return fiber.NewError(fiber.StatusBadRequest, "code, channel and body are required")
	}
	template, err := h.repo.CreateNotificationTemplate(c.Context(), in)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.Status(fiber.StatusCreated).JSON(template)
}

func (h *Handler) updateNotificationTemplate(c *fiber.Ctx) error {
	var in NotificationTemplateInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	template, err := h.repo.UpdateNotificationTemplate(c.Context(), c.Params("id"), in)
	if errors.Is(err, dberr.ErrNotFound) {
		return fiber.NewError(fiber.StatusNotFound, "template not found")
	}
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(template)
}

func (h *Handler) deleteNotificationTemplate(c *fiber.Ctx) error {
	if err := h.repo.DeleteNotificationTemplate(c.Context(), c.Params("id")); err != nil {
		return apperr.Internal(c, err)
	}
	return c.SendStatus(fiber.StatusNoContent)
}

func (h *Handler) listNotificationLogs(c *fiber.Ctx) error {
	logs, err := h.repo.ListNotificationLogs(c.Context())
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(logs)
}

func (h *Handler) sendNotification(c *fiber.Ctx) error {
	var in SendNotificationInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	if in.TemplateCode == "" || in.Recipient == "" {
		return fiber.NewError(fiber.StatusBadRequest, "templateCode and recipient are required")
	}
	log, err := h.repo.SendNotification(c.Context(), in)
	if errors.Is(err, ErrTemplateNotFound) {
		return fiber.NewError(fiber.StatusNotFound, "template not found")
	}
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.Status(fiber.StatusCreated).JSON(log)
}

func (h *Handler) listArticleCategories(c *fiber.Ctx) error {
	categories, err := h.repo.ListArticleCategories(c.Context())
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(categories)
}

func (h *Handler) createArticleCategory(c *fiber.Ctx) error {
	var body struct {
		Name string `json:"name"`
	}
	if err := c.BodyParser(&body); err != nil || body.Name == "" {
		return fiber.NewError(fiber.StatusBadRequest, "name is required")
	}
	category, err := h.repo.CreateArticleCategory(c.Context(), body.Name)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.Status(fiber.StatusCreated).JSON(category)
}

func (h *Handler) listArticles(c *fiber.Ctx) error {
	articles, err := h.repo.ListArticles(c.Context())
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(articles)
}

func (h *Handler) createArticle(c *fiber.Ctx) error {
	var in ArticleInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	if in.Title == "" || in.Slug == "" {
		return fiber.NewError(fiber.StatusBadRequest, "title and slug are required")
	}
	article, err := h.repo.CreateArticle(c.Context(), in)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.Status(fiber.StatusCreated).JSON(article)
}

func (h *Handler) updateArticle(c *fiber.Ctx) error {
	var in ArticleInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	article, err := h.repo.UpdateArticle(c.Context(), c.Params("id"), in)
	if errors.Is(err, dberr.ErrNotFound) {
		return fiber.NewError(fiber.StatusNotFound, "article not found")
	}
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(article)
}

func (h *Handler) deleteArticle(c *fiber.Ctx) error {
	if err := h.repo.DeleteArticle(c.Context(), c.Params("id")); err != nil {
		return apperr.Internal(c, err)
	}
	return c.SendStatus(fiber.StatusNoContent)
}

func (h *Handler) listPromos(c *fiber.Ctx) error {
	promos, err := h.repo.ListPromos(c.Context())
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(promos)
}

func (h *Handler) createPromo(c *fiber.Ctx) error {
	var in PromoInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	if in.Title == "" {
		return fiber.NewError(fiber.StatusBadRequest, "title is required")
	}
	promo, err := h.repo.CreatePromo(c.Context(), in)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.Status(fiber.StatusCreated).JSON(promo)
}

func (h *Handler) updatePromo(c *fiber.Ctx) error {
	var in PromoInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	promo, err := h.repo.UpdatePromo(c.Context(), c.Params("id"), in)
	if errors.Is(err, dberr.ErrNotFound) {
		return fiber.NewError(fiber.StatusNotFound, "promo not found")
	}
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(promo)
}

func (h *Handler) deletePromo(c *fiber.Ctx) error {
	if err := h.repo.DeletePromo(c.Context(), c.Params("id")); err != nil {
		return apperr.Internal(c, err)
	}
	return c.SendStatus(fiber.StatusNoContent)
}

func (h *Handler) listTestimonials(c *fiber.Ctx) error {
	testimonials, err := h.repo.ListTestimonials(c.Context())
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(testimonials)
}

func (h *Handler) createTestimonial(c *fiber.Ctx) error {
	var in TestimonialInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	if in.PatientName == "" || in.Quote == "" || in.Rating < 1 || in.Rating > 5 {
		return fiber.NewError(fiber.StatusBadRequest, "patientName, quote, and rating (1-5) are required")
	}
	testimonial, err := h.repo.CreateTestimonial(c.Context(), in)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.Status(fiber.StatusCreated).JSON(testimonial)
}

func (h *Handler) updateTestimonial(c *fiber.Ctx) error {
	var in TestimonialInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	testimonial, err := h.repo.UpdateTestimonial(c.Context(), c.Params("id"), in)
	if errors.Is(err, dberr.ErrNotFound) {
		return fiber.NewError(fiber.StatusNotFound, "testimonial not found")
	}
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(testimonial)
}

func (h *Handler) deleteTestimonial(c *fiber.Ctx) error {
	if err := h.repo.DeleteTestimonial(c.Context(), c.Params("id")); err != nil {
		return apperr.Internal(c, err)
	}
	return c.SendStatus(fiber.StatusNoContent)
}

func (h *Handler) listVideos(c *fiber.Ctx) error {
	videos, err := h.repo.ListVideos(c.Context())
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(videos)
}

func (h *Handler) createVideo(c *fiber.Ctx) error {
	var in VideoInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	if in.Title == "" || in.VideoURL == "" {
		return fiber.NewError(fiber.StatusBadRequest, "title and videoUrl are required")
	}
	video, err := h.repo.CreateVideo(c.Context(), in)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.Status(fiber.StatusCreated).JSON(video)
}

func (h *Handler) deleteVideo(c *fiber.Ctx) error {
	if err := h.repo.DeleteVideo(c.Context(), c.Params("id")); err != nil {
		return apperr.Internal(c, err)
	}
	return c.SendStatus(fiber.StatusNoContent)
}

// --- App Version handlers ---

// getLatestAppVersion returns the latest released version for the requested platform.
// Query param: platform=android (default) | ios
// This endpoint is public — called by the Flutter app on startup without auth.
func (h *Handler) getLatestAppVersion(c *fiber.Ctx) error {
	platform := c.Query("platform", "android")
	v, err := h.repo.GetLatestAppVersion(c.Context(), platform)
	if err != nil {
		// No version published yet — return 404 so the client knows there's nothing to compare.
		return fiber.NewError(fiber.StatusNotFound, "no app version published yet")
	}
	return c.JSON(v)
}

// listAppVersions returns all recorded versions for a platform (admin use).
func (h *Handler) listAppVersions(c *fiber.Ctx) error {
	platform := c.Query("platform", "android")
	versions, err := h.repo.ListAppVersions(c.Context(), platform)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(versions)
}

// createAppVersion publishes a new app version (admin only).
// Body: { platform, versionName, versionCode, downloadUrl, releaseNotes, isMandatory }
func (h *Handler) createAppVersion(c *fiber.Ctx) error {
	var in AppVersionInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	if in.VersionName == "" || in.VersionCode <= 0 || in.DownloadURL == "" {
		return fiber.NewError(fiber.StatusBadRequest, "versionName, versionCode, and downloadUrl are required")
	}
	v, err := h.repo.CreateAppVersion(c.Context(), in)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.Status(fiber.StatusCreated).JSON(v)
}
