#!/bin/bash
set -euo pipefail

NS="joker"
DEP="joker-deployment"
CONTAINER="joker-container"
YAML_PATH="/opt/course/20/joker-deployment-new.yaml"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."

echo "🔍 Verifying CKAD SecurityContext & Capabilities Exercise..."
echo ""

# 1) Check if joker-deployment-new.yaml exists
[[ -f "$YAML_PATH" ]] || fail "File '$YAML_PATH' not found. You must save your changes to this file."
pass "File '$YAML_PATH' exists"

# 2) Check if deployment exists
kubectl -n "$NS" get deployment "$DEP" >/dev/null 2>&1 || fail "Deployment '$DEP' not found in namespace '$NS'."
pass "Deployment '$DEP' exists in namespace '$NS'"

# 3) Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=90s deployment/"$DEP" -n "$NS" >/dev/null 2>&1 || fail "Deployment is not ready after timeout."
pass "Deployment is ready"

# 4) Check runAsUser is set to 3000
RUN_AS_USER=$(kubectl -n "$NS" get deployment "$DEP" -o jsonpath='{.spec.template.spec.containers[?(@.name=="'"$CONTAINER"'")].securityContext.runAsUser}')
[[ "$RUN_AS_USER" == "3000" ]] || fail "Container must run as user ID 3000 (found: '$RUN_AS_USER')."
pass "Container configured to run as user ID 3000"

# 5) Check allowPrivilegeEscalation is set to false
PRIV_ESC=$(kubectl -n "$NS" get deployment "$DEP" -o jsonpath='{.spec.template.spec.containers[?(@.name=="'"$CONTAINER"'")].securityContext.allowPrivilegeEscalation}')
[[ "$PRIV_ESC" == "false" ]] || fail "allowPrivilegeEscalation must be set to false (found: '$PRIV_ESC')."
pass "Privilege escalation is forbidden (allowPrivilegeEscalation: false)"

# 6) Check capabilities are added
CAPABILITIES=$(kubectl -n "$NS" get deployment "$DEP" -o jsonpath='{.spec.template.spec.containers[?(@.name=="'"$CONTAINER"'")].securityContext.capabilities.add}')

if [[ -z "$CAPABILITIES" ]]; then
    fail "No capabilities found. You must add NET_BIND_SERVICE, NET_RAW, and NET_ADMIN."
fi

# Check for each required capability
HAS_NET_BIND=false
HAS_NET_RAW=false
HAS_NET_ADMIN=false

while IFS= read -r cap; do
    case "$cap" in
        NET_BIND_SERVICE) HAS_NET_BIND=true ;;
        NET_RAW) HAS_NET_RAW=true ;;
        NET_ADMIN) HAS_NET_ADMIN=true ;;
    esac
done < <(echo "$CAPABILITIES" | jq -r '.[]' 2>/dev/null || echo "")

[[ "$HAS_NET_BIND" == "true" ]] || fail "Missing capability: NET_BIND_SERVICE"
[[ "$HAS_NET_RAW" == "true" ]] || fail "Missing capability: NET_RAW"
[[ "$HAS_NET_ADMIN" == "true" ]] || fail "Missing capability: NET_ADMIN"

pass "All required capabilities added: NET_BIND_SERVICE, NET_RAW, NET_ADMIN"

