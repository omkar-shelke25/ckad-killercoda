#!/bin/bash
# Verification script for Ingress 'site-ingress' with default backend
set -uo pipefail

NS="main"
ING="site-ingress"
HOST="main.example.com"
ICLASS="nginx"
ANN_KEY="nginx.ingress.kubernetes.io/rewrite-target"
ANN_VAL="/"

pass() { echo "PASS: $1"; exit 0; }
fail() { echo "FAIL: $1"; exit 1; }
ok()   { echo "  ok: $1"; }

# -- Prerequisites --
kubectl get ns "$NS" >/dev/null 2>&1 \
  || fail "Namespace '$NS' not found"
ok "Namespace '$NS' exists"

kubectl -n "$NS" get svc main-site-svc >/dev/null 2>&1 \
  || fail "Service 'main-site-svc' not found in '$NS'"
ok "Service 'main-site-svc' exists"

kubectl -n "$NS" get svc error-page-svc >/dev/null 2>&1 \
  || fail "Service 'error-page-svc' not found in '$NS'"
ok "Service 'error-page-svc' exists"

# -- Ingress exists --
kubectl -n "$NS" get ingress "$ING" >/dev/null 2>&1 \
  || fail "Ingress '$ING' not found in namespace '$NS' — make sure the name is exactly 'site-ingress'"
ok "Ingress '$ING' exists"

INGRESS_JSON=$(kubectl -n "$NS" get ingress "$ING" -o json)

# -- ingressClassName: nginx --
CLASS=$(echo "$INGRESS_JSON" | jq -r '.spec.ingressClassName // empty')
[[ "$CLASS" == "$ICLASS" ]] \
  || fail "ingressClassName must be 'nginx' (found: '${CLASS:-<none>}')"
ok "ingressClassName: nginx"

# -- Annotation: nginx.ingress.kubernetes.io/rewrite-target = "/" --
ANN=$(echo "$INGRESS_JSON" | jq -r --arg k "$ANN_KEY" '.metadata.annotations[$k] // empty')
[[ "$ANN" == "$ANN_VAL" ]] \
  || fail "Annotation '$ANN_KEY' must be '/' (found: '${ANN:-<none>}')"
ok "Annotation rewrite-target: /"

# -- Host rule: main.example.com → main-site-svc:80 at path / --
HOST_RULE=$(echo "$INGRESS_JSON" | jq -r --arg host "$HOST" '
  .spec.rules[]? | select(.host == $host) | .http.paths[]?
  | select(.path == "/") | "\(.backend.service.name):\(.backend.service.port.number)"
' | head -n1)
[[ "$HOST_RULE" == "main-site-svc:80" ]] \
  || fail "Host rule for '$HOST' must route path '/' to 'main-site-svc:80' (found: '${HOST_RULE:-<none>}')"
ok "Host rule: $HOST / -> main-site-svc:80"

# -- Default backend: error-page-svc:80 --
DEF_SVC=$(echo "$INGRESS_JSON"  | jq -r '.spec.defaultBackend.service.name // empty')
DEF_PORT=$(echo "$INGRESS_JSON" | jq -r '.spec.defaultBackend.service.port.number // empty')
[[ "$DEF_SVC" == "error-page-svc" ]] \
  || fail "defaultBackend service must be 'error-page-svc' (found: '${DEF_SVC:-<none>}')"
[[ "$DEF_PORT" == "80" ]] \
  || fail "defaultBackend service port must be 80 (found: '${DEF_PORT:-<none>}')"
ok "Default backend: error-page-svc:80"

# -- Functional checks --
# Read the NodePort live from the Service every time — never cache it.
# NodePorts are reachable on any node's IP; we use the control-plane node.
NODE_IP=$(kubectl get nodes \
  -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null)

HTTP_PORT=$(kubectl -n ingress-nginx get svc ingress-nginx-controller \
  -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}' 2>/dev/null)

[[ -n "$NODE_IP" ]] \
  || fail "Could not detect node IP"
[[ -n "$HTTP_PORT" ]] \
  || fail "Could not detect Ingress Controller NodePort — is ingress-nginx installed?"
ok "Ingress Controller: $NODE_IP:$HTTP_PORT"

# Allow the controller a moment to sync the newly created Ingress
sleep 4

# Test 1: main.example.com should route to main-site-svc
MAIN_RESP=""
for attempt in 1 2 3; do
  MAIN_RESP=$(curl -s --max-time 8 -H "Host: main.example.com" \
    "http://$NODE_IP:$HTTP_PORT/" 2>/dev/null || true)
  echo "$MAIN_RESP" | grep -qi "main-site" && break
  [[ $attempt -lt 3 ]] && sleep 6
done
echo "$MAIN_RESP" | grep -qi "main-site" \
  || fail "main.example.com did not route to main-site-svc (response: '${MAIN_RESP:0:150}')"
ok "main.example.com routes to main-site-svc"

# Test 2: unknown host should fall through to error-page-svc (default backend)
DEF_RESP=""
for attempt in 1 2 3; do
  DEF_RESP=$(curl -s --max-time 8 -H "Host: unknown.example.com" \
    "http://$NODE_IP:$HTTP_PORT/" 2>/dev/null || true)
  echo "$DEF_RESP" | grep -qi "error-page" && break
  [[ $attempt -lt 3 ]] && sleep 6
done
echo "$DEF_RESP" | grep -qi "error-page" \
  || fail "Unknown host did not route to error-page-svc (default backend) (response: '${DEF_RESP:0:150}')"
ok "Unknown host routes to error-page-svc (default backend)"

pass "Ingress 'site-ingress' is correctly configured: nginx class, rewrite annotation, host rule for main.example.com, and default backend error-page-svc"
