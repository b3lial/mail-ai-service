# mail-ai-service

Runs as a single Docker container. On startup it launches **mail-proxy** (a FastAPI service that talks to an IMAP account) and **mail-agent** (an LLM agent that reads unread emails and moves or deletes them according to configurable rules).

## Prerequisites

- Docker
- A config file for each service (see `mail-proxy/config.example.yaml` and `mail-agent/config.example.yaml`)
- An IMAP account and an [Ollama](https://ollama.com/) instance reachable from the container

## Build

The build accepts a `VERSION` argument. Pass the current git description so the version is baked into the image label and `/etc/mail-ai-service/version` inside the container.

```bash
docker build \
  --build-arg VERSION=$(git describe --tags --always --dirty) \
  -t mail-ai-service:$(git describe --tags --always --dirty) \
  -t mail-ai-service:latest \
  .
```

## Configuration

Each service reads a YAML config file that you mount into the container, plus secrets supplied as environment variables.

### mail-proxy

Mount your config at `/etc/mail-proxy/config.yaml` (or override the path via `MAIL_PROXY_CONFIG`).

| Environment variable | Required | Description |
|---|---|---|
| `MAIL_PASSWORD` | yes | IMAP account password |
| `PROXY_API_KEY` | yes | Bearer token agents must supply to call the proxy |

See `mail-proxy/config.example.yaml` for all options.

### mail-agent

Mount your config at `/etc/mail-agent/config.yaml` (or override the path via `MAIL_AGENT_CONFIG`).

| Environment variable | Required | Description |
|---|---|---|
| `MAIL_PROXY_API_KEY` | yes | Must match `PROXY_API_KEY` set for mail-proxy |

See `mail-agent/config.example.yaml` for all options (LLM model, poll interval, sorting rules, …).

### Important config notes

- `PROXY_API_KEY` and `MAIL_PROXY_API_KEY` must be set to the **same value**: the proxy uses the former to validate incoming requests, and the agent uses the latter to authenticate against the proxy.
- Both services run inside the same container, so the agent's `proxy.base_url` must point to localhost: set it to `http://127.0.0.1:8080` in the mail-agent config. If you change `proxy.port` in the mail-proxy config, update this URL and also the port in `docker-entrypoint.sh` accordingly.

## Run

```bash
docker run -d \
  --name mail-ai-service \
  -v /path/to/mail-proxy-config.yaml:/etc/mail-proxy/config.yaml:ro \
  -v /path/to/mail-agent-config.yaml:/etc/mail-agent/config.yaml:ro \
  -e MAIL_PASSWORD=your-imap-password \
  -e PROXY_API_KEY=your-secret-key \
  -e MAIL_PROXY_API_KEY=your-secret-key \
  mail-ai-service:latest
```

Follow logs:

```bash
docker logs -f mail-ai-service
```

Stop:

```bash
docker stop mail-ai-service
```

## Inspect the version

```bash
docker inspect mail-ai-service:latest --format '{{ index .Config.Labels "version" }}'
# or inside a running container:
docker exec mail-ai-service cat /etc/mail-ai-service/version
```
