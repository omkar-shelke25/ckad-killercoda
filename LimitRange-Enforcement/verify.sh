#!/bin/bash
set -euo pipefail

NS="team-a"
LR="mem-limit-range"
POD="busy-pod"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# 1) Namespace exists
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."

# 2) LimitRange exists
kubectl -n "$NS" get limitrange "$LR" >/dev/null 2>&1 || fail "LimitRange '$LR' not found in '$NS'."

# Pull all limit entries and find the one with type=Container
LINES=$(kubectl -n "$NS" get limitrange "$LR" -o jsonpath='{range .spec.limits[*]}{.type}{"|"}{.min.memory}{"|"}{.max.memory}{"|"}{.defaultRequest.memory}{"|"}{.default.memory}{"\n"}{end}')
MATCH=""
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  IFS='|' read -r TYPE MIN MAX DEFREQ DEF <<<"$line"
  if [[ "$TYPE" == "Container" ]]; then
    MATCH="$line"
    break
  fi
done <<< "$LINES"

[[ -n "$MATCH" ]] || fail "No 'Container' type entry found in LimitRange '$LR'."

IFS='|' read -r _ MIN MAX DEFREQ DEF <<<"$MATCH"

[[ "$MIN" == "64Mi" ]]   || fail "LimitRange min.memory must be 64Mi (found '$MIN')."
[[ "$MAX" == "512Mi" ]]  || fail "LimitRange max.memory must be 512Mi (found '$MAX')."
[[ "$DEFREQ" == "128Mi" ]] || fail "LimitRange defaultRequest.memory must be 128Mi (found '$DEFREQ')."
[[ "$DEF" == "256Mi" ]]  || fail "LimitRange default.memory must be 256Mi (found '$DEF')."

# 3) Pod exists and is Ready
kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1 || fail "Pod '$POD' not found in '$NS'."
kubectl -n "$NS" wait --for=condition=Ready "pod/$POD" --timeout=120s >/dev/null 2>&1 || \
  fail "Pod '$POD' did not become Ready."

# 4) Pod inherited defaults: requests.memory=128Mi, limits.memory=256Mi
REQ_MEM=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[0].resources.requests.memory}')
LIM_MEM=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[0].resources.limits.memory}')

[[ "$REQ_MEM" == "128Mi" ]] || fail "Pod must have defaulted requests.memory=128Mi (found '$REQ_MEM')."
[[ "$LIM_MEM" == "256Mi"  ]] || fail "Pod must have defaulted limits.memory=256Mi (found '$LIM_MEM')."

pass "Verification successful! LimitRange is correct and Pod inherited defaults (128Mi/256Mi) and is Ready."
