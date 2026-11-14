# uptime-platform

Website uptime monitor: an API to manage sites and a worker that checks them every 30 seconds.

## Local

```bash
make dev
curl -X POST localhost:8000/targets -H 'content-type: application/json' -d '{"url": "https://example.com"}'
curl localhost:8000/status
```

`make test`, `make lint`, `make down`.
