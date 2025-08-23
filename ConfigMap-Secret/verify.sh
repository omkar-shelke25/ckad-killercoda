#!/bin/bash
set -euo pipefail

NS="apps"
CM="app-config"
SK="api-credentials"
POD="app-pod"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# Namespace
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."

# ConfigMap exists with correct key/value
kubectl get configmap "$CM" -n "$NS" >/dev/null 2>&1 || fail "ConfigMap '$CM' not found in '$NS'."
DB_KEY="$(kubectl get configmap "$CM" -n "$NS" -o jsonpath='{.data}' | jq -r 'keys[]' 2>/dev/null | grep -E '^database\.url$' || true)"
[ "$DB_KEY" = "database.url" ] || fail "Expected ConfigMap key 'database.url' not found in '$CM'."
DB_URL="$(kubectl get configmap "$CM" -n "$NS" -o jsonpath='{.data.database\.url}')"
[ "$DB_URL" = "postgres://db.example.com:5432/production" ] || fail "ConfigMap[$CM].database.url='$DB_URL', expected 'postgres://db.example.com:5432/production'."
pass "ConfigMap '$CM' has database.url with correct value."

# Secret exists with correct key/value
kubectl get secret "$SK" -n "$NS" >/dev/null 2>&1 || fail "Secret '$SK' not found in '$NS'."
API_KEY_NAME="$(kubectl get secret "$SK" -n "$NS" -o jsonpath='{.data}' | jq -r 'keys[]' 2>/dev/null | grep -E '^api\.key$' || true)"
[ "$API_KEY_NAME" = "api.key" ] || fail "Expected Secret key 'api.key' not found in '$SK'."
API_B64="$(kubectl get secret "$SK" -n "$NS" -o jsonpath='{.data.api\.key}')"
API_VAL="$(printf "%s" "$API_B64" | base64 -d 2>/dev/null || true)"
[ "$API_VAL" = "s3cr3t-ap1-k3y-f0r-pr0d" ] || fail "Secret[$SK].api.key decoded='$API_VAL', expected 's3cr3t-ap1-k3y-f0r-pr0d'."
pass "Secret '$SK' has api.key with correct value."

# Pod exists and becomes Ready
kubectl get pod "$POD" -n "$NS" >/dev/null 2>&1 || fail "Pod '$POD' not found in '$NS'."
kubectl wait --for=condition=Ready pod/"$POD" -n "$NS" --timeout=120s >/dev/null 2>&1 || fail "Pod '$POD' did not reach Ready."
pass "Pod '$POD' is Ready."

# Verify env vars are present inside the running container
DB_ENV="$(kubectl exec -n "$NS" "$POD" -- sh -c 'echo -n "$DATABASE_URL"')"
[ "$DB_ENV" = "postgres://db.example.com:5432/production" ] || fail "Env DATABASE_URL='$DB_ENV', expected 'postgres://db.example.com:5432/production'."

API_ENV="$(kubectl exec -n "$NS" "$POD" -- sh -c 'echo -n "$API_KEY"')"
[ "$API_ENV" = "s3cr3t-ap1-k3y-f0r-pr0d" ] || fail "Env API_KEY='$API_ENV', expected 's3cr3t-ap1-k3y-f0r-pr0d'."

pass "Environment variables resolved correctly inside the Pod."

echo "✅ Verification successful! ConfigMap, Secret, and Pod env wiring are correct."
