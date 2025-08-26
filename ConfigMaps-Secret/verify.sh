#!/bin/bash
set -euo pipefail

NS="api"
CM1="frontend-config"
CM2="backend-config"
SECRET="api-secret"
POD="complex-pod"
IMG="nginx:1.29.0"

expect_title="Frontend"
expect_endpoint="http://backend.local"
expect_key="12345"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."

# 0) Namespace exists
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."

# 1) ConfigMaps exist with values
kubectl -n "$NS" get cm "$CM1" >/dev/null 2>&1 || fail "ConfigMap '$CM1' not found."
kubectl -n "$NS" get cm "$CM2" >/dev/null 2>&1 || fail "ConfigMap '$CM2' not found."
title=$(kubectl -n "$NS" get cm "$CM1" -o jsonpath='{.data.TITLE}')
endpoint=$(kubectl -n "$NS" get cm "$CM2" -o jsonpath='{.data.ENDPOINT}')
[[ "$title" == "$expect_title" ]] || fail "frontend-config TITLE must be '$expect_title' (found '$title')."
[[ "$endpoint" == "$expect_endpoint" ]] || fail "backend-config ENDPOINT must be '$expect_endpoint' (found '$endpoint')."

# 2) Secret exists with API_KEY
kubectl -n "$NS" get secret "$SECRET" >/dev/null 2>&1 || fail "Secret '$SECRET' not found."
# ensure data key exists (we don't print it decoded to avoid leaking secrets)
has_key=$(kubectl -n "$NS" get secret "$SECRET" -o json | jq -r '.data["API_KEY"] // empty')
[[ -n "$has_key" ]] || fail "Secret '$SECRET' missing key 'API_KEY'."

# 3) Pod exists, image correct, and Ready
kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1 || fail "Pod '$POD' not found in '$NS'."
pimg=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[0].image}')
[[ "$pimg" == "$IMG" ]] || fail "Pod image must be '$IMG' (found '$pimg')."
kubectl -n "$NS" wait --for=condition=Ready "pod/$POD" --timeout=120s >/dev/null 2>&1 || fail "Pod '$POD' did not become Ready."

# 4) Spec injects env via envFrom for both CMs and Secret
JSON=$(kubectl -n "$NS" get pod "$POD" -o json)
has_cm1=$(echo "$JSON" | jq -r '.spec.containers[0].envFrom[]? | select(.configMapRef.name=="'"$CM1"'") | "yes"' | head -n1)
has_cm2=$(echo "$JSON" | jq -r '.spec.containers[0].envFrom[]? | select(.configMapRef.name=="'"$CM2"'") | "yes"' | head -n1)
has_sec=$(echo "$JSON" | jq -r '.spec.containers[0].envFrom[]? | select(.secretRef.name=="'"$SECRET"'") | "yes"' | head -n1)
[[ "$has_cm1" == "yes" ]] || fail "Pod must envFrom configMap '$CM1'."
[[ "$has_cm2" == "yes" ]] || fail "Pod must envFrom configMap '$CM2'."
[[ "$has_sec" == "yes" ]] || fail "Pod must envFrom secret '$SECRET'."

# 5) Runtime env contains expected values (TITLE, ENDPOINT, API_KEY)
out=$(kubectl -n "$NS" exec "$POD" -- sh -c 'echo "TITLE=$TITLE"; echo "ENDPOINT=$ENDPOINT"; echo "API_KEY=$API_KEY"')
echo "$out" | grep -q "^TITLE=$expect_title$"     || fail "TITLE env mismatch. Got: $(echo "$out" | grep '^TITLE=')"
echo "$out" | grep -q "^ENDPOINT=$expect_endpoint$" || fail "ENDPOINT env mismatch. Got: $(echo "$out" | grep '^ENDPOINT=')"
echo "$out" | grep -q "^API_KEY=$expect_key$"        || fail "API_KEY env mismatch. Got: $(echo "$out" | grep '^API_KEY=')"

pass "Verification successful! Pod has env vars from both ConfigMaps and the Secret."
