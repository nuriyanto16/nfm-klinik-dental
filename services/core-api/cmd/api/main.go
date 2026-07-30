package main

import (
	"context"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/nina-dental-care/core-api/internal/platform/cache"
	"github.com/nina-dental-care/core-api/internal/platform/config"
	"github.com/nina-dental-care/core-api/internal/platform/db"
	"github.com/nina-dental-care/core-api/internal/platform/httpserver"
	"github.com/nina-dental-care/core-api/internal/platform/logger"
)

func main() {
	cfg := config.Load()
	log := logger.New(cfg.AppEnv)

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	pool, err := db.Connect(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to connect to postgres")
	}
	defer pool.Close()
	log.Info().Msg("connected to postgres")

	redisClient, err := cache.Connect(ctx, cfg.RedisURL)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to connect to redis")
	}
	defer redisClient.Close()
	log.Info().Msg("connected to redis")

	app := httpserver.New(httpserver.Dependencies{
		AppEnv:              cfg.AppEnv,
		DB:                  pool,
		JWTAccessSecret:     cfg.JWTAccessSecret,
		JWTAccessTTLMinutes: cfg.JWTAccessTTLMinutes,
	})

	go func() {
		if err := app.Listen(":" + cfg.HTTPPort); err != nil {
			log.Fatal().Err(err).Msg("http server stopped")
		}
	}()
	log.Info().Str("port", cfg.HTTPPort).Msg("core-api listening")

	<-ctx.Done()
	log.Info().Msg("shutting down core-api")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := app.ShutdownWithContext(shutdownCtx); err != nil {
		log.Error().Err(err).Msg("graceful shutdown failed")
	}
}
