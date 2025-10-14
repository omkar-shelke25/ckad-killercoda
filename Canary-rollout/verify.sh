#!/bin/bash
set -euo pipefail

NS="default"
DEP_STABLE="frontend"
DEP_CANARY="frontend-canary"
IMG_STABLE="nginx:1.19"
IMG_CANARY="nginx:1.20"
SVC="frontend-svc"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# 1) Stable deployment exists, correct image & replicas (4)
kubectl -n "$NS" get deploy "$DEP_STABLE" >/dev/null 2>&1 || fail "Missing Deployment '$DEP_STABLE'."
STABLE_IMG="$(kubectl -n "$NS" get deploy "$DEP_STABLE" -o jsonpath='{.spec.template.spec.containers[0].image}')"
[[ "$STABLE_IMG" == "$IMG_STABLE" ]] || fail "Stable image must be '$IMG_STABLE' (found '$STABLE_IMG')."
STABLE_REP="$(kubectl -n "$NS" get deploy "$DEP_STABLE" -o jsonpath='{.spec.replicas}')"
[[ "$STABLE_REP" == "4" ]] || fail "Stable replicas must be 4 (found '$STABLE_REP')."

# 2) Canary deployment exists, correct image & replicas (1)
kubectl -n "$NS" get deploy "$DEP_CANARY" >/dev/null 2>&1 || fail "Missing Deployment '$DEP_CANARY'."
CANARY_IMG="$(kubectl -n "$NS" get deploy "$DEP_CANARY" -o jsonpath='{.spec.template.spec.containers[0].image}')"
[[ "$CANARY_IMG" == "$IMG_CANARY" ]] || fail "Canary image must be '$IMG_CANARY' (found '$CANARY_IMG')."
CANARY_REP="$(kubectl -n "$NS" get deploy "$DEP_CANARY" -o jsonpath='{.spec.replicas}')"
[[ "$CANARY_REP" == "1" ]] || fail "Canary replicas must be 1 (found '$CANARY_REP')."

# --- Begin: Validate canary template & pod label version:v2 ---
# 2.a) Canary deployment template must include label version=v2
TEMPLATE_VER="$(kubectl -n "$NS" get deploy "$DEP_CANARY" -o jsonpath='{.spec.template.metadata.labels.version}' 2>/dev/null || true)"
[[ "$TEMPLATE_VER" == "v2" ]] || fail "Canary deployment template must have label version=v2 (found '$TEMPLATE_VER')."

# 2.b) At least one pod with labels app=frontend AND version=v2 must exist
POD_V2="$(kubectl -n "$NS" get pods -l app=frontend,version=v2 -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
[[ -n "$POD_V2" ]] || fail "No pod found with labels app=frontend and version=v2."

# 2.c) That pod must be running the canary image (nginx:1.20)
POD_V2_IMG="$(kubectl -n "$NS" get pod "$POD_V2" -o jsonpath='{.spec.containers[0].image}' 2>/dev/null || true)"
[[ "$POD_V2_IMG" == "$IMG_CANARY" ]] || fail "Pod $POD_V2 must have image $IMG_CANARY (found '$POD_V2_IMG')."
# --- End: Validate canary template & pod label version:v2 ---

# 3) Service exists and selects app=frontend
kubectl -n "$NS" get svc "$SVC" >/dev/null 2>&1 || fail "Missing Service '$SVC'."
SEL_APP="$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.selector.app}' 2>/dev/null || true)"
[[ "$SEL_APP" == "frontend" ]] || fail "Service '$SVC' must select app=frontend."

# 3.a) Optional: warn if service selector includes version (which would filter traffic)
SEL_VER="$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.selector.version}' 2>/dev/null || true)"
if [[ -n "$SEL_VER" ]]; then
  echo "⚠️  Warning: Service '$SVC' selector includes version=$SEL_VER — this may route only one version."
fi

# 4) Pods behind Service include both images
PODS_IMAGES="$(kubectl -n "$NS" get pods -l app=frontend -o jsonpath='{range .items[*]}{.metadata.name} {"->"} {.spec.containers[0].image}{"\n"}{end}')"
echo "Pods with app=frontend and their images:"
echo "$PODS_IMAGES"
echo

echo "$PODS_IMAGES" | grep -q "$IMG_STABLE" || fail "No stable pods with image $IMG_STABLE found."
echo "$PODS_IMAGES" | grep -q "$IMG_CANARY" || fail "No canary pods with image $IMG_CANARY found."

# 5) Readiness check (rollout status should be ready)
kubectl -n "$NS" rollout status deploy/"$DEP_STABLE" --timeout=180s >/dev/null 2>&1 || fail "Stable rollout not ready."
kubectl -n "$NS" rollout status deploy/"$DEP_CANARY" --timeout=180s >/dev/null 2>&1 || fail "Canary rollout not ready."

pass "Verification successful! Stable=4 (nginx:1.19) + Canary=1 (nginx:1.20) behind Service '$SVC' → ~20% canary traffic."
