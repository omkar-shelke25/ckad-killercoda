#!/bin/bash
set -uo pipefail

NS="jupiter"
NP="np-redis"

pass() { echo "✅ $1"; }
fail() { echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq not found in PATH."

echo "========================================="
echo "Verifying NetworkPolicy '$NP' in '$NS'..."
echo "========================================="

# 1) Namespace exists
kubectl get namespace "$NS" >/dev/null 2>&1 \
  || fail "Namespace '$NS' not found."
pass "Namespace '$NS' exists"

# 2) NetworkPolicy exists
kubectl -n "$NS" get networkpolicy "$NP" >/dev/null 2>&1 \
  || fail "NetworkPolicy '$NP' not found in '$NS'."
pass "NetworkPolicy '$NP' exists"

JSON="$(kubectl -n "$NS" get networkpolicy "$NP" -o json)"

# 3) podSelector targets app=redis
#    Accept EITHER matchLabels OR matchExpressions form.
SEL_OK="$(echo "$JSON" | jq -r '
  (.spec.podSelector.matchLabels.app == "redis")
  or
  (
    [.spec.podSelector.matchExpressions[]? |
      select(.key == "app" and .operator == "In" and (.values | index("redis")))
    ] | length > 0
  )
')"
[ "$SEL_OK" = "true" ] \
  || fail "podSelector must target app=redis (via matchLabels or matchExpressions)."
pass "podSelector targets app=redis"

# 4) policyTypes includes Ingress and Egress
TYPES="$(echo "$JSON" | jq -r '[.spec.policyTypes[]?] | unique | join(",")')"
echo "$TYPES" | grep -q "Ingress" || fail "policyTypes must include 'Ingress' (found: $TYPES)."
echo "$TYPES" | grep -q "Egress"  || fail "policyTypes must include 'Egress' (found: $TYPES)."
pass "policyTypes includes Ingress and Egress"

# 5) Ingress allows TCP port 6379
INGRESS_6379="$(echo "$JSON" | jq '
  [.spec.ingress[]?.ports[]? |
    select((.protocol // "TCP") == "TCP" and (.port == 6379 or .port == "6379"))
  ] | length
')"
[ "${INGRESS_6379:-0}" -ge 1 ] \
  || fail "No ingress rule allows TCP port 6379."
pass "Ingress allows TCP port 6379"

# 6) Ingress 'from' includes app1 AND app2 — checks BOTH matchLabels and matchExpressions
#    A podSelector matches app1 if EITHER:
#      matchLabels.app == "app1"
#      OR matchExpressions has {key: app, operator: In, values: [..., "app1", ...]}
FROM_HAS_APP1="$(echo "$JSON" | jq -r '
  [.spec.ingress[]?.from[]?.podSelector |
    select(
      (.matchLabels.app == "app1")
      or
      ([.matchExpressions[]? | select(.key == "app" and .operator == "In" and (.values | index("app1")))] | length > 0)
    )
  ] | length > 0
')"

FROM_HAS_APP2="$(echo "$JSON" | jq -r '
  [.spec.ingress[]?.from[]?.podSelector |
    select(
      (.matchLabels.app == "app2")
      or
      ([.matchExpressions[]? | select(.key == "app" and .operator == "In" and (.values | index("app2")))] | length > 0)
    )
  ] | length > 0
')"

[ "$FROM_HAS_APP1" = "true" ] \
  || fail "Ingress 'from' does not allow pods with label app=app1 (checked matchLabels and matchExpressions)."
[ "$FROM_HAS_APP2" = "true" ] \
  || fail "Ingress 'from' does not allow pods with label app=app2 (checked matchLabels and matchExpressions)."
pass "Ingress 'from' allows app1 and app2 (matchLabels or matchExpressions accepted)"

# 7) Egress allows DNS (UDP/53 and TCP/53)
EGRESS_UDP53="$(echo "$JSON" | jq '
  [.spec.egress[]?.ports[]? |
    select((.protocol // "UDP") == "UDP" and (.port == 53 or .port == "53"))
  ] | length
')"
EGRESS_TCP53="$(echo "$JSON" | jq '
  [.spec.egress[]?.ports[]? |
    select((.protocol // "TCP") == "TCP" and (.port == 53 or .port == "53"))
  ] | length
')"
[ "${EGRESS_UDP53:-0}" -ge 1 ] || fail "Egress does not allow UDP port 53 (DNS)."
[ "${EGRESS_TCP53:-0}" -ge 1 ] || fail "Egress does not allow TCP port 53 (DNS)."
pass "Egress allows DNS (UDP/53 and TCP/53)"

# 8) Live connectivity test (best-effort — uses wget which is present in busybox)
echo ""
echo "── Live connectivity test ────────────────────────"

APP1_POD="$(kubectl -n "$NS" get pods -l app=app1 -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
TEST_POD="$(kubectl -n "$NS" get pods -l app=test-pod -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"

if [ -n "$APP1_POD" ]; then
  if kubectl -n "$NS" exec "$APP1_POD" -- timeout 5 sh -c 'echo > /dev/tcp/redis/6379' 2>/dev/null; then
    pass "Live test: app1 CAN reach redis:6379 (expected)"
  else
    fail "Live test: app1 cannot reach redis:6379. Check your ingress rule allows app=app1."
  fi
else
  echo "⚠️  Skipping live test — no app1 pod found."
fi

if [ -n "$TEST_POD" ]; then
  if kubectl -n "$NS" exec "$TEST_POD" -- timeout 5 sh -c 'echo > /dev/tcp/redis/6379' 2>/dev/null; then
    fail "Live test: test-pod CAN reach redis:6379 — this should be BLOCKED."
  else
    pass "Live test: test-pod is correctly BLOCKED from redis:6379"
  fi
else
  echo "⚠️  Skipping live test — no test-pod found."
fi

echo ""
echo "========================================="
pass "All checks passed! NetworkPolicy is correctly configured."
echo "========================================="
