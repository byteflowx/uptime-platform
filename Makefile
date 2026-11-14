.PHONY: dev down test lint

dev:
	docker compose up --build --detach --wait

down:
	docker compose down

test:
	docker compose up --detach --wait db
	docker compose exec db createdb -U uptime uptime_test 2>/dev/null || true
	cd app && uv run pytest

lint:
	cd app && uv run ruff check . && uv run ruff format --check .
	docker run --rm -i hadolint/hadolint:v2.15.1 < app/Dockerfile
