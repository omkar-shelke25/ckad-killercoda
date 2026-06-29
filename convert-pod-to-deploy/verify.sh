#!/bin/bash
set -euo pipefail

NS="pluto"
DEP="holy-api"
DEP_FILE="/opt/course/9/holy-api-deployment.yaml"
EXPECTED_IMAGE="busybox:latest"

pass() { echo "✅ $1"; }
fail() { echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1       || fail "jq not found in PATH."
command -v python3 >/dev/null 2>&1  || fail "python3 not found in PATH."

echo "========================================="
echo "Verifying Deployment in namespace '$NS'..."
echo "========================================="

# 1) Deployment exists
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 \
  || fail "Deployment '$DEP' not found in namespace '$NS'. Did you apply the YAML?"
pass "Deployment '$DEP' exists"

# 2) Replicas = 3
REPLICAS=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.replicas}')
[[ "$REPLICAS" == "3" ]] \
  || fail "Deployment must have replicas=3 (found: $REPLICAS)."
pass "Replicas = 3"

# 3) Image check
IMG=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].image}')
[[ "$IMG" == "$EXPECTED_IMAGE" ]] \
  || fail "Expected image '$EXPECTED_IMAGE' (found: '$IMG')."
pass "Image = $EXPECTED_IMAGE"

# 4) ALL containers must have allowPrivilegeEscalation=false AND privileged=false
JSON=$(kubectl -n "$NS" get deploy "$DEP" -o json)

TOTAL_CONTAINERS=$(echo "$JSON" | jq '[.spec.template.spec.containers[]] | length')
SECURE_CONTAINERS=$(echo "$JSON" | jq '[
  .spec.template.spec.containers[]
  | select(
      .securityContext.allowPrivilegeEscalation == false
      and .securityContext.privileged == false
    )
] | length')

if [[ "$SECURE_CONTAINERS" -lt "$TOTAL_CONTAINERS" ]]; then
  echo "Container securityContext found:" >&2
  echo "$JSON" | jq '.spec.template.spec.containers[] | {name, securityContext}' >&2
  fail "All containers must have allowPrivilegeEscalation=false and privileged=false. ($SECURE_CONTAINERS/$TOTAL_CONTAINERS containers are correctly set.)"
fi
pass "All containers have allowPrivilegeEscalation=false and privileged=false"

# 5) Deployment rollout complete and 3 ready replicas
#    (checked BEFORE pod deletion so timing issues don't cause false failures)
kubectl -n "$NS" rollout status deploy/"$DEP" --timeout=120s >/dev/null 2>&1 \
  || fail "Deployment rollout not complete. Check pod status: kubectl get pods -n $NS"
READY=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.status.readyReplicas}')
[[ "${READY:-0}" == "3" ]] \
  || fail "Expected 3 ready replicas (found: ${READY:-0}). Pods may still be starting."
pass "Deployment is rolled out with 3/3 ready replicas"

# 6) Original standalone Pod must be deleted
if kubectl -n "$NS" get pod "$DEP" >/dev/null 2>&1; then
  fail "The original Pod '$DEP' still exists. Delete it: kubectl delete pod $DEP -n $NS"
fi
pass "Original Pod '$DEP' has been deleted"

# 7) YAML file saved at the correct path
[[ -f "$DEP_FILE" ]] \
  || fail "YAML file not found at '$DEP_FILE'. Save your Deployment manifest there."

# Parse kind and name using python3 (always available; avoids yq/kubectl dry-run issues)
KIND=$(python3 -c "
import sys
for line in open('$DEP_FILE'):
    line = line.strip()
    if line.startswith('kind:'):
        print(line.split(':',1)[1].strip())
        sys.exit()
")
NAME=$(python3 -c "
import sys
found_metadata = False
for line in open('$DEP_FILE'):
    stripped = line.strip()
    if stripped == 'metadata:':
        found_metadata = True
        continue
    if found_metadata and stripped.startswith('name:'):
        print(stripped.split(':',1)[1].strip())
        sys.exit()
")

[[ "$KIND" == "Deployment" ]] \
  || fail "Saved YAML kind must be 'Deployment' (found: '$KIND')."
[[ "$NAME" == "$DEP" ]] \
  || fail "Saved YAML metadata.name must be '$DEP' (found: '$NAME')."
pass "YAML file saved correctly at $DEP_FILE"

echo ""
echo "========================================="
pass "All checks passed! Great work. 🚀"
echo "========================================="