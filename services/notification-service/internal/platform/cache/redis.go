package cache

import (
	"context"

	"github.com/redis/go-redis/v9"
)

// EventsChannel must match payment-service and core-api — this is how
// notification-service is told about things worth notifying someone about
// ("reservation.created", "payment.paid", "reservation.reminder_h1", ...).
const EventsChannel = "nina.events"

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
