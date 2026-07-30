package clinical

import (
	"errors"

	"github.com/gofiber/fiber/v2"

	"github.com/nina-dental-care/core-api/internal/platform/dberr"
)

type Handler struct {
	repo *Repository
}

func NewHandler(repo *Repository) *Handler {
	return &Handler{repo: repo}
}

// RegisterRoutes wires up this domain's endpoints.
//
// NOTE: unauthenticated for now, and there is deliberately no PUT/DELETE —
// medical records are append-only. See docs/architecture.md §5; RBAC
// (dokter/perawat write, pasien read-only-own) lands with the auth domain
// in Fase 1.
func (h *Handler) RegisterRoutes(router fiber.Router) {
	router.Get("/medical-records", h.listMedicalRecords)
	router.Get("/medical-records/:id", h.getMedicalRecord)
	router.Post("/medical-records", h.createMedicalRecord)
}

func (h *Handler) listMedicalRecords(c *fiber.Ctx) error {
	records, err := h.repo.ListMedicalRecords(c.Context(), c.Query("patientId"))
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(records)
}

func (h *Handler) getMedicalRecord(c *fiber.Ctx) error {
	record, err := h.repo.GetMedicalRecord(c.Context(), c.Params("id"))
	if errors.Is(err, dberr.ErrNotFound) {
		return fiber.NewError(fiber.StatusNotFound, "medical record not found")
	}
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(record)
}

func (h *Handler) createMedicalRecord(c *fiber.Ctx) error {
	var in CreateMedicalRecordInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	if in.PatientID == "" || in.StaffID == "" {
		return fiber.NewError(fiber.StatusBadRequest, "patientId and staffId are required")
	}
	record, err := h.repo.CreateMedicalRecord(c.Context(), in)
	if errors.Is(err, ErrInsufficientStock) {
		return fiber.NewError(fiber.StatusConflict, "stok alat/obat tidak cukup")
	}
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.Status(fiber.StatusCreated).JSON(record)
}
