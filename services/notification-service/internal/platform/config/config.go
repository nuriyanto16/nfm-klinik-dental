package config

import (
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	AppEnv         string
	HTTPPort       string
	DatabaseURL    string
	RedisURL       string
	WAGatewayURL   string
	WAGatewayToken string
	FCMCredentials string
	SMTPHost       string
	SMTPPort       string
	SMTPUser       string
	SMTPPassword   string
}

func Load() Config {
	_ = godotenv.Load()

	return Config{
		AppEnv:         getEnv("APP_ENV", "development"),
		HTTPPort:       getEnv("HTTP_PORT", "8082"),
		DatabaseURL:    getEnv("DATABASE_URL", "postgres://postgres:postgres@localhost:5432/nina_dental?sslmode=disable"),
		RedisURL:       getEnv("REDIS_URL", "redis://localhost:6379/0"),
		WAGatewayURL:   getEnv("WA_GATEWAY_URL", ""),
		WAGatewayToken: getEnv("WA_GATEWAY_TOKEN", ""),
		FCMCredentials: getEnv("FCM_CREDENTIALS_JSON", ""),
		SMTPHost:       getEnv("SMTP_HOST", ""),
		SMTPPort:       getEnv("SMTP_PORT", "587"),
		SMTPUser:       getEnv("SMTP_USER", ""),
		SMTPPassword:   getEnv("SMTP_PASSWORD", ""),
	}
}

func getEnv(key, fallback string) string {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		return v
	}
	return fallback
}
