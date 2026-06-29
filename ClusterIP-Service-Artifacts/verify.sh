#!/bin/bash
set -uo pipefail

NS="pluto"
POD="project-plt-6cc-api"
SVC="project-plt-6cc-svc"
ART_HTML="/opt/course/10/service_test.html"
ART_LOG="/opt/course/10/service_test.log"

pass() { echo "✅ $1"; }
fail() { echo "❌ $1"; exit 1; }

echo "========================================="
echo "Verifying scenario in namespace '$NS'..."
echo "========================================="

# 1) Namespace
kubectl get ns "$NS" >/dev/null 2>&1 \
  || fail "Namespace '$NS' not found."
pass "Namespace '$NS' exists"

# 2) Pod exists
kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1 \
  || fail "Pod '$POD' not found in '$NS'. Run: kubectl -n $NS run $POD --image=nginx:1.17.3-alpine --labels=project=plt-6cc-api --restart=Never"
pass "Pod '$POD' exists"

# 3) Pod image
IMG="$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[0].image}')"
[ "$IMG" = "nginx:1.17.3-alpine" ] \
  || fail "Pod image is '$IMG', expected 'nginx:1.17.3-alpine'."
pass "Pod image = nginx:1.17.3-alpine"

# 4) Pod label
LBL="$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.metadata.labels.project}')"
[ "$LBL" = "plt-6cc-api" ] \
  || fail "Pod label project='$LBL', expected 'plt-6cc-api'. Add label: --labels=project=plt-6cc-api"
pass "Pod label project=plt-6cc-api"

# 5) Pod ready
kubectl -n "$NS" wait --for=condition=Ready pod/"$POD" --timeout=180s >/dev/null 2>&1 \
  || fail "Pod '$POD' is not Ready. Check: kubectl -n $NS describe pod $POD"
pass "Pod '$POD' is Ready"

# 6) Service exists
kubectl -n "$NS" get svc "$SVC" >/dev/null 2>&1 \
  || fail "Service '$SVC' not found in '$NS'. Expose the pod: kubectl -n $NS expose pod $POD --name=$SVC --port=3333 --target-port=80"
pass "Service '$SVC' exists"

# 7) Service type
TYPE="$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.type}')"
[ "$TYPE" = "ClusterIP" ] \
  || fail "Service type is '$TYPE', expected 'ClusterIP'."
pass "Service type = ClusterIP"

# 8) Service port
PORT="$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.ports[0].port}')"
[ "$PORT" = "3333" ] \
  || fail "Service port is '$PORT', expected '3333'."
pass "Service port = 3333"

# 9) Service targetPort
TPORT="$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.ports[0].targetPort}')"
[ "$TPORT" = "80" ] \
  || fail "Service targetPort is '$TPORT', expected '80'."
pass "Service targetPort = 80"

# 10) Service protocol
PROTO="$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.ports[0].protocol}')"
[ "$PROTO" = "TCP" ] \
  || fail "Service protocol is '$PROTO', expected 'TCP'."
pass "Service protocol = TCP"

# 11) Service selector matches pod label
SEL="$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.selector.project}')"
[ "$SEL" = "plt-6cc-api" ] \
  || fail "Service selector project='$SEL', expected 'plt-6cc-api'. Selector must match the Pod label."
pass "Service selector matches Pod label (project=plt-6cc-api)"

# 12) HTML artifact exists and is non-empty
[ -f "$ART_HTML" ] \
  || fail "File not found: $ART_HTML. Save the HTTP response: kubectl -n $NS exec <client-pod> -- wget -qO- http://$SVC:3333 > $ART_HTML"
[ -s "$ART_HTML" ] \
  || fail "File is empty: $ART_HTML"
pass "HTML artifact exists: $ART_HTML"

# 13) HTML artifact contains actual nginx HTML — hard fail
if ! grep -qiE '<html|<head|<title|nginx' "$ART_HTML"; then
  fail "$ART_HTML does not contain nginx HTML output. Make sure you saved the HTTP response body, not kubectl output."
fi
pass "HTML artifact contains nginx HTML content"

# 14) HTML artifact must not contain kubectl noise
NOISE_PATTERN='pod .* deleted|If you do not see a command prompt|attached|Defaulted container|Waiting for pod|Session ended|Use Ctrl-C|command terminated'
if grep -qiE "$NOISE_PATTERN" "$ART_HTML"; then
  fail "$ART_HTML contains kubectl stderr noise. Redirect only stdout: wget -qO- http://$SVC:3333 > $ART_HTML 2>/dev/null"
fi
pass "HTML artifact is clean (no kubectl noise)"

# 15) Log artifact exists and is non-empty
[ -f "$ART_LOG" ] \
  || fail "File not found: $ART_LOG. Save pod logs: kubectl -n $NS logs $POD > $ART_LOG"
[ -s "$ART_LOG" ] \
  || fail "File is empty: $ART_LOG. The Pod may not have received any requests yet."
pass "Log artifact exists: $ART_LOG"

# 16) Log artifact contains a GET request — hard fail
if ! grep -qiE 'GET /' "$ART_LOG"; then
  fail "$ART_LOG does not contain any GET requests. Make the HTTP request first, then save the logs."
fi
pass "Log artifact contains GET request from nginx access log"

# 17) Log artifact must not contain kubectl noise
if grep -qiE "$NOISE_PATTERN" "$ART_LOG"; then
  fail "$ART_LOG contains kubectl stderr noise. Save logs cleanly: kubectl -n $NS logs $POD > $ART_LOG"
fi
pass "Log artifact is clean (no kubectl noise)"

echo ""
echo "========================================="
pass "All checks passed! Well done. 🚀"
echo "========================================="
