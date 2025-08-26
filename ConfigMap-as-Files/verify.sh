#!/bin/bash
set -euo pipefail

NS="default"
CM="html-config"
POD="web-pod"
IMG="nginx:1.29.0"
HTML_DIR="/usr/share/nginx/html"
IDX_CONTENT="<h1>Welcome to Kubernetes</h1>"
ERR_CONTENT="<h1>Error Page</h1>"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."

# 1) ConfigMap exists and has required keys/values
kubectl -n "$NS" get cm "$CM" >/dev/null 2>&1 || fail "ConfigMap '$CM' not found in namespace '$NS'."
DATA=$(kubectl -n "$NS" get cm "$CM" -o json)
IDX=$(echo "$DATA" | jq -r '.data["index.html"] // empty')
ERR=$(echo "$DATA" | jq -r '.data["error.html"] // empty')
[[ "$IDX" == "$IDX_CONTENT" ]] || fail "index.html content mismatch in ConfigMap."
[[ "$ERR" == "$ERR_CONTENT" ]] || fail "error.html content mismatch in ConfigMap."

# 2) Pod exists and uses correct image
kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1 || fail "Pod '$POD' not found in namespace '$NS'."
PIMG=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[0].image}')
[[ "$PIMG" == "$IMG" ]] || fail "Pod image must be '$IMG' (found '$PIMG')."

# 3) Pod Ready
kubectl -n "$NS" wait --for=condition=Ready "pod/$POD" --timeout=90s >/dev/null 2>&1 || \
  fail "Pod '$POD' did not become Ready."

# 4) Volume mount points to ConfigMap at correct path
JSON=$(kubectl -n "$NS" get pod "$POD" -o json)
MOUNT_NAME=$(echo "$JSON" | jq -r ".spec.containers[0].volumeMounts[]? | select(.mountPath==\"$HTML_DIR\") | .name" | head -n1)
[[ -n "$MOUNT_NAME" ]] || fail "No volumeMount at $HTML_DIR found."
SRC_CM=$(echo "$JSON" | jq -r --arg n "$MOUNT_NAME" '.spec.volumes[]? | select(.name==$n) | .configMap.name // empty')
[[ "$SRC_CM" == "$CM" ]] || fail "Mounted volume '$MOUNT_NAME' must reference ConfigMap '$CM'."

# 5) Files exist in container with correct contents
IDX_IN=$(kubectl -n "$NS" exec "$POD" -- sh -c "cat $HTML_DIR/index.html" || true)
ERR_IN=$(kubectl -n "$NS" exec "$POD" -- sh -c "cat $HTML_DIR/error.html" || true)
[[ "$IDX_IN" == "$IDX_CONTENT" ]] || fail "Container index.html content mismatch."
[[ "$ERR_IN" == "$ERR_CONTENT" ]] || fail "Container error.html content mismatch."

pass "Verification successful! ConfigMap files are correctly mounted into '$POD'."
