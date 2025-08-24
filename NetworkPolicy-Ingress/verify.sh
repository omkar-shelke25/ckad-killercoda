#!/bin/bash
set -euo pipefail
NS="netpol-demo6"
NP="internal-only"
pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# 0) Prereqs
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."
kubectl -n "$NS" get pod pod-a >/dev/null 2>&1 || fail "Pod 'pod-a' not found in '$NS'."
kubectl -n "$NS" get pod pod-b >/dev/null 2>&1 || fail "Pod 'pod-b' not found in '$NS'."
kubectl -n "$NS" wait --for=condition=Ready pod/pod-a --timeout=120s >/dev/null 2>&1 || fail "pod-a not Ready."
kubectl -n "$NS" wait --for=condition=Ready pod/pod-b --timeout=120s >/dev/null 2>&1 || fail "pod-b not Ready."
pass "Prerequisite pods are Ready."

# 1) NetworkPolicy exists
kubectl -n "$NS" get networkpolicy "$NP" >/dev/null 2>&1 || fail "NetworkPolicy '$NP' not found in '$NS'."

# 2) Structural checks (matches all pods, ingress only, from same-namespace pods)
POLICY_TYPES="$(kubectl -n "$NS" get networkpolicy "$NP" -o jsonpath='{.spec.policyTypes[*]}')"
echo "$POLICY_TYPES" | grep -qw "Ingress" || fail "policyTypes must include 'Ingress'."

# podSelector must be empty {} to select all pods
SEL_KEYS="$(kubectl -n "$NS" get networkpolicy "$NP" -o jsonpath='{.spec.podSelector}')"
[ "$SEL_KEYS" = "map[]" ] || [ "$SEL_KEYS" = "{}" ] || fail "spec.podSelector should select all pods ({}). Found: $SEL_KEYS"

# Ingress.from should include a same-namespace podSelector
# Fixed: Use \n instead of literal newline in jsonpath
FROM_BLOCKS="$(kubectl -n "$NS" get networkpolicy "$NP" -o jsonpath='{range .spec.ingress[*].from[*]}{.podSelector}{"\n"}{end}')"
echo "$FROM_BLOCKS" | grep -q "map\[\]" || echo "$FROM_BLOCKS" | grep -q "{}" || fail "ingress.from must include a same-namespace podSelector ({})."
pass "NetworkPolicy structure looks correct."

# 3) Functional checks
# We'll create a tmp client in same namespace and one in another namespace to test access to pod-b (nginx on :80)
POD_B_IP="$(kubectl -n "$NS" get pod pod-b -o jsonpath='{.status.podIP}')"
[ -n "$POD_B_IP" ] || fail "Could not resolve pod-b IP."

# Same-namespace test client
kubectl -n "$NS" run np-same --image=busybox:1.36 --restart=Never --command -- sh -c "sleep 3600" >/dev/null 2>&1 || true
kubectl -n "$NS" wait --for=condition=Ready pod/np-same --timeout=60s >/dev/null 2>&1 || fail "np-same pod not Ready."

# Cross-namespace test client
OTHER_NS="netpol-otherns"
kubectl get ns "$OTHER_NS" >/dev/null 2>&1 || kubectl create namespace "$OTHER_NS" >/dev/null 2>&1
kubectl -n "$OTHER_NS" run np-other --image=busybox:1.36 --restart=Never --command -- sh -c "sleep 3600" >/dev/null 2>&1 || true
kubectl -n "$OTHER_NS" wait --for=condition=Ready pod/np-other --timeout=60s >/dev/null 2>&1 || fail "np-other pod not Ready."

# Helper to fetch via busybox wget (nginx returns 200 with body)
fetch() {
  local ns="$1" pod="$2" ip="$3"
  kubectl -n "$ns" exec "$pod" -- sh -c "wget -qO- -T 3 http://$ip:80/ || echo FAILED"
}

# 3a) Same-namespace should SUCCEED
BODY_SAME="$(fetch "$NS" np-same "$POD_B_IP")"
echo "$BODY_SAME" | grep -q "html" || fail "Expected same-namespace access to succeed, got: $BODY_SAME"
pass "Same-namespace ingress to pod-b allowed."

# 3b) Other-namespace should FAIL
BODY_OTHER="$(fetch "$OTHER_NS" np-other "$POD_B_IP")"
if echo "$BODY_OTHER" | grep -qi "FAILED"; then
  pass "Cross-namespace ingress to pod-b denied (timeout/fail)."
else
  # Some CNIs may immediately refuse with no body; treat any non-empty non-html as failure
  echo "$BODY_OTHER" | grep -q "html" && fail "Cross-namespace access unexpectedly succeeded."
  pass "Cross-namespace ingress appears denied."
fi

# Cleanup temporary test clients (keep target pods and policy)
kubectl -n "$NS" delete pod np-same --force --grace-period=0 >/dev/null 2>&1 || true
kubectl -n "$OTHER_NS" delete pod np-other --force --grace-period=0 >/dev/null 2>&1 || true
kubectl delete ns "$OTHER_NS" >/dev/null 2>&1 || true

echo "✅ Verification successful! NetworkPolicy '$NP' enforces internal-only ingress in '$NS'."
