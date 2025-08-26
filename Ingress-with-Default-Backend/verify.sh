#!/bin/bash
set -euo pipefail

NS="main"
ING="site-ingress"
HOST="main.example.com"
ICLASS="nginx"
ANN_KEY="nginx.ingress.kubernetes.io/rewrite-target"
ANN_VAL="/"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."

# Ingress exists
kubectl -n "$NS" get ingress "$ING" >/dev/null 2>&1 || fail "Ingress '$ING' not found in namespace '$NS'."

JSON=$(kubectl -n "$NS" get ingress "$ING" -o json)

# ingressClassName
CLASS=$(echo "$JSON" | jq -r '.spec.ingressClassName // empty')
[[ "$CLASS" == "$ICLASS" ]] || fail "Expected ingressClassName '$ICLASS', found '${CLASS:-<none>}'"

# Annotation
ANN=$(echo "$JSON" | jq -r --arg k "$ANN_KEY" '.metadata.annotations[$k] // empty')
[[ "$ANN" == "$ANN_VAL" ]] || fail "Expected annotation '$ANN_KEY: $ANN_VAL', got '${ANN:-<none>}'"

# Host rule → main-site-svc:80 at path /
RULE=$(echo "$JSON" | jq -r --arg host "$HOST" '
  .spec.rules[]? | select(.host==$host) | .http.paths[]?
  | select(.path=="/") | "\(.backend.service.name):\(.backend.service.port.number)"
' | head -n1)
[[ "$RULE" == "main-site-svc:80" ]] || fail "Host rule must route / on $HOST to main-site-svc:80 (found '${RULE:-<none>}')."

# Default backend → error-page-svc:80
DEF=$(echo "$JSON" | jq -r '.spec.defaultBackend.service.name // empty')
DEFPORT=$(echo "$JSON" | jq -r '.spec.defaultBackend.service.port.number // empty')
[[ "$DEF" == "error-page-svc" && "$DEFPORT" == "80" ]] || fail "Default backend must be error-page-svc:80 (found '${DEF:-<none>}':${DEFPORT:-<none>})."

pass "Verification successful! Ingress '$ING' has nginx class, rewrite annotation, host rule, and a correct default backend."
