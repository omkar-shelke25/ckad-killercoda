#!/bin/bash
set -euo pipefail

NS="moon"
POD="secret-handler"
S1="secret1"
S2="secret2"
OUT_FILE="/opt/course/14/secret-handler-new.yaml"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."

# Namespace exists
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."

# Secret1 exists with keys user & pass (values test/pwd)
kubectl -n "$NS" get secret "$S1" >/dev/null 2>&1 || fail "Secret '$S1' not found in '$NS'."
U64=$(kubectl -n "$NS" get secret "$S1" -o jsonpath='{.data.user}')
P64=$(kubectl -n "$NS" get secret "$S1" -o jsonpath='{.data.pass}')
[[ -n "$U64" && -n "$P64" ]] || fail "Secret '$S1' must contain keys 'user' and 'pass'."
USER_VAL=$(echo -n "$U64" | base64 -d 2>/dev/null || true)
PASS_VAL=$(echo -n "$P64" | base64 -d 2>/dev/null || true)
[[ "$USER_VAL" == "test" ]] || fail "Secret '$S1'.user must decode to 'test'."
[[ "$PASS_VAL" == "pwd" ]] || fail "Secret '$S1'.pass must decode to 'pwd'."

# Secret2 exists (created from provided YAML)
kubectl -n "$NS" get secret "$S2" >/dev/null 2>&1 || fail "Secret '$S2' not found in '$NS'."

# Pod exists
kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1 || fail "Pod '$POD' not found in '$NS'."
JSON=$(kubectl -n "$NS" get pod "$POD" -o json)

# Env vars from secret1
HAS_USER=$(echo "$JSON" | jq -r '.spec.containers[0].env[]? | select(.name=="SECRET1_USER") | select(.valueFrom.secretKeyRef.name=="secret1" and .valueFrom.secretKeyRef.key=="user") | "yes"' | head -n1)
HAS_PASS=$(echo "$JSON" | jq -r '.spec.containers[0].env[]? | select(.name=="SECRET1_PASS") | select(.valueFrom.secretKeyRef.name=="secret1" and .valueFrom.secretKeyRef.key=="pass") | "yes"' | head -n1)
[[ "$HAS_USER" == "yes" ]] || fail "Env var SECRET1_USER must come from secret1/user."
[[ "$HAS_PASS" == "yes" ]] || fail "Env var SECRET1_PASS must come from secret1/pass."

# Volume mount for secret2 at /tmp/secret2
MOUNT_NAME=$(echo "$JSON" | jq -r '.spec.containers[0].volumeMounts[]? | select(.mountPath=="/tmp/secret2") | .name' | head -n1)
[[ -n "$MOUNT_NAME" ]] || fail "VolumeMount at /tmp/secret2 is missing."
SRC=$(echo "$JSON" | jq -r --arg n "$MOUNT_NAME" '.spec.volumes[]? | select(.name==$n) | .secret.secretName // empty')
[[ "$SRC" == "$S2" ]] || fail "Volume '$MOUNT_NAME' must reference secret '$S2'."

# Pod Ready
kubectl -n "$NS" wait --for=condition=Ready "pod/$POD" --timeout=120s >/dev/null 2>&1 || \
  fail "Pod '$POD' did not become Ready."

# File saved at required path
[[ -f "$OUT_FILE" ]] || fail "Updated YAML not found at $OUT_FILE."

pass "Verification successful! Secrets created, Pod updated with env & volume, and YAML saved."
