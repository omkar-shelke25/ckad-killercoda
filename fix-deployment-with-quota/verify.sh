#!/bin/bash
set -euo pipefail

NS="payments-prod"
DEPLOY="checkout-api"

fail(){ echo "❌ $1"; exit 1; }
pass(){ echo "✅ $1"; exit 0; }

# Check namespace exists
kubectl get ns $NS >/dev/null 2>&1 || fail "Namespace $NS does not exist."

# Check ResourceQuota exists
kubectl -n $NS get quota rq-payments-prod >/dev/null 2>&1 || fail "ResourceQuota rq-payments-prod not found in $NS."

# Check deployment exists
kubectl -n $NS get deploy $DEPLOY >/dev/null 2>&1 || fail "Deployment $DEPLOY not found in $NS."

# Ensure deployment's pod template defines resources.requests.cpu and resources.requests.memory
REQ_CPU=$(kubectl -n $NS get deploy $DEPLOY -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null || true)
REQ_MEM=$(kubectl -n $NS get deploy $DEPLOY -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}' 2>/dev/null || true)
LIM_CPU=$(kubectl -n $NS get deploy $DEPLOY -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' 2>/dev/null || true)
LIM_MEM=$(kubectl -n $NS get deploy $DEPLOY -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null || true)

[[ -n "$REQ_CPU" ]] || fail "Deployment pod template missing resources.requests.cpu."
[[ -n "$REQ_MEM" ]] || fail "Deployment pod template missing resources.requests.memory."
[[ -n "$LIM_CPU" ]] || fail "Deployment pod template missing resources.limits.cpu."
[[ -n "$LIM_MEM" ]] || fail "Deployment pod template missing resources.limits.memory."

# Check that at least one pod is running
POD_PHASE=$(kubectl -n $NS get pods -l app=checkout-api -o jsonpath='{.items[0].status.phase}' 2>/dev/null || true)
[[ "$POD_PHASE" == "Running" ]] || fail "No checkout-api pods are in Running state yet. Pods may still be creating or failing."

# Optional: verify that the number of replicas desired has at least created 1 running pod
RUNNING_COUNT=$(kubectl -n $NS get pods -l app=checkout-api --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l || true)
[[ "$RUNNING_COUNT" -ge 1 ]] || fail "Expected at least 1 running pod; found $RUNNING_COUNT."

pass "Deployment updated with resources and pods are running under ResourceQuota."
