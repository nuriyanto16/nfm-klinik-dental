package config

import (
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	AppEnv           string
	HTTPPort         string
	DatabaseURL      string
	RedisURL         string
	XenditAPIKey     string
	XenditWebhookKey string
	XenditBaseURL    string
}

func Load() Config {
	_ = godotenv.Load()

	return Config{
		AppEnv:           getEnv("APP_ENV", "development"),
		HTTPPort:         getEnv("HTTP_PORT", "8081"),
		DatabaseURL:      getEnv("DATABASE_URL", "postgres://postgres:postgres@localhost:5432/nina_dental?sslmode=disable"),
		RedisURL:         getEnv("REDIS_URL", "redis://localhost:6379/0"),
		XenditAPIKey:     getEnv("XENDIT_API_KEY", ""),
		XenditWebhookKey: getEnv("XENDIT_WEBHOOK_VERIFICATION_TOKEN", ""),
		XenditBaseURL:    getEnv("XENDIT_BASE_URL", "https://api.xendit.co"),
	}
}

func getEnv(key, fallback string) string {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		return v
	}
	return fallback
}
