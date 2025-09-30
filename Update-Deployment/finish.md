#!/bin/bash
set -euo pipefail

NS="prod"
DEP="gamma-app"
EXPECT_IMAGE="nginx:stable"
EXPECT_CONTAINER_NAME="gamma-nginx"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# 1) Deployment exists
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || fail "Deployment '$DEP' not found in namespace '$NS'."

# 2) Check if Deployment UID has changed (it should NOT have changed)
ORIGINAL_UID=""
if [[ -f /tmp/original_deployment_uid.txt ]]; then
  ORIGINAL_UID=$(cat /tmp/original_deployment_uid.txt)
fi

CURRENT_UID=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.metadata.uid}')

if [[ -n "$ORIGINAL_UID" && "$ORIGINAL_UID" != "$CURRENT_UID" ]]; then
  fail "Deployment was recreated! Original UID: $ORIGINAL_UID, Current UID: $CURRENT_UID. The Deployment should be updated in-place."
fi

pass "Deployment was not recreated (UID: $CURRENT_UID)."

# 3) Check container name
CONTAINER_NAME=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].name}')
[[ "$CONTAINER_NAME" == "$EXPECT_CONTAINER_NAME" ]] || fail "Expected container name '$EXPECT_CONTAINER_NAME' but found '$CONTAINER_NAME'."
pass "Container name is correct: $CONTAINER_NAME"

# 4) Check image
IMAGE=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].image}')
[[ "$IMAGE" == "$EXPECT_IMAGE" ]] || fail "Expected image '$EXPECT_IMAGE' but found '$IMAGE'."
pass "Container image is correct: $IMAGE"

# 5) Check if rollout is complete and pods are ready
kubectl -n "$NS" rollout status "deploy/$DEP" --timeout=120s >/dev/null 2>&1 \
  || fail "Deployment '$DEP' did not complete rollout successfully."

DESIRED_REPLICAS=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.replicas}')
READY_REPLICAS=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.status.readyReplicas}')
READY_REPLICAS="${READY_REPLICAS:-0}"

[[ "$READY_REPLICAS" == "$DESIRED_REPLICAS" ]] || fail "Expected $DESIRED_REPLICAS ready replicas but found '$READY_REPLICAS'."
pass "All $READY_REPLICAS replicas are ready."

# 6) Verify pods are running with new container name and image
POD_CONTAINER_NAME=$(kubectl -n "$NS" get pods -l app="$DEP" -o jsonpath='{.items[0].spec.containers[0].name}' 2>/dev/null || echo "")
POD_IMAGE=$(kubectl -n "$NS" get pods -l app="$DEP" -o jsonpath='{.items[0].spec.containers[0].image}' 2>/dev/null || echo "")

[[ "$POD_CONTAINER_NAME" == "$EXPECT_CONTAINER_NAME" ]] || fail "Pod container name is '$POD_CONTAINER_NAME', expected '$EXPECT_CONTAINER_NAME'."
[[ "$POD_IMAGE" == "$EXPECT_IMAGE" ]] || fail "Pod image is '$POD_IMAGE', expected '$EXPECT_IMAGE'."

pass "Pods are running with correct configuration."

echo ""
echo "🎉 Verification successful!"
echo "   - Deployment '$DEP' was updated in-place (not recreated)"
echo "   - Container name: $CONTAINER_NAME"
echo "   - Container image: $IMAGE"
echo "   - Ready replicas: $READY_REPLICAS"