# 7) Get a running pod
echo "⏳ Getting pod information..."
POD_NAME=$(kubectl -n "$NS" get pods -l app=joker --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [[ -z "$POD_NAME" ]]; then
    fail "No running pods found for deployment '$DEP'."
fi

pass "Found running pod: $POD_NAME"

# 8) Verify pod is running
POD_STATUS=$(kubectl -n "$NS" get pod "$POD_NAME" -o jsonpath='{.status.phase}')
[[ "$POD_STATUS" == "Running" ]] || fail "Pod is not running (status: $POD_STATUS)."
pass "Pod is in Running state"

# 9) Verify container is ready
CONTAINER_READY=$(kubectl -n "$NS" get pod "$POD_NAME" -o jsonpath='{.status.containerStatuses[?(@.name=="'"$CONTAINER"'")].ready}')
[[ "$CONTAINER_READY" == "true" ]] || fail "Container is not ready."
pass "Container is ready"

# 10) Verify actual user ID in running container
echo "🔐 Verifying security context in running pod..."
ACTUAL_UID=$(kubectl -n "$NS" exec "$POD_NAME" -- id -u 2>/dev/null || echo "")

if [[ -z "$ACTUAL_UID" ]]; then
    fail "Could not verify user ID in running container."
fi

[[ "$ACTUAL_UID" == "3000" ]] || fail "Container is not running as user ID 3000 (actual UID: $ACTUAL_UID)."
pass "✨ Verified: Container is actually running as user ID 3000"

# 11) Verify securityContext in pod spec
POD_RUN_AS_USER=$(kubectl -n "$NS" get pod "$POD_NAME" -o jsonpath='{.spec.containers[?(@.name=="'"$CONTAINER"'")].securityContext.runAsUser}')
POD_PRIV_ESC=$(kubectl -n "$NS" get pod "$POD_NAME" -o jsonpath='{.spec.containers[?(@.name=="'"$CONTAINER"'")].securityContext.allowPrivilegeEscalation}')

[[ "$POD_RUN_AS_USER" == "3000" ]] || fail "Pod spec does not show runAsUser: 3000."
[[ "$POD_PRIV_ESC" == "false" ]] || fail "Pod spec does not show allowPrivilegeEscalation: false."
pass "Pod spec matches deployment configuration"

# 12) Verify capabilities in pod spec
POD_CAPS=$(kubectl -n "$NS" get pod "$POD_NAME" -o jsonpath='{.spec.containers[?(@.name=="'"$CONTAINER"'")].securityContext.capabilities.add}')
POD_CAP_COUNT=$(echo "$POD_CAPS" | jq -r '. | length' 2>/dev/null || echo "0")

[[ "$POD_CAP_COUNT" -ge 3 ]] || fail "Pod spec does not show all 3 capabilities."
pass "Pod spec shows all capabilities"

# 13) Check all replicas are ready
DESIRED_REPLICAS=$(kubectl -n "$NS" get deployment "$DEP" -o jsonpath='{.spec.replicas}')
READY_REPLICAS=$(kubectl -n "$NS" get deployment "$DEP" -o jsonpath='{.status.readyReplicas}')

[[ "$READY_REPLICAS" == "$DESIRED_REPLICAS" ]] || fail "Not all replicas are ready ($READY_REPLICAS/$DESIRED_REPLICAS)."
pass "All replicas are ready: $READY_REPLICAS/$DESIRED_REPLICAS"

# 14) Verify YAML file contains the changes
if grep -q "runAsUser: 3000" "$YAML_PATH" && \
   grep -q "allowPrivilegeEscalation: false" "$YAML_PATH" && \
   grep -q "NET_BIND_SERVICE" "$YAML_PATH" && \
   grep -q "NET_RAW" "$YAML_PATH" && \
   grep -q "NET_ADMIN" "$YAML_PATH"; then
    pass "YAML file contains all required security configurations"
else
    fail "YAML file is missing some security configurations."
fi

echo ""
pass "🎉 Verification successful! Security context configured correctly:"
echo ""
echo "   📋 Deployment: $DEP (namespace: $NS)"
echo "   👤 User ID: 3000 (non-root)"
echo "   🔒 Privilege Escalation: Forbidden"
echo "   🛡️  Capabilities Added:"
echo "      • NET_BIND_SERVICE (bind to privileged ports)"
echo "      • NET_RAW (use RAW sockets)"
echo "      • NET_ADMIN (network administration)"
echo "   ✅ Status: All $READY_REPLICAS/$DESIRED_REPLICAS pods running and ready"
echo ""
echo "🔐 Security Best Practices Applied:"
echo "   ✓ Running as non-root user (UID 3000)"
echo "   ✓ Privilege escalation prevented"
echo "   ✓ Least privilege with specific capabilities only"
echo ""
echo "💡 Verify the user ID in a pod:"
echo "   kubectl exec -n $NS $POD_NAME -- id"
