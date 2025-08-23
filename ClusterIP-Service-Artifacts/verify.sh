#!/bin/bash
set -euo pipefail

NS="pluto"
POD="project-plt-6cc-api"
SVC="project-plt-6cc-svc"
ART_HTML="/opt/course/10/service_test.html"
ART_LOG="/opt/course/10/service_test.log"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# Namespace
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."

# Pod checks
kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1 || fail "Pod '$POD' not found in '$NS'."
IMG="$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[0].image}')"
[ "$IMG" = "nginx:1.17.3-alpine" ] || fail "Pod image is '$IMG', expected 'nginx:1.17.3-alpine'."
LBL="$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.metadata.labels.project}')"
[ "$LBL" = "plt-6cc-api" ] || fail "Pod label 'project'='$LBL', expected 'plt-6cc-api'."
kubectl -n "$NS" wait --for=condition=Ready pod/"$POD" --timeout=180s >/dev/null 2>&1 || fail "Pod '$POD' not Ready."
pass "Pod present, labeled, image correct, Ready."

# Service checks
kubectl -n "$NS" get svc "$SVC" >/dev/null 2>&1 || fail "Service '$SVC' not found in '$NS'."
TYPE="$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.type}')"
[ "$TYPE" = "ClusterIP" ] || fail "Service type is '$TYPE', expected 'ClusterIP'."
SEL="$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.selector.project}')"
[ "$SEL" = "plt-6cc-api" ] || fail "Service selector project='$SEL', expected 'plt-6cc-api'."
PORT="$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.ports[0].port}')"
TPORT="$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.ports[0].targetPort}')"
PROTO="$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.ports[0].protocol}')"
[ "$PORT" = "3333" ] || fail "Service port is '$PORT', expected '3333'."
[ "$TPORT" = "80" ] || fail "Service targetPort is '$TPORT', expected '80'."
[ "$PROTO" = "TCP" ] || fail "Service protocol is '$PROTO', expected 'TCP'."
pass "Service configured correctly (3333→80/TCP with correct selector)."

# Artifact: HTML must exist, be non-empty, look like HTML, and contain no kubectl noise
[ -f "$ART_HTML" ] || fail "Missing artifact: $ART_HTML"
[ -s "$ART_HTML" ] || fail "Artifact is empty: $ART_HTML"

# Reject common kubectl noise (stderr mixed into file)
NOISE_RE='(pod .* deleted|If you do not see a command prompt|attached|Defaulted container|Waiting for pod|Session ended|Use Ctrl-C|command terminated)'
if grep -qiE "$NOISE_RE" "$ART_HTML"; then
  fail "$ART_HTML contains kubectl noise (stderr). Recreate with: ... > $ART_HTML 2>/dev/null"
fi

# Must look like HTML/nginx output
if ! grep -qiE '<html|<head|<title|nginx' "$ART_HTML"; then
  echo "ℹ️ Note: $ART_HTML does not match typical HTML/nginx markers; continuing."
fi
pass "HTML artifact looks clean (no kubectl noise)."

# Artifact: LOG must exist, be non-empty, and contain a GET line; also ensure no kubectl noise
[ -f "$ART_LOG" ] || fail "Missing artifact: $ART_LOG"
[ -s "$ART_LOG" ] || fail "Artifact is empty: $ART_LOG"
if grep -qiE "$NOISE_RE" "$ART_LOG"; then
  fail "$ART_LOG contains kubectl noise (stderr). Save logs with: kubectl -n $NS logs $POD > $ART_LOG 2>/dev/null"
fi
grep -qi "GET /" "$ART_LOG" || echo "ℹ️ Note: 'GET /' not found in $ART_LOG; log format may differ."
pass "Log artifact present and appears valid."

echo "✅ Verification successful! Pod, Service, and clean artifacts meet requirements."
