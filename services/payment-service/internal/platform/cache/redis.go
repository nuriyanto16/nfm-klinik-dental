package cache

import (
	"context"

	"github.com/redis/go-redis/v9"
)

func Connect(ctx context.Context, redisURL string) (*redis.Client, error) {
	opt, err := redis.ParseURL(redisURL)
	if err != nil {
		return nil, err
	}

	client := redis.NewClient(opt)
	if err := client.Ping(ctx).Err(); err != nil {
		return nil, err
	}

	return client, nil
}

// Events publishes domain events (e.g. "payment.paid") on a well-known Redis
// pub/sub channel so core-api and notification-service can react without a
// direct dependency on payment-service.
const EventsChannel = "nina.events"
