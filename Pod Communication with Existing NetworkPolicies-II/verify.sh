#!/bin/bash
set -euo pipefail

NS="ckad00018"

fail(){ echo "❌ $1"; exit 1; }
pass(){ echo "✅ $1"; exit 0; }

# Pods must exist
for pod in web db ckad00018-newpod; do
  kubectl -n $NS get pod $pod >/dev/null 2>&1 || fail "Pod $pod missing in $NS."
done

# Labels check
WEB_LABEL=$(kubectl -n $NS get pod web -o jsonpath='{.metadata.labels.app}' 2>/dev/null || true)
[[ "$WEB_LABEL" == "web" ]] || fail "Pod 'web' must be labeled app=web."

DB_LABEL=$(kubectl -n $NS get pod db -o jsonpath='{.metadata.labels.app}' 2>/dev/null || true)
[[ "$DB_LABEL" == "db" ]] || fail "Pod 'db' must be labeled app=db."

NEWPOD_LABEL=$(kubectl -n $NS get pod ckad00018-newpod -o jsonpath='{.metadata.labels.app}' 2>/dev/null || true)
[[ "$NEWPOD_LABEL" == "newpod" ]] || fail "Pod 'ckad00018-newpod' must be labeled app=newpod."

# NetworkPolicy check
kubectl -n $NS get netpol np-ckad00018 >/dev/null 2>&1 || fail "NetworkPolicy np-ckad00018 not found."

TYPES=$(kubectl -n $NS get netpol np-ckad00018 -o jsonpath='{.spec.policyTypes[*]}')
echo "$TYPES" | grep -q "Ingress" || fail "NetworkPolicy must include Ingress."
echo "$TYPES" | grep -q "Egress" || fail "NetworkPolicy must include Egress."

pass "Pods relabeled correctly and existing NetworkPolicy enforces restrictions."
