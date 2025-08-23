#!/usr/bin/env bash
set -euo pipefail

NS_SRC="prime"
NS_DST="mars"
POD_NAME="web-app-04"          # the pod that must be migrated
PODS_STAY=(web-app-01 web-app-02 web-app-03 web-app-05 web-app-06)

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# 0) Namespaces exist
kubectl get ns "$NS_SRC" >/dev/null 2>&1 || fail "Namespace '$NS_SRC' not found."
kubectl get ns "$NS_DST" >/dev/null 2>&1 || fail "Namespace '$NS_DST' not found."

# 1) The five correct pods remain in 'prime' and are Ready
for p in "${PODS_STAY[@]}"; do
  kubectl -n "$NS_SRC" get pod "$p" >/dev/null 2>&1 || fail "Expected pod '$p' to remain in '$NS_SRC'."
  kubectl -n "$NS_SRC" wait --for=condition=Ready pod/"$p" --timeout=120s >/dev/null 2>&1 \
    || fail "Pod '$p' not Ready in '$NS_SRC'."
done
pass "Five correct pods remain in '$NS_SRC' and are Ready."

# 2) The pod 'web-app-04' must NOT exist in 'prime' anymore
if kubectl -n "$NS_SRC" get pod "$POD_NAME" >/dev/null 2>&1; then
  fail "Pod '$POD_NAME' still exists in '$NS_SRC'. It must be migrated out."
fi
pass "Pod '$POD_NAME' no longer exists in '$NS_SRC'."

# 3) The pod 'web-app-04' must exist in 'mars', be Ready, and contain container 'mars-container'
kubectl -n "$NS_DST" get pod "$POD_NAME" >/dev/null 2>&1 || fail "Pod '$POD_NAME' not found in '$NS_DST'."
kubectl -n "$NS_DST" wait --for=condition=Ready pod/"$POD_NAME" --timeout=120s >/dev/null 2>&1 \
  || fail "Pod '$POD_NAME' not Ready in '$NS_DST'."

CTR_NAMES="$(kubectl -n "$NS_DST" get pod "$POD_NAME" -o jsonpath='{.spec.containers[*].name}')"
echo "$CTR_NAMES" | tr ' ' '\n' | grep -qx "mars-container" \
  || fail "Pod '$POD_NAME' in '$NS_DST' does not have a container named 'mars-container'."
pass "Pod '$POD_NAME' is present in '$NS_DST', Ready, and has container 'mars-container'."

# 4) Labels on the migrated pod in 'mars' must match what was in 'prime'
APP_LABEL="$(kubectl -n "$NS_DST" get pod "$POD_NAME" -o jsonpath='{.metadata.labels.app}')"
ID_LABEL="$(kubectl -n "$NS_DST" get pod "$POD_NAME" -o jsonpath='{.metadata.labels.id}')"

[ "$APP_LABEL" = "web-app" ] || fail "Expected label app=web-app on '$POD_NAME' in '$NS_DST', found '$APP_LABEL'."
[ "$ID_LABEL" = "web-app-04" ] || fail "Expected label id=web-app-04 on '$POD_NAME' in '$NS_DST', found '$ID_LABEL'."
pass "Migrated pod '$POD_NAME' in '$NS_DST' has correct labels (app=web-app, id=web-app-04)."

# 5) Optional: image sanity check to match setup (does not fail scenario if different)
IMG="$(kubectl -n "$NS_DST" get pod "$POD_NAME" -o jsonpath='{.spec.containers[?(@.name=="mars-container")].image}')"
if [ "$IMG" != "nginx:1.25-alpine" ]; then
  echo "ℹ️ Note: Container 'mars-container' image is '$IMG' (setup used 'nginx:1.25-alpine')."
fi

echo "✅ Verification successful! 'web-app-04' was migrated to 'mars' with correct name and labels; other pods remain in 'prime'."
