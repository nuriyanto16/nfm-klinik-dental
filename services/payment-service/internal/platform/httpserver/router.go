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
		AppName:               "payment-service",
		DisableStartupMessage: deps.AppEnv != "development",
	})

	app.Use(recover.New())
	app.Use(requestid.New())
	app.Use(cors.New())

	app.Get("/healthz", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"status": "ok", "service": "payment-service"})
	})

	// Wired up once the Xendit Provider implementation lands:
	//   internal := app.Group("/internal/payments")
	//   internal.Post("/", handlers.CreatePayment)
	//   internal.Get("/:id", handlers.GetPayment)
	//   app.Post("/webhooks/xendit", handlers.XenditWebhook)

	return app
}
