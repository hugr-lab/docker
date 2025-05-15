# 🚀 Running Hugr Cluster Locally with Minikube

This guide walks you through deploying a local Hugr cluster using **Minikube** and **Helm**, including schema volume mounts, DNS setup, and Traefik access.

---

## 📦 Prerequisites

Install the following tools:

- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)
- Docker (required if using Docker as driver)

---

## 🧱 1. Start Minikube

```bash
minikube start --cpus=4 --memory=8192 --driver=docker
```

Optional (to persist config):

```bash
minikube config set cpus 4
minikube config set memory 8192
```

---

## 📁 2. Connect to Cluster

```bash
kubectl config use-context minikube
kubectl get nodes
```

---

## 📦 3. Update Helm Dependencies

Inside your chart directory:

```bash
cd k8s/cluster
helm dependency update
```

---

## 🚀 4. Install the Hugr Helm Chart

Initial install:

```bash
helm install hugr ./k8s/cluster -n hugr --create-namespace
```

Upgrade / re-install:

```bash
helm upgrade --install hugr ./k8s/cluster -n hugr -f values.yaml
```

---

## 🌐 5. Access Hugr API / UI

### Option A: Port Forwarding (for development)

```bash
kubectl port-forward svc/traefik 16000:80 -n traefik
```

It will be accessible at: `http://hugr-cluster.local:16000/`

### Option B: LoadBalancer with Minikube Tunnel

In a separate terminal:

```bash
minikube tunnel
```

It will be accessible at: `http://hugr-cluster.local/`

---

## 📂 6. Mount shared folder from host

If you want to mount a shared folder to each work node (schema definition files), follow these steps:

Mount a shared folder to `/data`:

```bash
minikube mount $(pwd)/data:/data
```

In `values.yaml`:

```yaml
workNode:
  shared:
    hostPath: /data
    mountPath: /data
```

---

## 🧾 7. Edit Local DNS

Add hostnames to `/etc/hosts`:

```bash
echo "127.0.0.1 hugr-cluster.local traefik.local" | sudo tee -a /etc/hosts
```

---

## ✅ 8. Check Everything Is Running

```bash
kubectl get pods -n hugr
```

Check health:

```bash
curl -H "Host: hugr-cluster.local" http://localhost:16000/health
```

Open in browser:

`http://hugr-cluster.local:16000/admin`
or if using the tunnel:
`http://hugr-cluster.local/admin`

---

You're ready to work with a fully functional local Hugr cluster! 🎉
