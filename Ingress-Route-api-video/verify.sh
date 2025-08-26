#!/bin/bash
set -euo pipefail

NS="streaming"
ING="app-ingress"
HOST="app.example.com"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."

# Ingress exists
kubectl -n "$NS" get ingress "$ING" >/dev/null 2>&1 || fail "Ingress '$ING' not found in namespace '$NS'."

# Host check
FOUND_HOST=$(kubectl -n "$NS" get ingress "$ING" -o json | jq -r '.spec.rules[0].host // empty')
[[ "$FOUND_HOST" == "$HOST" ]] || fail "Expected host '$HOST' on the first rule, found '${FOUND_HOST:-<none>}'."

# Extract paths
JSON=$(kubectl -n "$NS" get ingress "$ING" -o json)

check_path() {
  local path="$1"
  local svc="$2"
  local port="$3"

  # find the path entry
  local entry=$(echo "$JSON" | jq -r --arg p "$path" '.spec.rules[].http.paths[] | select(.path == $p)')
  [[ -n "$entry" ]] || fail "Path '$path' not found."

  local ptype=$(echo "$entry" | jq -r '.pathType')
  [[ "$ptype" == "Prefix" ]] || fail "Path '$path' must have pathType 'Prefix'."

  local name=$(echo "$entry" | jq -r '.backend.service.name // empty')
  local number=$(echo "$entry" | jq -r '.backend.service.port.number // empty')
  [[ "$name" == "$svc" && "$number" == "$port" ]] || fail "Path '$path' must route to service '$svc' port '$port'."
}

check_path "/api" "api-service" "80"
check_path "/video" "video-service" "80"

pass "Verification successful! Ingress '$ING' is correctly configured."
