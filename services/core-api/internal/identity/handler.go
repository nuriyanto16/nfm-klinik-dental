package identity

import (
	"errors"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"

	"github.com/nina-dental-care/core-api/internal/platform/authtoken"
	"github.com/nina-dental-care/core-api/internal/platform/dberr"
)

type Handler struct {
	repo         *Repository
	jwtSecret    string
	jwtAccessTTL time.Duration
}

func NewHandler(repo *Repository, jwtSecret string, jwtAccessTTLMinutes int) *Handler {
	return &Handler{repo: repo, jwtSecret: jwtSecret, jwtAccessTTL: time.Duration(jwtAccessTTLMinutes) * time.Minute}
}

// RegisterRoutes wires up this domain's endpoints.
//
// NOTE: unauthenticated for now — see docs/architecture.md §5, full RBAC
// (protecting every route by role) lands in Fase 1. `auth/login` and
// `auth/me` below are the one exception already wired end-to-end, since the
// office panel needs a working login screen now.
func (h *Handler) RegisterRoutes(router fiber.Router) {
	router.Post("/auth/login", h.login)
	router.Get("/auth/me", h.me)

	router.Get("/patients", h.listPatients)
	router.Post("/patients", h.createPatient)
	router.Put("/patients/:id", h.updatePatient)
	router.Delete("/patients/:id", h.deletePatient)

	router.Get("/users", h.listUsers)
	router.Post("/users", h.createUser)
	router.Put("/users/:id", h.updateUser)
	router.Delete("/users/:id", h.deactivateUser)
	router.Get("/roles", h.listRoles)
}

func (h *Handler) login(c *fiber.Ctx) error {
	var body struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}
	if err := c.BodyParser(&body); err != nil || body.Email == "" || body.Password == "" {
		return fiber.NewError(fiber.StatusBadRequest, "email dan password wajib diisi")
	}

	user, err := h.repo.Authenticate(c.Context(), body.Email, body.Password)
	if errors.Is(err, ErrInvalidCredentials) {
		return fiber.NewError(fiber.StatusUnauthorized, "email atau password salah")
	}
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}

	token, err := authtoken.Generate(h.jwtSecret, h.jwtAccessTTL, user.ID, user.FullName, user.Role)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}

	return c.JSON(fiber.Map{"token": token, "user": user})
}

func (h *Handler) me(c *fiber.Ctx) error {
	authHeader := c.Get("Authorization")
	token, ok := strings.CutPrefix(authHeader, "Bearer ")
	if !ok || token == "" {
		return fiber.NewError(fiber.StatusUnauthorized, "missing bearer token")
	}

	claims, err := authtoken.Parse(h.jwtSecret, token)
	if err != nil {
		return fiber.NewError(fiber.StatusUnauthorized, "token tidak valid atau kedaluwarsa")
	}

	user, err := h.repo.GetAuthUser(c.Context(), claims.UserID)
	if errors.Is(err, ErrInvalidCredentials) {
		return fiber.NewError(fiber.StatusUnauthorized, "akun tidak ditemukan atau nonaktif")
	}
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(user)
}

func (h *Handler) listPatients(c *fiber.Ctx) error {
	patients, err := h.repo.ListPatients(c.Context())
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(patients)
}

func (h *Handler) createPatient(c *fiber.Ctx) error {
	var in CreatePatientInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	if in.FullName == "" || in.Relation == "" {
		return fiber.NewError(fiber.StatusBadRequest, "fullName and relation are required")
	}
	patient, err := h.repo.CreatePatient(c.Context(), in)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.Status(fiber.StatusCreated).JSON(patient)
}

func (h *Handler) updatePatient(c *fiber.Ctx) error {
	var in UpdatePatientInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	patient, err := h.repo.UpdatePatient(c.Context(), c.Params("id"), in)
	if errors.Is(err, dberr.ErrNotFound) {
		return fiber.NewError(fiber.StatusNotFound, "patient not found")
	}
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(patient)
}

func (h *Handler) deletePatient(c *fiber.Ctx) error {
	err := h.repo.DeletePatient(c.Context(), c.Params("id"))
	if errors.Is(err, ErrPatientInUse) {
		return fiber.NewError(fiber.StatusConflict, "pasien memiliki riwayat reservasi/pembayaran, tidak bisa dihapus")
	}
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.SendStatus(fiber.StatusNoContent)
}

func (h *Handler) listUsers(c *fiber.Ctx) error {
	users, err := h.repo.ListUsers(c.Context())
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(users)
}

func (h *Handler) listRoles(c *fiber.Ctx) error {
	return c.JSON(StaffRoles)
}

func (h *Handler) createUser(c *fiber.Ctx) error {
	var in CreateUserInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	if in.FullName == "" || in.Email == "" || in.Password == "" || in.Role == "" {
		return fiber.NewError(fiber.StatusBadRequest, "fullName, email, password and role are required")
	}
	if len(in.Password) < 8 {
		return fiber.NewError(fiber.StatusBadRequest, "password minimal 8 karakter")
	}
	user, err := h.repo.CreateUser(c.Context(), in)
	if errors.Is(err, ErrEmailInUse) {
		return fiber.NewError(fiber.StatusConflict, "email sudah dipakai")
	}
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.Status(fiber.StatusCreated).JSON(user)
}

func (h *Handler) updateUser(c *fiber.Ctx) error {
	var in UpdateUserInput
	if err := c.BodyParser(&in); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
	}
	user, err := h.repo.UpdateUser(c.Context(), c.Params("id"), in)
	if errors.Is(err, dberr.ErrNotFound) {
		return fiber.NewError(fiber.StatusNotFound, "user not found")
	}
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(user)
}

func (h *Handler) deactivateUser(c *fiber.Ctx) error {
	err := h.repo.DeactivateUser(c.Context(), c.Params("id"))
	if errors.Is(err, dberr.ErrNotFound) {
		return fiber.NewError(fiber.StatusNotFound, "user not found")
	}
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.SendStatus(fiber.StatusNoContent)
}
