package logger

import (
	"os"

	"github.com/rs/zerolog"
)

func New(appEnv string) zerolog.Logger {
	if appEnv == "development" {
		return zerolog.New(zerolog.ConsoleWriter{Out: os.Stdout}).With().Timestamp().Logger()
	}
	return zerolog.New(os.Stdout).With().Timestamp().Logger()
}
