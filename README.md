# uptime-platform

Website uptime monitor: an API to manage sites and a worker that checks them every 30 seconds.

## Local

```bash
make dev
curl -X POST localhost:8000/targets -H 'content-type: application/json' -d '{"url": "https://example.com"}'
curl localhost:8000/status
```

`make test`, `make lint`, `make down`.

## AWS

Requires Terraform, Helm, kubectl, jq and AWS CLI with the Session Manager plugin, signed in with `aws login`.

1. `make infra` creates VPC, EC2 with k3s and RDS.
2. `make kubeconfig`, then `make tunnel` in a separate terminal.
3. `make deploy` installs Argo CD, which deploys `deploy/chart` from `main`.
4. `curl http://$(terraform -chdir=infra output -raw node_public_ip)/status`
5. `make destroy` removes everything.
