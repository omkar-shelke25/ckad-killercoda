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

# 6) Ingress 'from' includes app1 AND app2
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

# ============================================================================
# 8) Live connectivity test
#
# Speed notes vs. the original:
#   - Timeout dropped from 5s -> 2s. 2s is plenty for an in-cluster TCP
#     check; the blocked case (test-pod) used to eat the full 5s timeout
#     every single run just to confirm it's blocked.
#   - The two `kubectl exec` checks now run in PARALLEL (background jobs +
#     `wait`) instead of sequentially, so you pay the cost once instead
#     of twice.
#
# We still use `nc -zv` (not /dev/tcp) since the busybox image's `sh`
# (ash) doesn't support /dev/tcp redirection — nc is the reliable option
# here.
# ============================================================================

echo ""
echo "── Live connectivity test (using nc -zv, parallel, 2s timeout) ─────────"

APP1_POD="$(kubectl -n "$NS" get pods -l app=app1 -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
TEST_POD="$(kubectl -n "$NS" get pods -l app=test-pod -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"

APP1_RESULT_FILE="$(mktemp)"
TEST_RESULT_FILE="$(mktemp)"
trap 'rm -f "$APP1_RESULT_FILE" "$TEST_RESULT_FILE"' EXIT

if [ -n "$APP1_POD" ]; then
  (
    if kubectl -n "$NS" exec "$APP1_POD" -- nc -zv -w 2 redis 6379 >/dev/null 2>&1; then
      echo "ok" > "$APP1_RESULT_FILE"
    else
      echo "fail" > "$APP1_RESULT_FILE"
    fi
  ) &
  APP1_PID=$!
fi

if [ -n "$TEST_POD" ]; then
  (
    if kubectl -n "$NS" exec "$TEST_POD" -- nc -zv -w 2 redis 6379 >/dev/null 2>&1; then
      echo "ok" > "$TEST_RESULT_FILE"
    else
      echo "fail" > "$TEST_RESULT_FILE"
    fi
  ) &
  TEST_PID=$!
fi

[ -n "${APP1_PID:-}" ] && wait "$APP1_PID"
[ -n "${TEST_PID:-}" ] && wait "$TEST_PID"

if [ -n "$APP1_POD" ]; then
  if [ "$(cat "$APP1_RESULT_FILE" 2>/dev/null)" = "ok" ]; then
    pass "Live test: app1 CAN reach redis:6379 (expected — allowed by policy)"
  else
    fail "Live test: app1 cannot reach redis:6379. Check your ingress rule allows app=app1 on TCP/6379."
  fi
else
  echo "⚠️  Skipping live test — no app1 pod found."
fi

if [ -n "$TEST_POD" ]; then
  if [ "$(cat "$TEST_RESULT_FILE" 2>/dev/null)" = "ok" ]; then
    fail "Live test: test-pod CAN reach redis:6379 — this should be BLOCKED by the policy."
  else
    pass "Live test: test-pod is correctly BLOCKED from redis:6379 (expected — denied by policy)"
  fi
else
  echo "⚠️  Skipping live test — no test-pod found."
fi

echo ""
echo "========================================="
pass "All checks passed! NetworkPolicy is correctly configured."
echo "========================================="
