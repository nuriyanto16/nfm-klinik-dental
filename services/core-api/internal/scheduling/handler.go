package scheduling

import (
	"errors"
	"slices"

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
// NOTE: unauthenticated for now — see docs/architecture.md §5, auth/RBAC
// lands in Fase 1.
func (h *Handler) RegisterRoutes(router fiber.Router) {
	router.Get("/branches", h.listBranches)

	router.Get("/doctors", h.listDoctors)
	router.Get("/doctors/admin", h.listDoctorsAdmin)
	router.Get("/doctors/:id", h.getDoctor)
	router.Post("/doctors", h.createDoctor)
	router.Put("/doctors/:id", h.updateDoctor)
	router.Delete("/doctors/:id", h.deactivateDoctor)

	router.Get("/reservations", h.listReservations)
	router.Post("/reservations", h.createReservation)
	router.Patch("/reservations/:id/status", h.updateReservationStatus)
	router.Get("/reservation-statuses", h.listReservationStatuses)
}

func (h *Handler) listBranches(c *fiber.Ctx) error {
	branches, err := h.repo.ListBranches(c.Context())
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(branches)
}

func (h *Handler) listDoctors(c *fiber.Ctx) error {
	doctors, err := h.repo.ListDoctors(c.Context())
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(doctors)
}

func (h *Handler) listDoctorsAdmin(c *fiber.Ctx) error {
	doctors, err := h.repo.ListDoctorsAdmin(c.Context())
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(doctors)
}

func (h *Handler) getDoctor(c *fiber.Ctx) error {
	doctor, err := h.repo.GetDoctor(c.Context(), c.Params("id"))
	if errors.Is(err, dberr.ErrNotFound) {
		return fiber.NewError(fiber.StatusNotFound, "doctor not found")
	}
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(doctor)
}

func (h *Handler) createDoctor(c *fiber.Ctx) error {
	var in CreateDoctorInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	if in.FullName == "" || in.Email == "" {
		return fiber.NewError(fiber.StatusBadRequest, "fullName and email are required")
	}
	doctor, err := h.repo.CreateDoctor(c.Context(), in)
	if errors.Is(err, ErrDoctorEmailInUse) {
		return fiber.NewError(fiber.StatusConflict, "email sudah dipakai")
	}
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.Status(fiber.StatusCreated).JSON(doctor)
}

func (h *Handler) updateDoctor(c *fiber.Ctx) error {
	var in UpdateDoctorInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	doctor, err := h.repo.UpdateDoctor(c.Context(), c.Params("id"), in)
	if errors.Is(err, dberr.ErrNotFound) {
		return fiber.NewError(fiber.StatusNotFound, "doctor not found")
	}
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(doctor)
}

func (h *Handler) deactivateDoctor(c *fiber.Ctx) error {
	err := h.repo.DeactivateDoctor(c.Context(), c.Params("id"))
	if errors.Is(err, dberr.ErrNotFound) {
		return fiber.NewError(fiber.StatusNotFound, "doctor not found")
	}
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.SendStatus(fiber.StatusNoContent)
}

func (h *Handler) listReservations(c *fiber.Ctx) error {
	filter := ReservationFilter{
		BranchID:  c.Query("branchId"),
		Status:    c.Query("status"),
		From:      c.Query("from"),
		To:        c.Query("to"),
		PatientID: c.Query("patientId"),
	}
	reservations, err := h.repo.ListReservations(c.Context(), filter)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(reservations)
}

func (h *Handler) createReservation(c *fiber.Ctx) error {
	var in CreateReservationInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	if in.PatientID == "" || in.BranchID == "" || in.StaffID == "" {
		return fiber.NewError(fiber.StatusBadRequest, "patientId, branchId and staffId are required")
	}
	if in.Status != "" && !slices.Contains(ReservationStatuses, in.Status) {
		return fiber.NewError(fiber.StatusBadRequest, "invalid status")
	}
	reservation, err := h.repo.CreateReservation(c.Context(), in)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.Status(fiber.StatusCreated).JSON(reservation)
}

func (h *Handler) updateReservationStatus(c *fiber.Ctx) error {
	var in UpdateReservationStatusInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	reservation, err := h.repo.UpdateReservationStatus(c.Context(), c.Params("id"), in.Status)
	if errors.Is(err, dberr.ErrNotFound) {
		return fiber.NewError(fiber.StatusNotFound, "reservation not found")
	}
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(reservation)
}

func (h *Handler) listReservationStatuses(c *fiber.Ctx) error {
	return c.JSON(ReservationStatuses)
}
