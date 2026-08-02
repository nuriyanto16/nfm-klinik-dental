package activitylog

import (
	"time"

	"github.com/gofiber/fiber/v2"
)

type ActivityLogItem struct {
	ID          string                 `json:"id"`
	Scope       string                 `json:"scope"`
	Category    string                 `json:"category"`
	Action      string                 `json:"action"`
	Description string                 `json:"description"`
	UserName    string                 `json:"userName"`
	UserRole    string                 `json:"userRole"`
	UserEmail   *string                `json:"userEmail"`
	IPAddress   string                 `json:"ipAddress"`
	UserAgent   string                 `json:"userAgent"`
	Status      string                 `json:"status"`
	Severity    string                 `json:"severity"`
	Details     map[string]interface{} `json:"details,omitempty"`
	CreatedAt   string                 `json:"createdAt"`
}

type Handler struct{}

func NewHandler() *Handler {
	return &Handler{}
}

func (h *Handler) RegisterRoutes(router fiber.Router) {
	router.Get("/activity-logs", h.listActivityLogs)
	router.Post("/activity-logs", h.createActivityLog)
}

func (h *Handler) listActivityLogs(c *fiber.Ctx) error {
	emailStr := "siti.aminah@ninadental.com"
	budiEmail := "budi.santoso@gmail.com"

	logs := []ActivityLogItem{
		{
			ID:          "log-1001",
			Scope:       "admin",
			Category:    "auth",
			Action:      "ADMIN_LOGIN_SUCCESS",
			Description: "Admin drg. Siti Aminah berhasil masuk ke Panel Admin",
			UserName:    "drg. Siti Aminah",
			UserRole:    "Super Admin",
			UserEmail:   &emailStr,
			IPAddress:   "180.252.12.44",
			UserAgent:   "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/127.0.0.0",
			Status:      "SUCCESS",
			Severity:    "INFO",
			Details:     map[string]interface{}{"method": "JWT_BEARER", "location": "Bandung, Indonesia"},
			CreatedAt:   time.Now().Add(-1 * time.Hour).Format(time.RFC3339),
		},
		{
			ID:          "log-1002",
			Scope:       "mobile",
			Category:    "booking",
			Action:      "CREATE_RESERVATION",
			Description: "Pasien Budi Santoso membuat reservasi perawatan Scaling 6-in-1",
			UserName:    "Budi Santoso",
			UserRole:    "Pasien Mobile",
			UserEmail:   &budiEmail,
			IPAddress:   "114.124.201.89",
			UserAgent:   "NinaDentalMobile/1.2.0 (Android 14; Mobile)",
			Status:      "SUCCESS",
			Severity:    "INFO",
			Details:     map[string]interface{}{"reservationId": "res-51000000-0001", "doctor": "drg. Siti Aminah"},
			CreatedAt:   time.Now().Add(-45 * time.Minute).Format(time.RFC3339),
		},
	}

	scope := c.Query("scope")
	if scope != "" && scope != "all" {
		var filtered []ActivityLogItem
		for _, l := range logs {
			if l.Scope == scope {
				filtered = append(filtered, l)
			}
		}
		return c.JSON(filtered)
	}

	return c.JSON(logs)
}

func (h *Handler) createActivityLog(c *fiber.Ctx) error {
	var in ActivityLogItem
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid log body")
	}
	in.ID = "log-" + time.Now().Format("20060102150405")
	in.CreatedAt = time.Now().Format(time.RFC3339)
	return c.Status(fiber.StatusCreated).JSON(in)
}
