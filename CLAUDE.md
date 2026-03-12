# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains Docker build configurations for [Hugr](https://github.com/hugr-lab/hugr) — a Data Mesh platform. It does **not** contain application source code; the Go source is cloned from `github.com/hugr-lab/hugr` at build time. Query/cluster logic lives in `hugr-lab/query-engine`.

## Constitution

Project principles are defined in `.specify/memory/constitution.md`. Key rules:

- **Packaging only** — no application logic in this repo.
- **Two images, one binary** — `server` (minimal) and `automigrate` (server + migrations). Role (standalone/management/worker) is set via `CLUSTER_ROLE` env var at runtime.
- **Management = full node** — management runs the full GraphQL engine and MUST be in load balancer upstreams alongside workers.
- **Build reproducibility** — pinned base images, `CGO_ENABLED=1 -tags=duckdb_arrow`, multi-platform (`amd64`/`arm64`).
- **E2E tests gate publishing** — `e2e/run.sh` must pass before images are pushed to GHCR.

## Docker Images

Two images, multi-stage builds on `ubuntu:24.04`:

| Image | Dockerfile | Description |
|-------|-----------|-------------|
| `ghcr.io/hugr-lab/server` | `server.dockerfile` | Minimal hugr-server binary |
| `ghcr.io/hugr-lab/automigrate` | `automigrate.dockerfile` | Server + migrate binary + migration files + startup script |

The `automigrate` image runs migrations via `run-migrate.sh` when `CORE_DB_PATH` is set and `CORE_DB_READONLY` is not `true`.

## Build Commands

```bash
# Build individual images
docker build -t ghcr.io/hugr-lab/server:latest -f server.dockerfile .
docker build -t ghcr.io/hugr-lab/automigrate:latest -f automigrate.dockerfile .

# Build with specific hugr version
docker build --build-arg HUGR_VERSION=v0.3.3 -t ghcr.io/hugr-lab/server:v0.3.3 -f server.dockerfile .

# Build and run via compose
cd compose && docker compose -f example.build.docker-compose.yaml up --build
```

## Build Args

All Dockerfiles accept:
- `GO_VERSION` — Go compiler version (default: `1.26.1`)
- `HUGR_VERSION` — Git tag/branch of hugr to build (default: `latest`)

## Running Locally

```bash
# Simple server with automigration
cd compose && docker compose -f example.docker-compose.yaml up

# With cache (Redis) and S3 (MinIO)
cd compose && docker compose -f example.cache.docker-compose.yaml up

# Cluster mode (management + workers + nginx)
cd compose && docker compose -f example.cluster.docker-compose.yaml up
```

Server listens on port `15000` by default.

## E2E Tests

```bash
cd e2e
bash run.sh                    # Full suite (standalone + cluster)
bash run.sh --standalone-only  # Skip cluster tests
bash run.sh --keep             # Keep containers after tests
```

Tests cover standalone (DuckDB + PG CoreDB) and cluster mode (management + worker + nginx LB).

## Deployment

- **Docker Compose**: Example configs in `compose/` for single-node and cluster deployments
- **Kubernetes**: Helm chart in `k8s/cluster/` with PostgreSQL and Redis (Bitnami) dependencies
- **CI/CD**: GitHub Actions workflow (`.github/workflows/docker-publish.yml`) triggers on `v*` tags, runs E2E tests, then builds `linux/amd64` + `linux/arm64` and pushes to GHCR

## Version Bumping

When updating versions, these typically change together:
- `GO_VERSION` ARG in Dockerfiles
- `HUGR_VERSION` / image tags in compose files
- Helm chart `appVersion` in `k8s/cluster/Chart.yaml`

## Architecture Note

Ubuntu 24.04 is used as the runtime base (not Alpine/scratch) because go-duckdb has runtime dependencies despite static linking. See: https://github.com/duckdb/duckdb/issues/17632
