#!/bin/bash
# E2E test runner for hugr Docker images.
# Tests: standalone (DuckDB CoreDB), standalone (PG CoreDB), cluster mode.
#
# Usage:
#   ./run.sh                    # Full test suite
#   ./run.sh --keep             # Keep containers after tests
#   ./run.sh --standalone-only  # Skip cluster tests

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
PASS=0
FAIL=0
KEEP=false
STANDALONE_ONLY=false

for arg in "$@"; do
  case $arg in
    --keep) KEEP=true ;;
    --standalone-only) STANDALONE_ONLY=true ;;
  esac
done

cleanup() {
  if [ "$KEEP" = false ]; then
    echo "Tearing down..."
    docker compose -f "$COMPOSE_FILE" down -v 2>/dev/null || true
  fi
}
trap cleanup EXIT

# Build and start all services
echo "Building and starting E2E environment..."
if [ "$STANDALONE_ONLY" = true ]; then
  docker compose -f "$COMPOSE_FILE" up -d --build --wait standalone standalone-pg
else
  docker compose -f "$COMPOSE_FILE" up -d --build --wait
fi

# --- Helper: run a GraphQL query and check for success ---
check_query() {
  local url="$1" label="$2" query="$3" expect_path="$4"
  local result
  result=$(curl -sf -X POST "$url/query" \
    -H "Content-Type: application/json" \
    -d "{\"query\": $(echo "$query" | jq -Rs .)}" 2>/dev/null) || {
    echo "  FAIL: $label (request failed)"
    FAIL=$((FAIL + 1))
    return
  }

  # Check no errors in response
  local has_errors
  has_errors=$(echo "$result" | jq 'has("errors")' 2>/dev/null)
  if [ "$has_errors" = "true" ]; then
    echo "  FAIL: $label"
    echo "    $(echo "$result" | jq -r '.errors[0].message' 2>/dev/null)"
    FAIL=$((FAIL + 1))
    return
  fi

  # Optionally check a path exists in data
  if [ -n "$expect_path" ]; then
    local val
    val=$(echo "$result" | jq -r "$expect_path" 2>/dev/null)
    if [ -z "$val" ] || [ "$val" = "null" ]; then
      echo "  FAIL: $label (missing $expect_path)"
      FAIL=$((FAIL + 1))
      return
    fi
  fi

  echo "  PASS: $label"
  PASS=$((PASS + 1))
}

# --- Helper: check service is responding ---
check_health() {
  local url="$1" label="$2"
  local result
  result=$(curl -sf -X POST "$url/query" \
    -H "Content-Type: application/json" \
    -d '{"query":"{ __schema { queryType { name } } }"}' 2>/dev/null)
  if [ $? -eq 0 ] && echo "$result" | jq -e '.data.__schema' >/dev/null 2>&1; then
    echo "  PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $label"
    FAIL=$((FAIL + 1))
  fi
}

# ============================================
# Test 1: Standalone (DuckDB CoreDB)
# ============================================
echo ""
echo "=== Standalone (DuckDB CoreDB) ==="
STANDALONE_URL="http://localhost:15000"

check_health "$STANDALONE_URL" "health endpoint"
check_query "$STANDALONE_URL" "introspection" \
  '{ __schema { queryType { name } } }' \
  ".data.__schema.queryType.name"
check_query "$STANDALONE_URL" "core module available" \
  '{ core { data_sources { name } } }' \
  ".data.core"

# ============================================
# Test 2: Standalone (PostgreSQL CoreDB)
# ============================================
echo ""
echo "=== Standalone (PostgreSQL CoreDB) ==="
STANDALONE_PG_URL="http://localhost:15001"

check_health "$STANDALONE_PG_URL" "health endpoint"
check_query "$STANDALONE_PG_URL" "introspection" \
  '{ __schema { queryType { name } } }' \
  ".data.__schema.queryType.name"

# Data source lifecycle: register → load
check_query "$STANDALONE_PG_URL" "insert data source" \
  'mutation { core { insert_data_sources(data: {
    name: "pg_store", prefix: "pg_store", type: "postgres",
    path: "postgres://test:test@postgres:5432/testdb",
    as_module: true, self_defined: true
  }) { name } } }' \
  ".data.core.insert_data_sources.name"

check_query "$STANDALONE_PG_URL" "load data source" \
  'mutation { function { core { load_data_source(name: "pg_store") { success } } } }' \
  ".data.function.core.load_data_source.success"

# ============================================
# Test 3: Cluster Mode
# ============================================
if [ "$STANDALONE_ONLY" = false ]; then
  echo ""
  echo "=== Cluster Mode ==="
  MGMT_URL="http://localhost:15010"
  WORKER_URL="http://localhost:15011"
  NGINX_URL="http://localhost:15020"

  # Health checks
  check_health "$MGMT_URL" "management health"
  check_health "$WORKER_URL" "worker health"

  # Cluster nodes visible
  check_query "$MGMT_URL" "cluster nodes registered" \
    '{ core { cluster { nodes { name role } } } }' \
    ".data.core.cluster.nodes"

  # Data source lifecycle via cluster broadcast
  check_query "$MGMT_URL" "insert data source on management" \
    'mutation { core { insert_data_sources(data: {
      name: "pg_store", prefix: "pg_store", type: "postgres",
      path: "postgres://test:test@postgres:5432/testdb",
      as_module: true, self_defined: true
    }) { name } } }' \
    ".data.core.insert_data_sources.name"

  check_query "$MGMT_URL" "load source via cluster broadcast" \
    'mutation { function { core { cluster { load_source(name: "pg_store") { success } } } } }' \
    ".data.function.core.cluster.load_source.success"

  # Wait for worker to sync schema
  echo "  Waiting for worker schema sync..."
  for i in $(seq 1 30); do
    result=$(curl -sf "$WORKER_URL/query" \
      -H "Content-Type: application/json" \
      -d '{"query":"{ pg_store { __typename } }"}' 2>/dev/null) && \
    echo "$result" | jq -e '.data.pg_store' >/dev/null 2>&1 && break
    sleep 1
  done

  # Query on worker (data source loaded via broadcast)
  check_query "$WORKER_URL" "query data source on worker" \
    '{ pg_store { __typename } }' \
    ".data.pg_store"

  # Query via nginx (load balanced to management + worker)
  check_query "$NGINX_URL" "query via nginx load balancer" \
    '{ __schema { queryType { name } } }' \
    ".data.__schema.queryType.name"

  # Worker forwards mutation to management
  check_query "$WORKER_URL" "unload source via worker" \
    'mutation { function { core { cluster { unload_source(name: "pg_store") { success } } } } }' \
    ".data.function.core.cluster.unload_source.success"
fi

# ============================================
# Summary
# ============================================
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -gt 0 ] && exit 1
exit 0
