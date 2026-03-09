# Running Hugr Cluster on Minikube

Deploy a local Hugr cluster (management + workers + PostgreSQL + Redis) using Minikube and Helm.

## Prerequisites

- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)
- [Docker](https://docs.docker.com/get-docker/)

## Quick Start

```bash
# 1. Start minikube
minikube start --cpus=4 --memory=8192 --driver=docker

# 2. Enable ingress
minikube addons enable ingress

# 3. Build images inside minikube
eval $(minikube docker-env)
docker build -t ghcr.io/hugr-lab/server:v0.3.1 -f server.dockerfile .
docker build -t ghcr.io/hugr-lab/automigrate:v0.3.1 -f automigrate.dockerfile .

# 4. Install the chart
helm install hugr ./k8s/cluster -n hugr --create-namespace \
  --set management.image.pullPolicy=Never \
  --set workNode.image.pullPolicy=Never \
  --set workNode.replicas=1

# 5. Wait for pods
kubectl wait --for=condition=ready pod -l app=coredb -n hugr --timeout=120s
kubectl wait --for=condition=ready pod -l app=management-node -n hugr --timeout=120s
kubectl wait --for=condition=ready pod -l app=work -n hugr --timeout=120s

# 6. Access the API
kubectl port-forward svc/management-node 15000:15000 -n hugr
# Open http://localhost:15000/admin
```

## What Gets Deployed

| Component | Image | Notes |
|-----------|-------|-------|
| CoreDB (PostgreSQL + pgvector) | `pgvector/pgvector:pg16` | Built-in template, no bitnami |
| Redis | `redis:7-alpine` | Built-in template, no bitnami |
| Management node | `ghcr.io/hugr-lab/automigrate:v0.3.1` | Runs migrations, then serves as full query node |
| Worker node(s) | `ghcr.io/hugr-lab/server:v0.3.1` | Stateless query nodes |

The chart uses lightweight built-in PostgreSQL and Redis templates (not bitnami subcharts). CoreDB uses `pgvector/pgvector:pg16` which includes the vector extension required for migrations.

## Step-by-Step Guide

### 1. Start Minikube

```bash
minikube start --cpus=4 --memory=8192 --driver=docker
```

For cluster mode with multiple workers, increase memory:

```bash
minikube start --cpus=4 --memory=16384 --driver=docker
```

### 2. Build Docker Images in Minikube

Point your Docker client at minikube's daemon so built images are available inside the cluster:

```bash
eval $(minikube docker-env)
```

Build both images (from the repo root):

```bash
docker build -t ghcr.io/hugr-lab/server:v0.3.1 -f server.dockerfile .
docker build -t ghcr.io/hugr-lab/automigrate:v0.3.1 -f automigrate.dockerfile .
```

> **Note**: The build takes a while — it compiles Go with CGO and DuckDB. Subsequent builds are faster due to Docker cache.

### 3. Install the Helm Chart

```bash
helm install hugr ./k8s/cluster -n hugr --create-namespace \
  --set management.image.pullPolicy=Never \
  --set workNode.image.pullPolicy=Never \
  --set workNode.replicas=1
```

Key flags:
- `pullPolicy=Never` — use locally built images instead of pulling from GHCR
- `workNode.replicas=1` — save resources locally (default is 3)

### 4. Verify Pods

```bash
kubectl get pods -n hugr
```

Expected output:

```
NAME                               READY   STATUS    RESTARTS   AGE
coredb-0                           1/1     Running   0          60s
redis-xxxxx                        1/1     Running   0          60s
management-node-xxxxx              1/1     Running   0          60s
work-0                             1/1     Running   0          60s
```

If a pod is not ready, check logs:

```bash
kubectl logs -n hugr <pod-name>
```

### 5. Access the Cluster

**Option A: Port forward to management node**

```bash
kubectl port-forward svc/management-node 15000:15000 -n hugr
```

Open http://localhost:15000/admin for the GraphQL playground.

**Option B: Port forward to a worker node**

```bash
kubectl port-forward svc/work 15000:15000 -n hugr
```

**Option C: Ingress (requires Traefik)**

```bash
minikube addons enable ingress
echo "$(minikube ip) hugr-cluster.local" | sudo tee -a /etc/hosts
```

Then access http://hugr-cluster.local (default ingress host).

### 6. Test the Cluster

Verify management node:

```bash
curl -s http://localhost:15000/query \
  -H "Content-Type: application/json" \
  -d '{"query":"{ function { core { info { node_name node_role version } } } }"}' | jq .
```

Check cluster nodes (from management):

```bash
curl -s http://localhost:15000/query \
  -H "Content-Type: application/json" \
  -d '{"query":"{ core { cluster { nodes { name role } } } }"}' | jq .
```

## Configuration

### Using Pre-built Images (from GHCR)

If images are published to GHCR, skip the local build step and install directly:

```bash
helm install hugr ./k8s/cluster -n hugr --create-namespace
```

### Using Bitnami Subcharts

To use bitnami PostgreSQL/Redis instead of built-in templates:

```bash
helm dependency update ./k8s/cluster
helm install hugr ./k8s/cluster -n hugr --create-namespace \
  --set postgresql.bitnami=true \
  --set cache.bitnami=true
```

> **Warning**: Bitnami PostgreSQL does not include pgvector. You may need to override the image:
> `--set postgresql.image.repository=pgvector/pgvector --set postgresql.image.tag=pg16`

### Multiple Workers

```bash
helm install hugr ./k8s/cluster -n hugr --create-namespace \
  --set workNode.replicas=3
```

### Mount Shared Data

To mount host files (e.g., schema definitions) into worker nodes:

```bash
# In a separate terminal
minikube mount $(pwd)/data:/data
```

The chart mounts `/data` into worker pods via hostPath by default.

## Cleanup

```bash
helm uninstall hugr -n hugr
kubectl delete namespace hugr
minikube stop
```

To reset everything:

```bash
minikube delete
```
