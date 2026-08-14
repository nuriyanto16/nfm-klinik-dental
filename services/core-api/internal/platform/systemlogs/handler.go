package systemlogs

import (
	"os"
	"path/filepath"
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/nina-dental-care/core-api/internal/platform/apperr"
)

type Handler struct{}

func NewHandler() *Handler {
	return &Handler{}
}

func (h *Handler) RegisterRoutes(router fiber.Router) {
	group := router.Group("/system/logs")
	group.Get("/", h.GetLogs)
}

func (h *Handler) GetLogs(c *fiber.Ctx) error {
	logPath := filepath.Join("logs", "app-error.log")

	data, err := os.ReadFile(logPath)
	if err != nil {
		if os.IsNotExist(err) {
			return c.JSON(fiber.Map{"logs": []string{}})
		}
		return apperr.Internal(c, err)
	}

	lines := strings.Split(string(data), "\n")
	
	// Remove trailing empty line if it exists
	if len(lines) > 0 && lines[len(lines)-1] == "" {
		lines = lines[:len(lines)-1]
	}

	// Reverse to show latest logs first (optional, but good for UI)
	for i, j := 0, len(lines)-1; i < j; i, j = i+1, j-1 {
		lines[i], lines[j] = lines[j], lines[i]
	}

	// Limit to the last 1000 lines for safety to prevent huge payloads
	if len(lines) > 1000 {
		lines = lines[:1000]
	}

	return c.JSON(fiber.Map{"logs": lines})
}
