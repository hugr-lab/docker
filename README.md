# Hugr docker images

The `hugr` is a Data Mesh platform that provides a simple way to manage and share data across different teams and services. It is designed to be easy to use and deploy, with a focus on simplicity and flexibility.

For more information about the Hugr project, please visit the [Hugr web site](https://hugr-lab.github.io/).

## Docker Images

There are two images:

- `ghcr.io/hugr-lab/server` — minimal hugr-server binary
- `ghcr.io/hugr-lab/automigrate` — hugr-server with auto-migration for the core-db schema

Both images are built from a single `hugr-server` binary. The role (standalone, management, worker) is determined by the `CLUSTER_ROLE` environment variable at runtime. For cluster mode, management uses the `automigrate` image with `CLUSTER_ROLE=management`.

The images are built using:

- `server.dockerfile`
- `automigrate.dockerfile`

The automation builds provided by GitHub actions are triggered by the new release tag. The version of images is the same as [Hugr](https://github.com/hugr-lab/hugr). To build the images manually, you can use the following commands:

```bash
docker build -t ghcr.io/hugr-lab/server:latest -f server.dockerfile .
docker build -t ghcr.io/hugr-lab/automigrate:latest -f automigrate.dockerfile .
```

Or you can build and run it using docker compose. The compose file is provided in the `compose` directory:

```bash
cd compose && docker compose -f example.build.docker-compose.yaml up --build
```

## Usage

To run the server, you can use the following command:

```bash
cd compose
docker compose -f example.docker-compose.yaml up
```

This will start the server and the database. The server will be available at `http://localhost:15000`. To set up other settings use environment variables — see [Hugr repo](https://github.com/hugr-lab/hugr).

There is an example of docker-compose file that describes Hugr with cache and S3 (minio) services:

```bash
docker compose -f example.cache.docker-compose.yaml up
```

## Cluster Deployment

Hugr runs natively in cluster mode. All nodes use the same `hugr-server` binary with the role set via environment variables:

- **Management node**: `automigrate` image with `CLUSTER_ROLE=management` — runs migrations, manages cluster state, and serves user queries
- **Worker nodes**: `server` image with `CLUSTER_ROLE=worker` — query execution nodes with caching

Management is a full query node included in the nginx upstream alongside workers, maximizing resource utilization.

Key cluster environment variables:
- `CLUSTER_ENABLED=true` — enable cluster mode
- `CLUSTER_ROLE` — `management` or `worker`
- `CLUSTER_SECRET` — shared authentication secret
- `CLUSTER_NODE_NAME` — unique node identifier
- `CLUSTER_NODE_URL` — node's IPC endpoint URL
- `CLUSTER_HEARTBEAT` — heartbeat interval (management only)
- `CLUSTER_GHOST_TTL` — ghost node TTL (management only)
- `CLUSTER_POLL_INTERVAL` — config poll interval (workers only)

Run the cluster example:

```bash
cd compose
docker compose -f example.cluster.docker-compose.yaml up
```

The cluster is accessible at `http://localhost:15000` via nginx load balancer.

There is also a Kubernetes Helm chart in `k8s/cluster/`. For local setup see [minikube-cluster.md](compose/minikube-cluster.md).

## E2E Tests

End-to-end tests verify standalone and cluster modes:

```bash
cd e2e
bash run.sh                    # Full suite
bash run.sh --standalone-only  # Skip cluster tests
bash run.sh --keep             # Keep containers after tests
```

Tests cover:
- Standalone with DuckDB CoreDB (in-memory)
- Standalone with PostgreSQL CoreDB
- Cluster mode (management + worker + nginx load balancer)
- Data source lifecycle (insert, load, query, unload)

## Pull Images

```bash
docker pull ghcr.io/hugr-lab/server:latest
docker pull ghcr.io/hugr-lab/automigrate:latest
```

You can also save and load the images to/from a tar file:

```bash
docker pull ghcr.io/hugr-lab/server:latest --platform linux/amd64
docker save -o hugr-server.tar ghcr.io/hugr-lab/server:latest --platform linux/amd64
docker load -i hugr-server.tar
```

```bash
docker pull ghcr.io/hugr-lab/automigrate:latest --platform linux/amd64
docker save -o hugr-automigrate.tar ghcr.io/hugr-lab/automigrate:latest --platform linux/amd64
docker load -i hugr-automigrate.tar
```

## Contributing

If you want to contribute to this project, please fork the repository and create a pull request. We welcome contributions of all kinds, including bug fixes, new features, and documentation improvements.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
