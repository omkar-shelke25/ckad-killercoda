#!/bin/bash
set -euo pipefail

NS="legacy"
ING="legacy-ingress"
HOST="legacy.example.com"
ANN_KEY="nginx.ingress.kubernetes.io/rewrite-target"
ANN_VAL="/"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."

# Ingress exists
kubectl -n "$NS" get ingress "$ING" >/dev/null 2>&1 || fail "Ingress '$ING' not found in namespace '$NS'."

JSON=$(kubectl -n "$NS" get ingress "$ING" -o json)

# Annotation (rewrite)
ANN=$(echo "$JSON" | jq -r --arg k "$ANN_KEY" '.metadata.annotations[$k] // empty')
[[ "$ANN" == "$ANN_VAL" ]] || fail "Expected annotation '$ANN_KEY: $ANN_VAL', got '${ANN:-<none>}'."

# Host rule → legacy-svc:80 at path /app
RULE=$(echo "$JSON" | jq -r --arg host "$HOST" '
  .spec.rules[]? | select(.host==$host) | .http.paths[]?
  | select(.path=="/app") | "\(.backend.service.name):\(.backend.service.port.number)"
' | head -n1)
[[ "$RULE" == "legacy-svc:80" ]] || fail "Host rule must route /app on $HOST to legacy-svc:80 (found '${RULE:-<none>}')."

pass "Verification successful! Ingress '$ING' rewrites /app to / via annotation and routes to legacy-svc:80."
