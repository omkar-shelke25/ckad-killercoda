#!/bin/bash
set -euo pipefail

NS="security"
SECRET_NAME="tls-secret"
POD="secure-pod"
IMG="redis:8.0.2"
MOUNT="/etc/tls"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."

# 0) Namespace exists
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."

# 1) Secret exists and is type kubernetes.io/tls
kubectl -n "$NS" get secret "$SECRET_NAME" >/dev/null 2>&1 || fail "Secret '$SECRET_NAME' not found in '$NS'."
TYPE=$(kubectl -n "$NS" get secret "$SECRET_NAME" -o jsonpath='{.type}')
[[ "$TYPE" == "kubernetes.io/tls" ]] || fail "Secret '$SECRET_NAME' must be type 'kubernetes.io/tls' (found '$TYPE')."

# 2) Secret has tls.crt and tls.key data
HAS_CRT=$(kubectl -n "$NS" get secret "$SECRET_NAME" -o json | jq -r '.data["tls.crt"] // empty')
HAS_KEY=$(kubectl -n "$NS" get secret "$SECRET_NAME" -o json | jq -r '.data["tls.key"] // empty')
[[ -n "$HAS_CRT" ]] || fail "Secret '$SECRET_NAME' missing key 'tls.crt'."
[[ -n "$HAS_KEY" ]] || fail "Secret '$SECRET_NAME' missing key 'tls.key'."

# 3) Pod exists, correct image, and ready
kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1 || fail "Pod '$POD' not found in '$NS'."
PIMG=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[0].image}')
[[ "$PIMG" == "$IMG" ]] || fail "Pod image must be '$IMG' (found '$PIMG')."
kubectl -n "$NS" wait --for=condition=Ready "pod/$POD" --timeout=120s >/dev/null 2>&1 || fail "Pod '$POD' did not become Ready."

# 4) Volume mount points to the Secret at /etc/tls
JSON=$(kubectl -n "$NS" get pod "$POD" -o json)
MOUNT_NAME=$(echo "$JSON" | jq -r '.spec.containers[0].volumeMounts[]? | select(.mountPath=="/etc/tls") | .name' | head -n1)
[[ -n "$MOUNT_NAME" ]] || fail "No volumeMount at /etc/tls found."
SRC_SECRET=$(echo "$JSON" | jq -r --arg n "$MOUNT_NAME" '.spec.volumes[]? | select(.name==$n) | .secret.secretName // empty')
[[ "$SRC_SECRET" == "$SECRET_NAME" ]] || fail "Mounted volume '$MOUNT_NAME' must reference Secret '$SECRET_NAME'."

# 5) Files exist in container
kubectl -n "$NS" exec "$POD" -- sh -c 'test -f /etc/tls/tls.crt' || fail "File /etc/tls/tls.crt not found in container."
kubectl -n "$NS" exec "$POD" -- sh -c 'test -f /etc/tls/tls.key' || fail "File /etc/tls/tls.key not found in container."

pass "Verification successful! TLS Secret is correctly mounted into '$POD'."
