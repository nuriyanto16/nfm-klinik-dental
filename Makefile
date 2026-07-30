COMPOSE = docker compose --env-file service-infra-klinik/.env -f service-infra-klinik/docker-compose.yml -f service-infra-klinik/docker-compose.dev.yml
DB_URL_IN_NETWORK = postgres://postgres:postgres@postgres:5432/nina_dental?sslmode=disable

.PHONY: up down logs build migrate-up migrate-down migrate-new seed

up:
	$(COMPOSE) up --build

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f

build:
	$(COMPOSE) build

migrate-up:
	$(COMPOSE) run --rm migrate -path=/migrations -database "$(DB_URL_IN_NETWORK)" up

migrate-down:
	$(COMPOSE) run --rm migrate -path=/migrations -database "$(DB_URL_IN_NETWORK)" down 1

# Usage: make migrate-new name=add_something
migrate-new:
	$(COMPOSE) run --rm migrate create -ext sql -dir /migrations -seq $(name)

# Loads services/core-api/seed/seed.sql into the running postgres container.
# Safe to re-run — the script wipes and re-inserts its own rows.
seed:
	$(COMPOSE) exec -T postgres psql -U postgres -d nina_dental < services/core-api/seed/seed.sql
