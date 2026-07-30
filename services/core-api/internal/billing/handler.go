package billing

import (
	"errors"

	"github.com/gofiber/fiber/v2"

	"github.com/nina-dental-care/core-api/internal/platform/apperr"
	"github.com/nina-dental-care/core-api/internal/platform/dberr"
	"github.com/nina-dental-care/core-api/internal/platform/pagination"
)

type Handler struct {
	repo *Repository
}

func NewHandler(repo *Repository) *Handler {
	return &Handler{repo: repo}
}

// RegisterRoutes wires up this domain's endpoints.
//
// NOTE: unauthenticated for now — see docs/architecture.md §5, auth/RBAC
// lands in Fase 1.
func (h *Handler) RegisterRoutes(router fiber.Router) {
	router.Get("/treatments", h.listTreatments)
	router.Post("/treatments", h.createTreatment)
	router.Put("/treatments/:id", h.updateTreatment)
	router.Delete("/treatments/:id", h.deleteTreatment)
	router.Get("/treatments/stats", h.treatmentStats)
	router.Get("/treatment-categories", h.listTreatmentCategories)
	router.Post("/treatment-categories", h.createTreatmentCategory)
	router.Get("/payments", h.listPayments)
	router.Post("/payments", h.createPayment)
	router.Get("/payments/:id/invoice", h.getInvoice)

	router.Get("/inventory", h.listInventoryItems)
	router.Post("/inventory", h.createInventoryItem)
	router.Put("/inventory/:id", h.updateInventoryItem)
	router.Delete("/inventory/:id", h.deleteInventoryItem)

	router.Get("/expenses", h.listExpenses)
	router.Post("/expenses", h.createExpense)
	router.Put("/expenses/:id", h.updateExpense)
	router.Delete("/expenses/:id", h.deleteExpense)
}

// RegisterAdminRoutes wires up the /admin/* group (dashboard metrics,
// financial reports).
func (h *Handler) RegisterAdminRoutes(router fiber.Router) {
	router.Get("/dashboard", h.dashboardSummary)
	router.Get("/dashboard/revenue-trend", h.revenueTrend)
	router.Get("/dashboard/reservations-by-status", h.reservationsByStatus)
	router.Get("/dashboard/revenue-by-branch", h.revenueByBranch)
	router.Get("/dashboard/top-treatments", h.topTreatments)

	router.Get("/reports/summary", h.reportSummary)
	router.Get("/reports/revenue-trend", h.reportRevenueTrend)
	router.Get("/reports/by-payment-method", h.reportByPaymentMethod)
	router.Get("/reports/by-expense-category", h.reportByExpenseCategory)
	router.Get("/reports/commission", h.reportCommission)
	router.Get("/reports/profit", h.reportProfit)
}

func (h *Handler) listExpenses(c *fiber.Ctx) error {
	from, to := reportRange(c)
	expenses, err := h.repo.ListExpenses(c.Context(), from, to)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(expenses)
}

func (h *Handler) createExpense(c *fiber.Ctx) error {
	var in ExpenseInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	if in.Category == "" || in.Amount <= 0 || in.ExpenseDate == "" {
		return fiber.NewError(fiber.StatusBadRequest, "category, a positive amount and expenseDate are required")
	}
	expense, err := h.repo.CreateExpense(c.Context(), in)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.Status(fiber.StatusCreated).JSON(expense)
}

func (h *Handler) updateExpense(c *fiber.Ctx) error {
	var in ExpenseInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	expense, err := h.repo.UpdateExpense(c.Context(), c.Params("id"), in)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(expense)
}

func (h *Handler) deleteExpense(c *fiber.Ctx) error {
	if err := h.repo.DeleteExpense(c.Context(), c.Params("id")); err != nil {
		return apperr.Internal(c, err)
	}
	return c.SendStatus(fiber.StatusNoContent)
}

func (h *Handler) reportByExpenseCategory(c *fiber.Ctx) error {
	from, to := reportRange(c)
	totals, err := h.repo.ExpensesByCategory(c.Context(), from, to)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(totals)
}

func (h *Handler) reportCommission(c *fiber.Ctx) error {
	from, to := reportRange(c)
	rows, err := h.repo.CommissionByDoctor(c.Context(), from, to)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(rows)
}

func (h *Handler) reportProfit(c *fiber.Ctx) error {
	from, to := reportRange(c)
	profit, err := h.repo.GetProfitReport(c.Context(), from, to)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(profit)
}

func (h *Handler) listTreatments(c *fiber.Ctx) error {
	treatments, err := h.repo.ListTreatments(c.Context())
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(treatments)
}

func (h *Handler) createTreatment(c *fiber.Ctx) error {
	var in TreatmentInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	if in.CategoryID == "" || in.Name == "" || in.Price <= 0 {
		return fiber.NewError(fiber.StatusBadRequest, "categoryId, name and a positive price are required")
	}
	treatment, err := h.repo.CreateTreatment(c.Context(), in)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.Status(fiber.StatusCreated).JSON(treatment)
}

func (h *Handler) updateTreatment(c *fiber.Ctx) error {
	var in TreatmentInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	if in.CategoryID == "" || in.Name == "" || in.Price <= 0 {
		return fiber.NewError(fiber.StatusBadRequest, "categoryId, name and a positive price are required")
	}
	treatment, err := h.repo.UpdateTreatment(c.Context(), c.Params("id"), in)
	if errors.Is(err, dberr.ErrNotFound) {
		return fiber.NewError(fiber.StatusNotFound, "treatment not found")
	}
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(treatment)
}

