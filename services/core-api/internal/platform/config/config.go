package config

import (
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

type Config struct {
	AppEnv              string
	HTTPPort            string
	DatabaseURL         string
	RedisURL            string
	JWTAccessSecret     string
	JWTRefreshSecret    string
	JWTAccessTTLMinutes int
	PaymentServiceURL   string
	NotificationSvcURL  string
	// AllowedOrigins is a comma-separated CORS allowlist — the admin panel's
	// own origin(s), never "*" for an API that issues auth tokens.
	AllowedOrigins string
}

func Load() Config {
	_ = godotenv.Load()

	return Config{
		AppEnv:              getEnv("APP_ENV", "development"),
		HTTPPort:            getEnv("HTTP_PORT", "8080"),
		DatabaseURL:         getEnv("DATABASE_URL", "postgres://postgres:postgres@localhost:5432/nina_dental?sslmode=disable"),
		RedisURL:            getEnv("REDIS_URL", "redis://localhost:6379/0"),
		JWTAccessSecret:     getEnv("JWT_ACCESS_SECRET", "dev-access-secret-change-me"),
		JWTRefreshSecret:    getEnv("JWT_REFRESH_SECRET", "dev-refresh-secret-change-me"),
		JWTAccessTTLMinutes: getEnvInt("JWT_ACCESS_TTL_MINUTES", 15),
		PaymentServiceURL:   getEnv("PAYMENT_SERVICE_URL", "http://payment-service:8081"),
		NotificationSvcURL:  getEnv("NOTIFICATION_SERVICE_URL", "http://notification-service:8082"),
		AllowedOrigins:      getEnv("ALLOWED_ORIGINS", "http://localhost:3100,https://nfmtech.my.id"),
	}
}

func getEnv(key, fallback string) string {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		return v
	}
	return fallback
}

func getEnvInt(key string, fallback int) int {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			return n
		}
	}
	return fallback
}
