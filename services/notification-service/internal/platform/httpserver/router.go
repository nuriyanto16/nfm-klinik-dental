package httpserver

import (
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/gofiber/fiber/v2/middleware/requestid"
)

type Dependencies struct {
	AppEnv string
}

func New(deps Dependencies) *fiber.App {
	app := fiber.New(fiber.Config{
		AppName:               "notification-service",
		DisableStartupMessage: deps.AppEnv != "development",
	})

	app.Use(recover.New())
	app.Use(requestid.New())
	app.Use(cors.New())

	app.Get("/healthz", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"status": "ok", "service": "notification-service"})
	})

	// Wired up once a WhatsAppGateway/PushGateway implementation lands:
	//   admin := app.Group("/internal/notifications")
	//   admin.Get("/templates", handlers.ListTemplates)
	//   admin.Put("/templates/:code", handlers.UpdateTemplate)
	//   admin.Get("/logs", handlers.ListLogs)

	return app
}