func (h *Handler) deleteTreatment(c *fiber.Ctx) error {
	err := h.repo.DeleteTreatment(c.Context(), c.Params("id"))
	if errors.Is(err, ErrTreatmentInUse) {
		return fiber.NewError(fiber.StatusConflict, "perawatan sudah pernah dipesan, tidak bisa dihapus — nonaktifkan saja")
	}
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.SendStatus(fiber.StatusNoContent)
}

func (h *Handler) treatmentStats(c *fiber.Ctx) error {
	stats, err := h.repo.TreatmentStats(c.Context())
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(stats)
}

func (h *Handler) listTreatmentCategories(c *fiber.Ctx) error {
	categories, err := h.repo.ListTreatmentCategories(c.Context())
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(categories)
}

func (h *Handler) createTreatmentCategory(c *fiber.Ctx) error {
	var body struct {
		Name string `json:"name"`
	}
	if err := c.BodyParser(&body); err != nil || body.Name == "" {
		return fiber.NewError(fiber.StatusBadRequest, "name is required")
	}
	category, err := h.repo.CreateTreatmentCategory(c.Context(), body.Name)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.Status(fiber.StatusCreated).JSON(category)
}

func (h *Handler) listPayments(c *fiber.Ctx) error {
	page := pagination.FromQuery(c)
	payments, total, err := h.repo.ListPayments(c.Context(), c.Query("patientId"), page)
	if err != nil {
		return apperr.Internal(c, err)
	}
	if !page.Enabled {
		return c.JSON(payments)
	}
	return c.JSON(pagination.Wrap(payments, total, page))
}

func (h *Handler) createPayment(c *fiber.Ctx) error {
	var in CreatePaymentInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	if in.ReservationID == "" || in.Status == "" {
		return fiber.NewError(fiber.StatusBadRequest, "reservationId and status are required")
	}
	payment, err := h.repo.CreatePayment(c.Context(), in)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.Status(fiber.StatusCreated).JSON(payment)
}

func (h *Handler) getInvoice(c *fiber.Ctx) error {
	invoice, err := h.repo.GetInvoice(c.Context(), c.Params("id"))
	if errors.Is(err, dberr.ErrNotFound) {
		return fiber.NewError(fiber.StatusNotFound, "payment not found")
	}
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(invoice)
}

func (h *Handler) listInventoryItems(c *fiber.Ctx) error {
	page := pagination.FromQuery(c)
	items, total, err := h.repo.ListInventoryItems(c.Context(), page)
	if err != nil {
		return apperr.Internal(c, err)
	}
	if !page.Enabled {
		return c.JSON(items)
	}
	return c.JSON(pagination.Wrap(items, total, page))
}

func (h *Handler) createInventoryItem(c *fiber.Ctx) error {
	var in InventoryItemInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	if in.Name == "" || in.Category == "" {
		return fiber.NewError(fiber.StatusBadRequest, "name and category are required")
	}
	item, err := h.repo.CreateInventoryItem(c.Context(), in)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.Status(fiber.StatusCreated).JSON(item)
}

func (h *Handler) updateInventoryItem(c *fiber.Ctx) error {
	var in InventoryItemInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	item, err := h.repo.UpdateInventoryItem(c.Context(), c.Params("id"), in)
	if errors.Is(err, dberr.ErrNotFound) {
		return fiber.NewError(fiber.StatusNotFound, "inventory item not found")
	}
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(item)
}

func (h *Handler) deleteInventoryItem(c *fiber.Ctx) error {
	err := h.repo.DeleteInventoryItem(c.Context(), c.Params("id"))
	if errors.Is(err, ErrInventoryItemInUse) {
		return fiber.NewError(fiber.StatusConflict, "item sudah dipakai di riwayat rekam medis, tidak bisa dihapus")
	}
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.SendStatus(fiber.StatusNoContent)
}

func (h *Handler) dashboardSummary(c *fiber.Ctx) error {
	summary, err := h.repo.DashboardSummary(c.Context())
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(summary)
}

func (h *Handler) revenueTrend(c *fiber.Ctx) error {
	days := c.QueryInt("days", 7)
	if days < 1 || days > 90 {
		days = 7
	}
	trend, err := h.repo.RevenueTrend(c.Context(), days)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(trend)
}

func (h *Handler) reservationsByStatus(c *fiber.Ctx) error {
	counts, err := h.repo.ReservationsByStatus(c.Context())
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(counts)
}

func (h *Handler) revenueByBranch(c *fiber.Ctx) error {
	branches, err := h.repo.RevenueByBranch(c.Context())
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(branches)
}

func (h *Handler) topTreatments(c *fiber.Ctx) error {
	limit := c.QueryInt("limit", 5)
	if limit < 1 || limit > 50 {
		limit = 5
	}
	treatments, err := h.repo.TopTreatments(c.Context(), limit)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(treatments)
}

func reportRange(c *fiber.Ctx) (string, string) {
	from := c.Query("from")
	to := c.Query("to")
	if from == "" {
		from = "2000-01-01"
	}
	if to == "" {
		to = "2100-01-01"
	}
	return from, to
}

func (h *Handler) reportSummary(c *fiber.Ctx) error {
	from, to := reportRange(c)
	summary, err := h.repo.FinancialSummaryReport(c.Context(), from, to)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(summary)
}

func (h *Handler) reportRevenueTrend(c *fiber.Ctx) error {
	from, to := reportRange(c)
	trend, err := h.repo.RevenueTrendRange(c.Context(), from, to)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(trend)
}

func (h *Handler) reportByPaymentMethod(c *fiber.Ctx) error {
	from, to := reportRange(c)
	methods, err := h.repo.RevenueByPaymentMethod(c.Context(), from, to)
	if err != nil {
		return apperr.Internal(c, err)
	}
	return c.JSON(methods)
}
