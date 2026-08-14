package logger

import (
	"os"
	"path/filepath"

	"github.com/rs/zerolog"
)

// levelFilterWriter wraps an io.Writer and only writes if the level is >= ErrorLevel
// (Actually we can just use zerolog's built-in LevelWriter interface if needed, or simply let the app write everything to file.
// But to strictly filter by error, we need a custom writer that parses the level, which is complex for zerolog since it writes raw JSON.
// Zerolog provides a cleaner way: multiple loggers, or we can just log everything to the file.)
// Given the complexity of filtering JSON on the fly, we will just write ALL logs to the file, and filter them when displaying if needed,
// OR we can just use &zerolog.FilteredLevelWriter{Writer: zerolog.LevelWriterAdapter{Writer: logFile}, Level: zerolog.ErrorLevel}


func New(appEnv string) zerolog.Logger {
	// Create logs directory if it doesn't exist
	logDir := "logs"
	if err := os.MkdirAll(logDir, 0755); err != nil {
		// Fallback to stdout if we can't create the directory
		return zerolog.New(os.Stdout).With().Timestamp().Logger()
	}

	logFile, err := os.OpenFile(filepath.Join(logDir, "app-error.log"), os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		return zerolog.New(os.Stdout).With().Timestamp().Logger()
	}

	// Create a writer that filters for error level and above for the file
	fileWriter := &zerolog.FilteredLevelWriter{
		Writer: zerolog.LevelWriterAdapter{Writer: logFile},
		Level:  zerolog.ErrorLevel,
	}

	var multi zerolog.LevelWriter
	if appEnv == "development" {
		multi = zerolog.MultiLevelWriter(zerolog.ConsoleWriter{Out: os.Stdout}, fileWriter)
	} else {
		multi = zerolog.MultiLevelWriter(os.Stdout, fileWriter)
	}

	return zerolog.New(multi).With().Timestamp().Logger()
}
