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

# 3) Service exists and selects app=frontend
kubectl -n "$NS" get svc "$SVC" >/dev/null 2>&1 || fail "Missing Service '$SVC'."
SEL_APP="$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.selector.app}')"
[[ "$SEL_APP" == "frontend" ]] || fail "Service '$SVC' must select app=frontend."

# 4) Pods behind Service include both images
PODS_IMAGES="$(kubectl -n "$NS" get pods -l app=frontend -o jsonpath='{range .items[*]}{.spec.containers[0].image}{"\n"}{end}')"
echo "$PODS_IMAGES" | grep -q "$IMG_STABLE" || fail "No stable pods with image $IMG_STABLE found."
echo "$PODS_IMAGES" | grep -q "$IMG_CANARY" || fail "No canary pods with image $IMG_CANARY found."

# 5) Readiness check (endpoints should be >0)
kubectl -n "$NS" rollout status deploy/"$DEP_STABLE" --timeout=180s >/dev/null 2>&1 || fail "Stable rollout not ready."
kubectl -n "$NS" rollout status deploy/"$DEP_CANARY" --timeout=180s >/dev/null 2>&1 || fail "Canary rollout not ready."

pass "Verification successful! Stable=4 (nginx:1.19) + Canary=1 (nginx:1.20) behind Service '$SVC' → ~20% canary traffic."
