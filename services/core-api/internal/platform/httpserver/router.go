package httpserver

import (
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/helmet"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/gofiber/fiber/v2/middleware/requestid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/nina-dental-care/core-api/internal/billing"
	"github.com/nina-dental-care/core-api/internal/clinical"
	"github.com/nina-dental-care/core-api/internal/content"
	"github.com/nina-dental-care/core-api/internal/identity"
	"github.com/nina-dental-care/core-api/internal/platform/activitylog"
	"github.com/nina-dental-care/core-api/internal/scheduling"
)

type Dependencies struct {
	AppEnv              string
	DB                  *pgxpool.Pool
	JWTAccessSecret     string
	JWTAccessTTLMinutes int
	AllowedOrigins      string
}

func New(deps Dependencies) *fiber.App {
	app := fiber.New(fiber.Config{
		AppName:               "core-api",
		DisableStartupMessage: deps.AppEnv != "development",
	})

	app.Use(recover.New())
	app.Use(requestid.New())
	app.Use(helmet.New())
	// Native clients (the Flutter app) aren't subject to CORS at all — this
	// allowlist only matters for the browser-based admin panel, which is
	// exactly why it must be a real allowlist and never "*" on an API that
	// hands out JWTs.
	app.Use(cors.New(cors.Config{
		AllowOrigins: deps.AllowedOrigins,
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
		AllowMethods: "GET, POST, PUT, PATCH, DELETE, OPTIONS",
	}))

	app.Get("/healthz", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"status": "ok", "service": "core-api"})
	})

	api := app.Group("/api/v1")

	identityHandler := identity.NewHandler(identity.NewRepository(deps.DB), deps.JWTAccessSecret, deps.JWTAccessTTLMinutes)
	identityHandler.RegisterRoutes(api)

	schedulingHandler := scheduling.NewHandler(scheduling.NewRepository(deps.DB))
	schedulingHandler.RegisterRoutes(api)

	billingHandler := billing.NewHandler(billing.NewRepository(deps.DB))
	billingHandler.RegisterRoutes(api)
	billingHandler.RegisterAdminRoutes(api.Group("/admin"))

	clinicalHandler := clinical.NewHandler(clinical.NewRepository(deps.DB))
	clinicalHandler.RegisterRoutes(api)

	contentHandler := content.NewHandler(content.NewRepository(deps.DB))
	contentHandler.RegisterRoutes(api)
	contentHandler.RegisterAppAdminRoutes(api.Group("/admin"))

	activityLogHandler := activitylog.NewHandler()
	activityLogHandler.RegisterRoutes(api)

	// `auth/login` + `auth/me` are wired (see identity.Handler); the rest of
	// RBAC (protecting every other route by role) lands in Fase 1 — see
	// docs/architecture.md §5.
	api.Get("/", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"service": "core-api",
			"domains": []string{"auth", "branches", "doctors", "patients", "users", "treatments", "inventory", "reservations", "payments", "medical-records", "content", "admin"},
		})
	})

	return app
}
