// Package apperr centralizes how handlers turn an unexpected internal error
// into an HTTP response: log the real error server-side (with enough
// context to debug it) and return a generic message to the client. Never
// echo err.Error() straight into a response body — for a database driver
// that can include table/column names, constraint names, or query
// fragments, which is free reconnaissance for an attacker probing the API.
package apperr

import (
	"github.com/gofiber/fiber/v2"
	"github.com/rs/zerolog/log"
)

// Internal logs err with request context and returns a generic 500 to the
// client. Use for any error that isn't a recognized domain error (those get
// their own specific status code and safe message at the call site).
func Internal(c *fiber.Ctx, err error) error {
	log.Error().
		Err(err).
		Str("method", c.Method()).
		Str("path", c.Path()).
		Msg("unhandled internal error")
	return fiber.NewError(fiber.StatusInternalServerError, "internal server error")
}
