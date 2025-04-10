FROM golang:1.24-bookworm AS builder
WORKDIR /app

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*


ARG HUGR_VERSION=latest
ENV HUGR_VERSION=${HUGR_VERSION}

RUN git clone --depth 1 --branch ${HUGR_VERSION} https://github.com/hugr-lab/hugr.git hugr
WORKDIR /app/hugr

RUN go get github.com/marcboeker/go-duckdb/v2
RUN go mod download

RUN cd cmd/server && \
    CGO_ENABLED=1 go build -tags='duckdb_arrow' -o /hugr-server .

RUN cd cmd/migrate && \
    CGO_ENABLED=1 go build -tags='duckdb_arrow' -o /migrate .

RUN cp -r /app/hugr/migrations /migrations

# We use debian:bookworm-slim because it has the necessary dependencies for DuckDB. Even though go-duckdb statically
# links the DuckDB library, it still needs some dependencies to be present on the system. This is a known issue:
# https://github.com/marcboeker/go-duckdb/issues/54
FROM debian:bookworm-slim 
USER root
WORKDIR /app

COPY --from=builder hugr-server .
COPY --from=builder migrate .
COPY --from=builder migrations migrations
COPY run-service.sh run-service.sh

RUN /app/hugr-server --install

RUN chmod +x /app/run-service.sh

CMD ["sh", "/app/run-service.sh"]

