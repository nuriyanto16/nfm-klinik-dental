package activitylog

import (
	"fmt"
	"strings"
	"sync"
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

type Handler struct {
	mu   sync.RWMutex
	logs []ActivityLogItem
}

func NewHandler() *Handler {
	emailStr := "siti.aminah@ninadental.com"
	budiEmail := "budi.santoso@gmail.com"
	dewiEmail := "dewi.lestari@gmail.com"
	nuriyantoEmail := "nuriyanto@gmail.com"

	initial := []ActivityLogItem{
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
			CreatedAt:   time.Now().Add(-2 * time.Hour).Format(time.RFC3339),
		},
		{
			ID:          "log-1002",
			Scope:       "mobile",
			Category:    "booking",
			Action:      "CREATE_RESERVATION",
			Description: "Pasien Nuriyanto membuat reservasi perawatan Tambal Komposit & Perawatan Gigi",
			UserName:    "Nuriyanto",
			UserRole:    "Pasien Mobile",
			UserEmail:   &nuriyantoEmail,
			IPAddress:   "114.124.201.89",
			UserAgent:   "NinaDentalMobile/1.2.0 (Android 14; Mobile)",
			Status:      "SUCCESS",
			Severity:    "INFO",
			Details:     map[string]interface{}{"reservationId": "NDC-0099", "doctor": "drg. Nina Marlina, Sp.KG"},
			CreatedAt:   time.Now().Add(-1*time.Hour - 30*time.Minute).Format(time.RFC3339),
		},
		{
			ID:          "log-1003",
			Scope:       "mobile",
			Category:    "payment",
			Action:      "SUBMIT_PAYMENT",
			Description: "Pasien Nuriyanto melakukan pembayaran DP via QRIS Midtrans",
			UserName:    "Nuriyanto",
			UserRole:    "Pasien Mobile",
			UserEmail:   &nuriyantoEmail,
			IPAddress:   "114.124.201.89",
			UserAgent:   "NinaDentalMobile/1.2.0 (Android 14; Mobile)",
			Status:      "SUCCESS",
			Severity:    "INFO",
			Details:     map[string]interface{}{"paymentId": "pay-881902", "method": "QRIS", "amount": 100000, "status": "LUNAS"},
			CreatedAt:   time.Now().Add(-1 * time.Hour).Format(time.RFC3339),
		},
		{
			ID:          "log-1004",
			Scope:       "admin",
			Category:    "medical",
			Action:      "CREATE_MEDICAL_RECORD",
			Description: "Dokter drg. Nina Marlina menginput Rekam Medis & Odontogram pasien #RM-2026-0099",
			UserName:    "drg. Nina Marlina, Sp.KG",
			UserRole:    "Dokter Spesialis",
			UserEmail:   &emailStr,
			IPAddress:   "180.252.12.44",
			UserAgent:   "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/127.0.0.0",
			Status:      "SUCCESS",
			Severity:    "INFO",
			Details:     map[string]interface{}{"rmNumber": "RM-2026-0099", "diagnosis": "Nekrosis pulpa gigi 46"},
			CreatedAt:   time.Now().Add(-45 * time.Minute).Format(time.RFC3339),
		},
		{
			ID:          "log-1005",
			Scope:       "mobile",
			Category:    "auth",
			Action:      "MOBILE_LOGIN_SUCCESS",
			Description: "Pasien Budi Santoso berhasil masuk ke aplikasi mobile",
			UserName:    "Budi Santoso",
			UserRole:    "Pasien Mobile",
			UserEmail:   &budiEmail,
			IPAddress:   "180.244.110.12",
			UserAgent:   "NinaDentalMobile/1.2.0 (iOS 17.5; iPhone)",
			Status:      "SUCCESS",
			Severity:    "INFO",
			Details:     map[string]interface{}{"loginAt": time.Now().Add(-30 * time.Minute).Format(time.RFC3339)},
			CreatedAt:   time.Now().Add(-30 * time.Minute).Format(time.RFC3339),
		},
		{
			ID:          "log-1006",
			Scope:       "mobile",
			Category:    "auth",
			Action:      "FAILED_LOGIN_ATTEMPT",
			Description: "Percobaan masuk aplikasi mobile gagal: Kata sandi tidak cocok",
			UserName:    "Dewi Lestari",
			UserRole:    "Pasien Mobile",
			UserEmail:   &dewiEmail,
			IPAddress:   "180.244.110.12",
			UserAgent:   "NinaDentalMobile/1.2.0 (iOS 17.5; iPhone)",
			Status:      "FAILED",
			Severity:    "WARNING",
			Details:     map[string]interface{}{"attemptCount": 2, "reason": "INVALID_CREDENTIALS"},
			CreatedAt:   time.Now().Add(-15 * time.Minute).Format(time.RFC3339),
		},
	}

	return &Handler{
		logs: initial,
	}
}

func (h *Handler) RegisterRoutes(router fiber.Router) {
	router.Get("/activity-logs", h.listActivityLogs)
	router.Post("/activity-logs", h.createActivityLog)
}

func (h *Handler) listActivityLogs(c *fiber.Ctx) error {
	h.mu.RLock()
	defer h.mu.RUnlock()

	scope := c.Query("scope")
	category := c.Query("category")
	severity := c.Query("severity")
	search := strings.ToLower(strings.TrimSpace(c.Query("search")))

	var filtered []ActivityLogItem
	for _, l := range h.logs {
		if scope != "" && scope != "all" && l.Scope != scope {
			continue
		}
		if category != "" && category != "all" && l.Category != category {
			continue
		}
		if severity != "" && severity != "all" && l.Severity != severity {
			continue
		}
		if search != "" {
			email := ""
			if l.UserEmail != nil {
				email = *l.UserEmail
			}
			matchName := strings.Contains(strings.ToLower(l.UserName), search)
			matchEmail := strings.Contains(strings.ToLower(email), search)
			matchDesc := strings.Contains(strings.ToLower(l.Description), search)
			matchAction := strings.Contains(strings.ToLower(l.Action), search)
			if !matchName && !matchEmail && !matchDesc && !matchAction {
				continue
			}
		}
		filtered = append(filtered, l)
	}

	if filtered == nil {
		filtered = []ActivityLogItem{}
	}

	return c.JSON(filtered)
}

func (h *Handler) createActivityLog(c *fiber.Ctx) error {
	var in ActivityLogItem
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid log body")
	}

	h.mu.Lock()
	defer h.mu.Unlock()

	if in.ID == "" {
		in.ID = fmt.Sprintf("log-%d", time.Now().UnixNano())
	}
	if in.CreatedAt == "" {
		in.CreatedAt = time.Now().Format(time.RFC3339)
	}
	if in.IPAddress == "" {
		in.IPAddress = c.IP()
	}
	if in.UserAgent == "" {
		in.UserAgent = string(c.Request().Header.UserAgent())
	}
	if in.Status == "" {
		in.Status = "SUCCESS"
	}
	if in.Severity == "" {
		in.Severity = "INFO"
	}
	if in.Scope == "" {
		in.Scope = "mobile"
	}

	// Prepend to top of logs list (most recent first)
	h.logs = append([]ActivityLogItem{in}, h.logs...)

	return c.Status(fiber.StatusCreated).JSON(in)
}
