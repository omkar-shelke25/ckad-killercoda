#!/bin/bash

# Verification script for CKAD Network Policy Restriction scenario
# Checks if app-pod has the correct label and connectivity works

set -e

NAMESPACE="ckad-netpol"
POD_NAME="app-pod"
REQUIRED_LABEL="role=allowed-app"

# Function to check pod label
check_label() {
    echo "🔍 Checking if $POD_NAME has label $REQUIRED_LABEL..."
    LABELS=$(kubectl -n "$NAMESPACE" get pod "$POD_NAME" --show-labels | grep "$REQUIRED_LABEL" || true)
    if [[ -z "$LABELS" ]]; then
        echo "❌ Error: $POD_NAME is missing the label $REQUIRED_LABEL."
        return 1
    else
        echo "✅ $POD_NAME has the correct label: $REQUIRED_LABEL"
        return 0
    fi
}

# Function to check pod status
check_pod_status() {
    echo "🔍 Checking if $POD_NAME is running..."
    STATUS=$(kubectl -n "$NAMESPACE" get pod "$POD_NAME" -o jsonpath='{.status.phase}')
    if [[ "$STATUS" != "Running" ]]; then
        echo "❌ Error: $POD_NAME is not running. Current status: $STATUS"
        return 1
    else
        echo "✅ $POD_NAME is running"
        return 0
    fi
}

# Function to check connectivity
check_connectivity() {
    echo "🔌 Testing ingress to $POD_NAME from frontend-pod..."
    INGRESS_TEST=$(kubectl exec -n "$NAMESPACE" frontend-pod -- curl -s -o /dev/null -w "%{http_code}" http://app-pod.ckad-netpol.svc.cluster.local || echo "failed")
    if [[ "$INGRESS_TEST" != "200" ]]; then
        echo "❌ Error: Ingress test failed. Cannot connect to $POD_NAME from frontend-pod."
        return 1
    else
        echo "✅ Ingress test passed: frontend-pod can connect to $POD_NAME"
    fi

    echo "🔌 Testing egress from $POD_NAME to backend-pod..."
    EGRESS_TEST=$(kubectl exec -n "$NAMESPACE" app-pod -- curl -s -o /dev/null -w "%{http_code}" http://backend-pod.ckad-netpol.svc.cluster.local:6379 || echo "failed")
    if [[ "$EGRESS_TEST" != "200" ]]; then
        echo "❌ Error: Egress test failed. $POD_NAME cannot connect to backend-pod."
        return 1
    else
        echo "✅ Egress test passed: $POD_NAME can connect to backend-pod"
    fi
    return 0
}

# Main verification
echo "🧪 Starting verification for CKAD Network Policy scenario..."
ERROR_COUNT=0

check_label || ERROR_COUNT=$((ERROR_COUNT + 1))
check_pod_status || ERROR_COUNT=$((ERROR_COUNT + 1))
check_connectivity || ERROR_COUNT=$((ERROR_COUNT + 1))

if [[ $ERROR_COUNT -eq 0 ]]; then
    echo "🎉 Verification successful! You have correctly configured $POD_NAME."
    exit 0
else
    echo "❌ Verification failed with $ERROR_COUNT errors."
    echo "Please review the errors above, fix the issues, and run '/bin/verify.sh' again."
    echo "Alternatively, check the solution in step1.md under 'Solution'."
    exit 1
fi
