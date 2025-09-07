#!/bin/bash
set -euo pipefail

NS="neptune"
SA="neptune-sa-v2"
FILE="/opt/course/5/token"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# 1) Namespace and SA exist
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."
kubectl -n "$NS" get sa "$SA" >/dev/null 2>&1 || fail "ServiceAccount '$SA' not found in '$NS'."

# 2) Secret exists
SECRET=$(kubectl -n "$NS" get sa "$SA" -o jsonpath='{.secrets[0].name}')
[[ -n "$SECRET" ]] || fail "No secret found for ServiceAccount '$SA'."

# 3) Token data exists in Secret
TOKEN=$(kubectl -n "$NS" get secret "$SECRET" -o jsonpath='{.data.token}')
[[ -n "$TOKEN" ]] || fail "Secret '$SECRET' has no token data."

# 4) File exists with decoded content
[[ -f "$FILE" ]] || fail "File '$FILE' not found."
if grep -q "eyJ" "$FILE"; then
  fail "File '$FILE' still looks base64 encoded."
fi

pass "Decoded token successfully saved to $FILE."
