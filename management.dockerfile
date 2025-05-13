FROM golang:1.24-bookworm AS builder
WORKDIR /app

RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*


ARG HUGR_VERSION=latest
ENV HUGR_VERSION=${HUGR_VERSION}

RUN git clone --depth 1 --branch ${HUGR_VERSION} https://github.com/hugr-lab/hugr.git hugr
WORKDIR /app/hugr

RUN go mod download
RUN make migrate
RUN make management

RUN cp -r /app/hugr/migrations /migrations

# We use debian:bookworm-slim because it has the necessary dependencies for DuckDB. Even though go-duckdb statically
# links the DuckDB library, it still needs some dependencies to be present on the system. This is a known issue:
# https://github.com/marcboeker/go-duckdb/issues/54
FROM debian:bookworm-slim 
USER root
WORKDIR /app
RUN apt-get update && apt-get install -y curl libcurl4 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/hugr/management hugr-management
COPY --from=builder /app/hugr/migrate .
COPY --from=builder migrations migrations
COPY run-management-migrate.sh run-service.sh

RUN chmod +x /app/run-service.sh

CMD ["sh", "/app/run-service.sh"]

