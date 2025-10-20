FROM ubuntu:24.04 AS builder
WORKDIR /app

RUN apt-get update && apt-get install -y wget git g++ gcc libc6-dev make pkg-config && rm -rf /var/lib/apt/lists/*

ARG GO_VERSION=1.25.3
ARG HUGR_VERSION=latest
ENV HUGR_VERSION=${HUGR_VERSION}
ENV GO_VERSION=${GO_VERSION}
RUN echo "HUGR_VERSION=${HUGR_VERSION}"
RUN echo "GO_VERSION=${GO_VERSION}"

RUN set -eux; \ 
        arch="$(dpkg --print-architecture)"; arch="${arch##*-}"; \
	    file=; \
        case "$arch" in \
            amd64) file="go${GO_VERSION}.linux-amd64.tar.gz" ;; \
            arm64) file="go${GO_VERSION}.linux-arm64.tar.gz" ;; \
            *) echo "Unsupported architecture: $arch"; exit 1 ;; \
        esac; \
        echo "Downloading Go from $file"; \
        wget -P /tmp "https://dl.google.com/go/$file"; \
        echo "Extracting Go to /usr/local"; \
        tar -C /usr/local -xzf "/tmp/$file"; \
        rm /tmp/go*.tar.gz;

ENV PATH="/usr/local/go/bin:${PATH}"
RUN go version

RUN git clone https://github.com/hugr-lab/hugr.git hugr
WORKDIR /app/hugr

RUN git checkout ${HUGR_VERSION}

RUN go mod download
RUN make server GIT_VERSION=${HUGR_VERSION}
RUN make migrate GIT_VERSION=${HUGR_VERSION}
RUN make management GIT_VERSION=${HUGR_VERSION}

RUN cp -r /app/hugr/migrations /migrations

# We use ubuntu:24.04 because it has the necessary dependencies for DuckDB. Even though go-duckdb statically
# links the DuckDB library, it still needs some dependencies to be present on the system. This is a known issue:
# https://github.com/duckdb/duckdb/issues/17632
FROM ubuntu:24.04
USER root
WORKDIR /app
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf \
        /var/lib/apt/lists/* \
        /usr/share/doc/* \
        /usr/share/man/* \
        /usr/share/locale/* \
        /var/cache/* \
        /tmp/* \
        /var/tmp/*

COPY --from=builder /app/hugr/management hugr-management
COPY --from=builder /app/hugr/migrate .
COPY --from=builder migrations migrations
COPY run-management-migrate.sh run-service.sh

RUN chmod +x /app/run-service.sh

CMD ["sh", "/app/run-service.sh"]

