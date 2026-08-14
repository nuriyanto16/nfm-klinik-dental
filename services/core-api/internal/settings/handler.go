package settings

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

func (h *Handler) RegisterRoutes(router fiber.Router) {
	router.Get("/settings/public", h.getPublicSettings)
	router.Get("/admin/settings", h.getAdminSettings)
	router.Put("/admin/settings/:key", h.updateSetting)
}

func (h *Handler) getPublicSettings(c *fiber.Ctx) error {
	settings, err := h.repo.GetAll(c.Context())
	if err != nil {
		return apperr.Internal(c, err)
	}
	// Inject defaults if empty
	if _, ok := settings["brand_name"]; !ok {
		settings["brand_name"] = "Nina Dental Care"
	}
	return c.JSON(settings)
}

func (h *Handler) getAdminSettings(c *fiber.Ctx) error {
	settings, err := h.repo.GetList(c.Context())
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(settings)
}

func (h *Handler) updateSetting(c *fiber.Ctx) error {
	keyName := c.Params("key")
	var in UpdateSettingInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}

	setting, err := h.repo.Update(c.Context(), keyName, in)
	if errors.Is(err, dberr.ErrNotFound) {
		return fiber.NewError(fiber.StatusNotFound, "setting not found")
	}
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(setting)
}
