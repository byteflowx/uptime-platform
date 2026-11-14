export AWS_REGION := eu-north-1
export KUBECONFIG := $(CURDIR)/kubeconfig

TF_STATE_BUCKET = uptime-platform-tfstate-$(shell aws sts get-caller-identity --query Account --output text)
MY_CIDR = $(shell curl -fsS https://checkip.amazonaws.com)/32
TF = terraform -chdir=infra
NODE = $(shell $(TF) output -raw node_id)

.PHONY: dev down test lint infra destroy kubeconfig tunnel deploy

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
	helm lint deploy/chart

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

kubeconfig:
	id=$$(aws ssm send-command --instance-ids $(NODE) --document-name AWS-RunShellScript \
		--parameters 'commands=["cat /etc/rancher/k3s/k3s.yaml"]' --query Command.CommandId --output text) && \
	aws ssm wait command-executed --command-id $$id --instance-id $(NODE) && \
	aws ssm get-command-invocation --command-id $$id --instance-id $(NODE) \
		--query StandardOutputContent --output text > kubeconfig
	chmod 600 kubeconfig

tunnel:
	aws ssm start-session --target $(NODE) \
		--document-name AWS-StartPortForwardingSession --parameters portNumber=6443,localPortNumber=6443

deploy:
	kubectl create secret generic uptime-db --dry-run=client -o yaml --from-literal=password="$$( \
		aws secretsmanager get-secret-value --secret-id $$($(TF) output -raw db_secret_arn) \
			--query SecretString --output text | jq -r .password)" | kubectl apply -f -
	helm upgrade --install argocd argo-cd --repo https://argoproj.github.io/argo-helm --version 10.18.0 \
		--namespace argocd --create-namespace --wait \
		--set dex.enabled=false --set notifications.enabled=false
	sed "s|DB_HOST|$$($(TF) output -raw db_endpoint)|" deploy/argocd.yaml | kubectl apply -f -
