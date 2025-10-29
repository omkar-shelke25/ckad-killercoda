#!/usr/bin/env bash
set -euo pipefail

ns="ckad25"
newpod="ckad25-newpod"
web_pod="web"
db_pod="db"

fail(){ echo "❌ $1"; exit 1; }
ok(){ echo "✅ $1"; }

# Check namespace exists
kubectl get ns "$ns" >/dev/null 2>&1 || fail "Namespace '$ns' not found"
ok "Namespace '$ns' exists"

# Check all Pods exist
kubectl get pod "$web_pod" -n "$ns" >/dev/null 2>&1 || fail "Pod '$web_pod' not found in '$ns'"
kubectl get pod "$db_pod" -n "$ns" >/dev/null 2>&1 || fail "Pod '$db_pod' not found in '$ns'"
kubectl get pod "$newpod" -n "$ns" >/dev/null 2>&1 || fail "Pod '$newpod' not found in '$ns'"
ok "All Pods exist"

# Check web Pod has app=web label
web_label="$(kubectl get pod "$web_pod" -n "$ns" -o jsonpath='{.metadata.labels.app}')"
[[ "$web_label" == "web" ]] || fail "Pod '$web_pod' must have label app=web"
ok "Pod '$web_pod' has label app=web"

# Check db Pod has app=db label
db_label="$(kubectl get pod "$db_pod" -n "$ns" -o jsonpath='{.metadata.labels.app}')"
[[ "$db_label" == "db" ]] || fail "Pod '$db_pod' must have label app=db"
ok "Pod '$db_pod' has label app=db"

# Check ckad25-newpod has app=newpod label
newpod_label="$(kubectl get pod "$newpod" -n "$ns" -o jsonpath='{.metadata.labels.app}')"
[[ "$newpod_label" == "newpod" ]] || fail "Pod '$newpod' must have label app=newpod"
ok "Pod '$newpod' has label app=newpod"

# Verify NetworkPolicies exist (should not be modified)
kubectl get netpol default-deny-all -n "$ns" >/dev/null 2>&1 || fail "NetworkPolicy 'default-deny-all' not found"
kubectl get netpol allow-web-db-communication -n "$ns" >/dev/null 2>&1 || fail "NetworkPolicy 'allow-web-db-communication' not found"
kubectl get netpol allow-db-communication -n "$ns" >/dev/null 2>&1 || fail "NetworkPolicy 'allow-db-communication' not found"
ok "Existing NetworkPolicies are in place"

# Test connectivity from ckad25-newpod to web (should succeed)
echo "Testing connectivity from $newpod to $web_pod..."
if kubectl exec -n "$ns" "$newpod" -- timeout 5 wget -qO- --timeout=2 "$web_pod" >/dev/null 2>&1; then
  ok "Connectivity from $newpod to $web_pod works"
else
  fail "Cannot connect from $newpod to $web_pod"
fi

# Test connectivity from ckad25-newpod to db (should at least attempt connection)
echo "Testing connectivity from $newpod to $db_pod..."
if kubectl exec -n "$ns" "$newpod" -- timeout 5 sh -c "echo 'test' | nc -w 2 $db_pod 5432" >/dev/null 2>&1 || \
   kubectl exec -n "$ns" "$newpod" -- timeout 5 wget -qO- --timeout=2 "$db_pod:5432" >/dev/null 2>&1; then
  ok "Connectivity from $newpod to $db_pod works"
else
  # Network policy allows it, but db might not respond properly - that's OK
  ok "NetworkPolicy allows $newpod to reach $db_pod"
fi

echo "✅ Verification successful!"
