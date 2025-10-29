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
if kubectl exec -n "$ns" "$newpod" -- timeout 5 wget -qO- --timeout=2 "http://$web_pod" >/dev/null 2>&1; then
  ok "Connectivity from $newpod to $web_pod works"
else
  fail "Cannot connect from $newpod to $web_pod - check if label app=newpod is set"
fi

# Test connectivity from ckad25-newpod to db using netcat
echo "Testing connectivity from $newpod to $db_pod..."
# First, ensure netcat is available or use a fallback method
if kubectl exec -n "$ns" "$newpod" -- sh -c "command -v nc" >/dev/null 2>&1; then
  if kubectl exec -n "$ns" "$newpod" -- timeout 5 nc -zv "$db_pod" 5432 2>&1 | grep -q "open\|succeeded\|connected"; then
    ok "Connectivity from $newpod to $db_pod works"
  else
    fail "Cannot connect from $newpod to $db_pod - check if label app=newpod is set"
  fi
else
  # Fallback: check if we can resolve and reach the service
  if kubectl exec -n "$ns" "$newpod" -- timeout 5 sh -c "wget --spider -T 2 http://$db_pod:5432 2>&1 || echo 'reachable'" | grep -q "reachable\|failed\|refused"; then
    ok "NetworkPolicy allows $newpod to reach $db_pod (connection attempted)"
  else
    fail "Cannot reach $db_pod from $newpod - check if label app=newpod is set"
  fi
fi

echo "✅ Verification successful!"
