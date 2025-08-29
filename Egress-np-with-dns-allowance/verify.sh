#!/bin/bash
set -euo pipefail

NS="venus"
NP="np1"

pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }

# 0) Pre-requisite sanity checks
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."
kubectl -n "$NS" get deploy api >/dev/null 2>&1 || fail "Deployment 'api' missing in '$NS'."
kubectl -n "$NS" get deploy frontend >/dev/null 2>&1 || fail "Deployment 'frontend' missing in '$NS'."
kubectl -n "$NS" get svc api >/dev/null 2>&1 || fail "Service 'api' missing in '$NS'."
kubectl -n "$NS" get svc frontend >/dev/null 2>&1 || fail "Service 'frontend' missing in '$NS'."

# 1) NetworkPolicy exists
kubectl -n "$NS" get networkpolicy "$NP" >/dev/null 2>&1 || fail "NetworkPolicy '$NP' not found in '$NS'."

# 2) Basic structure checks
#    - Targets pods with label app=frontend
SEL_APP="$(kubectl -n "$NS" get networkpolicy "$NP" -o jsonpath='{.spec.podSelector.matchLabels.app}')"
[[ "$SEL_APP" == "frontend" ]] || fail "np1 must select pods with label app=frontend."

#    - policyTypes includes Egress
POLICY_TYPES="$(kubectl -n "$NS" get networkpolicy "$NP" -o jsonpath='{.spec.policyTypes[*]}')"
echo "$POLICY_TYPES" | grep -qi "Egress" || fail "np1 must set policyTypes: [Egress]."

#    - Must include an egress rule to pods labeled app=api on TCP/2222
TO_API_PORT="$(kubectl -n "$NS" get networkpolicy "$NP" -o jsonpath='{range .spec.egress[*].to[*].podSelector.matchLabels}{.app}{" "}{end}' | tr -s ' ')"
E_HAS_TCP_2222="$(kubectl -n "$NS" get networkpolicy "$NP" -o jsonpath='{range .spec.egress[*].ports[*]}{.protocol}/{.port}{" "}{end}' | tr -s ' ')"

echo "Debug: TO_API_PORT='$TO_API_PORT'" >&2
( echo "$TO_API_PORT" | grep -q "api" ) || fail "np1 must allow egress to pods labeled app=api."
( echo "$E_HAS_TCP_2222" | grep -q "TCP/2222" ) || fail "np1 must allow TCP port 2222 to api."

#    - Must allow DNS on TCP/53 and UDP/53
DNS_PORTS="$(kubectl -n "$NS" get networkpolicy "$NP" -o jsonpath='{range .spec.egress[*].ports[*]}{.protocol}/{.port}{" "}{end}' | tr -s ' ')"
echo "$DNS_PORTS" | grep -q "UDP/53" || fail "np1 must allow UDP/53 for DNS."
echo "$DNS_PORTS" | grep -q "TCP/53" || fail "np1 must allow TCP/53 for DNS."

# 3) Functional checks from a frontend pod
FPOD="$(kubectl -n "$NS" get pod -l app=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"
[[ -n "$FPOD" ]] || fail "No pods found for Deployment 'frontend' in '$NS'."

#    - DNS resolution should work
kubectl -n "$NS" exec "$FPOD" -- nslookup kubernetes.default.svc.cluster.local >/dev/null 2>&1 \
  || fail "DNS lookup failed from frontend pod; ensure UDP/TCP 53 allowed."

#    - Access to api:2222 should work
kubectl -n "$NS" exec "$FPOD" -- wget -qO- --timeout=5 http://api:2222 >/dev/null 2>&1 \
  || fail "wget to api:2222 failed from frontend pod; ensure TCP/2222 to app=api allowed."

#    - Access to www.google.com should fail (blocked by NetworkPolicy)
kubectl -n "$NS" exec "$FPOD" -- wget -qO- --timeout=5 http://www.google.com >/dev/null 2>&1 \
  && fail "wget to www.google.com succeeded from frontend pod; it should be blocked by np1."

pass "np1 present and effective: frontend egress allowed only to api:2222 and DNS on 53, blocked to www.google.com."
