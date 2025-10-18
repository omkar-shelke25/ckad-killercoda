#!/bin/bash
set -euo pipefail

NS="pluto"
DEP="holy-api"
DEP_FILE="/opt/course/9/holy-api-deployment.yaml"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."

# 1) Deployment exists
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || fail "Deployment '$DEP' not found in namespace '$NS'."

# 2) Replicas = 3
REPLICAS=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.replicas}')
[[ "$REPLICAS" == "3" ]] || fail "Deployment '$DEP' must have replicas=3 (found $REPLICAS)."

# 3) Container image (first container)
IMG=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].image}')
[[ "$IMG" == "public.ecr.aws/docker/library/busybox:stable" ]] || fail "Expected image public.ecr.aws/docker/library/busybox:stable (found $IMG)."

# 4) At least one container has the required securityContext
JSON=$(kubectl -n "$NS" get deploy "$DEP" -o json)
HAS_SC=$(echo "$JSON" | jq '[.spec.template.spec.containers[]?
  | select(.securityContext.allowPrivilegeEscalation==false and .securityContext.privileged==false)
] | length')
if [[ "${HAS_SC}" -lt 1 ]]; then
  # Helpful debug print
  echo "Containers and their securityContext:" >&2
  echo "$JSON" | jq '.spec.template.spec.containers[] | {name, securityContext}' >&2
  fail "No container has securityContext.allowPrivilegeEscalation=false AND privileged=false."
fi

# 5) Original Pod removed
if kubectl -n "$NS" get pod holy-api >/dev/null 2>&1; then
  fail "The original Pod 'holy-api' still exists. Delete it after creating the Deployment."
fi

# 6) Deployment rollout and 3 ready replicas
kubectl -n "$NS" rollout status deploy/"$DEP" --timeout=120s >/dev/null 2>&1 || fail "Deployment not successfully rolled out."
READY=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.status.readyReplicas}')
[[ "$READY" == "3" ]] || fail "Deployment should have 3 ready replicas (found ${READY:-0})."

# 7) YAML file saved at path
[[ -f "$DEP_FILE" ]] || fail "YAML file not found at $DEP_FILE."
# Try yq first; if missing, fall back to kubectl server-side parse
if command -v yq >/dev/null 2>&1; then
  KIND=$(yq '.kind' "$DEP_FILE" 2>/dev/null || echo "")
  NAME=$(yq '.metadata.name' "$DEP_FILE" 2>/dev/null || echo "")
else
  KIND=$(kubectl create --dry-run=client -f "$DEP_FILE" -o json 2>/dev/null | jq -r '.kind' || true)
  NAME=$(kubectl create --dry-run=client -f "$DEP_FILE" -o json 2>/dev/null | jq -r '.metadata.name' || true)
fi
[[ "$KIND" == "Deployment" && "$NAME" == "$DEP" ]] || fail "Saved YAML must be a Deployment named '$DEP'."

pass "Verification successful! Deployment '$DEP' meets all requirements."
