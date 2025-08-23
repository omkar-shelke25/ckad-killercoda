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

# Artifacts exist and look sane
[ -f "$ART_HTML" ] || fail "Missing artifact: $ART_HTML"
[ -s "$ART_HTML" ] || fail "Artifact is empty: $ART_HTML"
# try to find some nginx/html-ish content
grep -qiE "nginx|html|welcome" "$ART_HTML" || echo "ℹ️ Note: $ART_HTML content not matched, continuing."

[ -f "$ART_LOG" ] || fail "Missing artifact: $ART_LOG"
[ -s "$ART_LOG" ] || fail "Artifact is empty: $ART_LOG"
# look for a GET access line
grep -qi "GET /" "$ART_LOG" || echo "ℹ️ Note: 'GET /' not found in $ART_LOG, log format may differ."

pass "Artifacts found and non-empty."

echo "✅ Verification successful! Pod, Service, and artifacts meet requirements."
