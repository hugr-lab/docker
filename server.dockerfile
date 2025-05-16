FROM golang:1.24-bookworm AS builder
WORKDIR /app

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*


ARG HUGR_VERSION=latest
ENV HUGR_VERSION=${HUGR_VERSION}
RUN echo "HUGR_VERSION=${HUGR_VERSION}"
RUN git clone https://github.com/hugr-lab/hugr.git hugr
WORKDIR /app/hugr

RUN git checkout ${HUGR_VERSION}

RUN go get github.com/marcboeker/go-duckdb/v2
RUN go mod download

RUN make server GIT_VERSION=${HUGR_VERSION}

# We use debian:bookworm-slim because it has the necessary dependencies for DuckDB. Even though go-duckdb statically
# links the DuckDB library, it still needs some dependencies to be present on the system. This is a known issue:
# https://github.com/marcboeker/go-duckdb/issues/54
FROM debian:bookworm-slim 
USER root
WORKDIR /app
RUN apt-get update && apt-get install -y curl libcurl4 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/hugr/server hugr-server

RUN /app/hugr-server --install

CMD ["/app/hugr-server"]

