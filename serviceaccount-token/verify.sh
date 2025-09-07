#!/bin/bash
set -euo pipefail

NS="neptune"
SA="neptune-sa-v2"
EXPECTED_SECRET="neptune-sa-v2-token"
FILE="/opt/course/5/token"

pass(){ echo "✅ $1"; exit 0; }
fail(){ echo "❌ $1"; exit 1; }

# 1) Namespace & ServiceAccount exist
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."
kubectl -n "$NS" get sa "$SA" >/dev/null 2>&1 || fail "ServiceAccount '$SA' not found in '$NS'."

# 2) Determine Secret name
# Prefer the known secret name created by setup.sh, else fall back to SA.secrets[0].name
if kubectl -n "$NS" get secret "$EXPECTED_SECRET" >/dev/null 2>&1; then
  SECRET="$EXPECTED_SECRET"
else
  # try to read from SA.secrets[0]
  SECRET=$(kubectl -n "$NS" get sa "$SA" -o jsonpath='{.secrets[0].name}' 2>/dev/null || true)
  [[ -n "$SECRET" ]] || fail "Could not find the Secret for ServiceAccount '$SA' (no '$EXPECTED_SECRET' and SA.secrets empty)."
  # ensure the secret actually exists
  kubectl -n "$NS" get secret "$SECRET" >/dev/null 2>&1 || fail "Secret '$SECRET' referenced by ServiceAccount does not exist."
fi

echo "Using Secret: $SECRET"

# 3) Ensure secret contains .data.token
TOKEN_B64=$(kubectl -n "$NS" get secret "$SECRET" -o jsonpath='{.data.token}' 2>/dev/null || true)
[[ -n "$TOKEN_B64" ]] || fail "Secret '$SECRET' does not contain a 'token' in .data.token."

# 4) Decode token
if ! command -v base64 >/dev/null 2>&1; then
  fail "base64 command not found on this host."
fi

# Decode safely (allowing for non-newline)
DECODED_TOKEN=$(echo "$TOKEN_B64" | base64 -d 2>/dev/null || true)
[[ -n "$DECODED_TOKEN" ]] || fail "Failed to base64-decode the token from secret '$SECRET'."

# 5) Ensure file exists and contains the decoded token
if [[ ! -f "$FILE" ]]; then
  fail "File '$FILE' not found. Expected the decoded token to be written there."
fi

FILE_CONTENT=$(cat "$FILE")

if [[ "$FILE_CONTENT" != "$DECODED_TOKEN" ]]; then
  # helpful diagnostic: show trimmed preview (don't print full token)
  echo "=== Diagnostic ==="
  echo "Secret token (decoded) first 64 chars: ${DECODED_TOKEN:0:64}"
  echo "File content first 64 chars: ${FILE_CONTENT:0:64}"
  echo "=================="
  fail "Content of '$FILE' does not match decoded token from secret '$SECRET'."
fi

# 6) Quick sanity check: decoded token should look like a JWT (contain 2 dots)
if [[ $(echo "$DECODED_TOKEN" | awk -F'.' '{print NF-1}') -lt 2 ]]; then
  echo "Warning: decoded token does not look like a JWT (does not contain two '.' characters)."
  # not a hard fail — some clusters may issue other token formats
fi

echo "Secret '$SECRET' contains a token and it matches the file '$FILE'."

pass "Verification successful: decoded token saved to $FILE."
