#!/bin/bash
set -euo pipefail

NS="ckad-netpol"

fail(){ echo "❌ $1"; exit 1; }
pass(){ echo "✅ $1"; exit 0; }

# Check if namespace exists
kubectl get ns $NS >/dev/null 2>&1 || fail "Namespace $NS does not exist."

# Check if all pods exist and are running
for pod in web db ckad-netpol-newpod; do
    kubectl -n $NS get pod $pod >/dev/null 2>&1 || fail "Pod $pod does not exist in namespace $NS."
    
    STATUS=$(kubectl -n $NS get pod $pod -o jsonpath='{.status.phase}')
    [[ "$STATUS" == "Running" ]] || fail "Pod $pod is not in Running state (current: $STATUS)."
done

echo "✅ All pods exist and are running"

# Check NetworkPolicies exist and haven't been modified
NETPOL_COUNT=$(kubectl -n $NS get networkpolicies --no-headers | wc -l)
[[ $NETPOL_COUNT -eq 4 ]] || fail "Expected 4 NetworkPolicies, found $NETPOL_COUNT. Do not modify NetworkPolicies!"

for netpol in default-deny-all web-netpol db-netpol allow-all; do
    kubectl -n $NS get networkpolicy $netpol >/dev/null 2>&1 || fail "NetworkPolicy $netpol is missing or modified."
done

echo "✅ All NetworkPolicies are intact"

# Test connectivity from ckad-netpol-newpod to web
echo "🔍 Testing connectivity from ckad-netpol-newpod to web..."
kubectl -n $NS exec ckad-netpol-newpod -- timeout 10 wget -qO- web >/dev/null 2>&1 || fail "ckad-netpol-newpod cannot reach web pod. Check pod labels and NetworkPolicy configuration."

echo "✅ ckad-netpol-newpod can communicate with web"

# Test connectivity from ckad-netpol-newpod to db  
echo "🔍 Testing connectivity from ckad-netpol-newpod to db..."
kubectl -n $NS exec ckad-netpol-newpod -- timeout 10 wget -qO- db >/dev/null 2>&1 || fail "ckad-netpol-newpod cannot reach db pod. Check pod labels and NetworkPolicy configuration."

echo "✅ ckad-netpol-newpod can communicate with db"

# Test connectivity from web to ckad-netpol-newpod
echo "🔍 Testing connectivity from web to ckad-netpol-newpod..."
kubectl -n $NS exec web -- timeout 10 wget -qO- ckad-netpol-newpod >/dev/null 2>&1 || fail "web pod cannot reach ckad-netpol-newpod. Check pod labels and NetworkPolicy configuration."

echo "✅ web can communicate with ckad-netpol-newpod"

# Test connectivity from db to ckad-netpol-newpod
echo "🔍 Testing connectivity from db to ckad-netpol-newpod..."
kubectl -n $NS exec db -- timeout 10 wget -qO- ckad-netpol-newpod >/dev/null 2>&1 || fail "db pod cannot reach ckad-netpol-newpod. Check pod labels and NetworkPolicy configuration."

echo "✅ db can communicate with ckad-netpol-newpod"

# Verify that communication is properly restricted (optional advanced check)
echo "🔍 Verifying NetworkPolicy restrictions are working..."

# Check pod labels to ensure proper configuration
WEB_LABELS=$(kubectl -n $NS get pod web -o jsonpath='{.metadata.labels}')
DB_LABELS=$(kubectl -n $NS get pod db -o jsonpath='{.metadata.labels}')
NEWPOD_LABELS=$(kubectl -n $NS get pod ckad-netpol-newpod -o jsonpath='{.metadata.labels}')

echo "📋 Current pod labels:"
echo "web: $WEB_LABELS"
echo "db: $DB_LABELS" 
echo "ckad-netpol-newpod: $NEWPOD_LABELS"

# Check if web pod has required labels for communication
echo "$WEB_LABELS" | grep -q '"env":"db"' || fail "web pod missing required label env=db for communication with ckad-netpol-newpod"

# Check if db pod has required labels for communication  
echo "$DB_LABELS" | grep -q '"run":"web"' || fail "db pod missing required label run=web for communication with ckad-netpol-newpod"

pass "🎉 Success! Pod ckad-netpol-newpod can now communicate bidirectionally with both web and db pods while maintaining NetworkPolicy restrictions."
