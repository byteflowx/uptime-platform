export AWS_REGION := eu-north-1

TF_STATE_BUCKET = uptime-platform-tfstate-$(shell aws sts get-caller-identity --query Account --output text)
MY_CIDR = $(shell curl -fsS https://checkip.amazonaws.com)/32
TF = terraform -chdir=infra

.PHONY: dev down test lint infra destroy

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
	terraform fmt -check -recursive infra

infra:
	aws s3api head-bucket --bucket $(TF_STATE_BUCKET) 2>/dev/null || ( \
		aws s3api create-bucket --bucket $(TF_STATE_BUCKET) \
			--create-bucket-configuration LocationConstraint=$(AWS_REGION) && \
		aws s3api put-bucket-versioning --bucket $(TF_STATE_BUCKET) \
			--versioning-configuration Status=Enabled )
	$(TF) init -input=false -backend-config="bucket=$(TF_STATE_BUCKET)"
	$(TF) apply -var allowed_cidr=$(MY_CIDR)

destroy:
	$(TF) destroy -var allowed_cidr=$(MY_CIDR)
