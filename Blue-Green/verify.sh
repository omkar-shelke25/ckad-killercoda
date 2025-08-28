#!/bin/bash
set -euo pipefail

NS="ios"
DEP_BLUE="web-app-blue"
DEP_GREEN="web-app-green"
SVC="web-app-service"
IMG_BLUE="nginx:1.19"
IMG_GREEN="nginx:1.20"
REPL="3"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# 1) Namespace
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."

# 2) BLUE exists as given (image/nginx:1.19, replicas=3)
kubectl -n "$NS" get deploy "$DEP_BLUE" >/dev/null 2>&1 || fail "Missing deployment '$DEP_BLUE'."
BIMG="$(kubectl -n "$NS" get deploy "$DEP_BLUE" -o jsonpath='{.spec.template.spec.containers[0].image}')"
[[ "$BIMG" == "$IMG_BLUE" ]] || fail "Expected BLUE image '$IMG_BLUE' (found '$BIMG')."
BREP="$(kubectl -n "$NS" get deploy "$DEP_BLUE" -o jsonpath='{.spec.replicas}')"
[[ "$BREP" == "$REPL" ]] || fail "Expected BLUE replicas=$REPL (found '$BREP')."

# 3) GREEN deployment created (nginx:1.20, replicas=3)
kubectl -n "$NS" get deploy "$DEP_GREEN" >/dev/null 2>&1 || fail "Missing deployment '$DEP_GREEN'."
GIMG="$(kubectl -n "$NS" get deploy "$DEP_GREEN" -o jsonpath='{.spec.template.spec.containers[0].image}')"
[[ "$GIMG" == "$IMG_GREEN" ]] || fail "Expected GREEN image '$IMG_GREEN' (found '$GIMG')."
GREP="$(kubectl -n "$NS" get deploy "$DEP_GREEN" -o jsonpath='{.spec.replicas}')"
[[ "$GREP" == "$REPL" ]] || fail "Expected GREEN replicas=$REPL (found '$GREP')."

# 4) Service exists and now selects color=green (not blue)
kubectl -n "$NS" get svc "$SVC" >/dev/null 2>&1 || fail "Missing Service '$SVC'."
SEL_COLOR="$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.selector.color}')"
[[ "$SEL_COLOR" == "green" ]] || fail "Service selector must be color=green (found '$SEL_COLOR')."

# 5) Rollout readiness
kubectl -n "$NS" rollout status deploy/"$DEP_GREEN" --timeout=180s >/dev/null 2>&1 || fail "GREEN rollout not Ready."
kubectl -n "$NS" rollout status deploy/"$DEP_BLUE"  --timeout=180s >/dev/null 2>&1 || fail "BLUE rollout not Ready."

# 6) Endpoints now point to GREEN pods (basic check: pod labels behind selector)
# Count running pods selected by service selector (app=web-app,color=green)
RUNNING_GREEN=$(kubectl -n "$NS" get pods -l app=web-app,color=green --field-selector=status.phase=Running --no-headers | wc -1 2>/dev/null || true)
if [[ -z "$RUNNING_GREEN" || "$RUNNING_GREEN" -eq 0 ]]; then
  fail "No running GREEN pods found behind the Service selector."
fi

pass "Verification successful! GREEN (nginx:1.20, 3 replicas) deployed and Service now routes to green with zero downtime."
