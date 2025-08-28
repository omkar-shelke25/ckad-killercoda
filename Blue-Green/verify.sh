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

# 2) BLUE checks
kubectl -n "$NS" get deploy "$DEP_BLUE" >/dev/null 2>&1 || fail "Missing deployment '$DEP_BLUE'."
BIMG="$(kubectl -n "$NS" get deploy "$DEP_BLUE" -o jsonpath='{.spec.template.spec.containers[0].image}')"
[[ "$BIMG" == "$IMG_BLUE" ]] || fail "Expected BLUE image '$IMG_BLUE' (found '$BIMG')."
BREP="$(kubectl -n "$NS" get deploy "$DEP_BLUE" -o jsonpath='{.spec.replicas}')"
[[ "$BREP" == "$REPL" ]] || fail "Expected BLUE replicas=$REPL (found '$BREP')."

# 3) GREEN checks
kubectl -n "$NS" get deploy "$DEP_GREEN" >/dev/null 2>&1 || fail "Missing deployment '$DEP_GREEN'."
GIMG="$(kubectl -n "$NS" get deploy "$DEP_GREEN" -o jsonpath='{.spec.template.spec.containers[0].image}')"
[[ "$GIMG" == "$IMG_GREEN" ]] || fail "Expected GREEN image '$IMG_GREEN' (found '$GIMG')."
GREP="$(kubectl -n "$NS" get deploy "$DEP_GREEN" -o jsonpath='{.spec.replicas}')"
[[ "$GREP" == "$REPL" ]] || fail "Expected GREEN replicas=$REPL (found '$GREP')."

# 4) Service selects GREEN
kubectl -n "$NS" get svc "$SVC" >/dev/null 2>&1 || fail "Missing Service '$SVC'."
SEL_APP="$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.selector.app}')"
SEL_COLOR="$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.selector.color}')"
[[ "$SEL_APP" == "web-app" ]] || fail "Service selector 'app' must be 'web-app' (found '$SEL_APP')."
[[ "$SEL_COLOR" == "green" ]] || fail "Service selector 'color' must be 'green' (found '$SEL_COLOR')."

# 5) Rollouts ready
kubectl -n "$NS" rollout status "deploy/$DEP_BLUE"  --timeout=180s >/dev/null 2>&1 || fail "BLUE rollout not Ready."
kubectl -n "$NS" rollout status "deploy/$DEP_GREEN" --timeout=180s >/dev/null 2>&1 || fail "GREEN rollout not Ready."

# 6) Running GREEN pods behind selector
RUNNING_GREEN="$(kubectl -n "$NS" get pods -l app=web-app,color=green \
  --field-selector=status.phase=Running --no-headers | wc -l | xargs)"
[[ "$RUNNING_GREEN" -ge 1 ]] || fail "No running GREEN pods found behind the Service selector."

# 7) (Bonus) Ensure Service has endpoints
EP_COUNT="$(kubectl -n "$NS" get endpoints "$SVC" -o jsonpath='{range .subsets[*].addresses[*]}1{end}' 2>/dev/null | wc -c | xargs)"
[[ -n "$EP_COUNT" && "$EP_COUNT" -gt 0 ]] || fail "Service '$SVC' has no ready endpoints."

pass "Verification successful! BLUE (nginx:1.19, 3) & GREEN (nginx:1.20, 3) exist; Service routes to GREEN; rollouts Ready; GREEN pods running."
