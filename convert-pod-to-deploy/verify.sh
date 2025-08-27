#!/bin/bash
set -euo pipefail

NS="pluto"
DEP="holy-api"
RAW_DEP_FILE="/opt/course/9/holy-api-deployment.yaml"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."

# 0) Deployment exists
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || fail "Deployment '$DEP' not found in namespace '$NS'."

# 1) Deployment spec: replicas=3
REPLICAS=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.replicas}')
[[ "$REPLICAS" == "3" ]] || fail "Deployment '$DEP' must have replicas=3 (found $REPLICAS)."

# 2) Container securityContext: allowPrivilegeEscalation=false, privileged=false
JSON=$(kubectl -n "$NS" get deploy "$DEP" -o json)
APE=$(echo "$JSON" | jq -r '.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation // empty')
PRIV=$(echo "$JSON" | jq -r '.spec.template.spec.containers[0].securityContext.privileged // empty')
[[ "$APE" == "false" ]] || fail "Container securityContext.allowPrivilegeEscalation must be false (found '${APE:-<none>}')."
[[ "$PRIV" == "false" ]] || fail "Container securityContext.privileged must be false (found '${PRIV:-<none>}')."

# 3) Single Pod 'holy-api' should be deleted (original standalone)
if kubectl -n "$NS" get pod holy-api >/dev/null 2>&1; then
  fail "The original single Pod 'holy-api' still exists. Delete it after creating the Deployment."
fi

# 4) Deployment should be rolling out and have 3 ready
kubectl -n "$NS" rollout status deploy/"$DEP" --timeout=120s >/dev/null 2>&1 || \
  fail "Deployment '$DEP' did not become Ready."

READY=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.status.readyReplicas}')
[[ "$READY" == "3" ]] || fail "Deployment '$DEP' should have 3 ready replicas (found ${READY:-0})."

# 5) The YAML file should be saved under the requested path and be a Deployment with correct name
[[ -f "$RAW_DEP_FILE" ]] || fail "Expected saved YAML at $RAW_DEP_FILE not found."
KIND=$(yq '.kind' "$RAW_DEP_FILE" 2>/dev/null || echo "")
NAME=$(yq '.metadata.name' "$RAW_DEP_FILE" 2>/dev/null || echo "")
if [[ -z "$KIND" || -z "$NAME" ]]; then
  # Fallback to kubectl if yq not present
  KIND=$(kubectl create --dry-run=client -f "$RAW_DEP_FILE" -o json 2>/dev/null | jq -r '.kind' || true)
  NAME=$(kubectl create --dry-run=client -f "$RAW_DEP_FILE" -o json 2>/dev/null | jq -r '.metadata.name' || true)
fi
[[ "$KIND" == "Deployment" && "$NAME" == "$DEP" ]] || fail "Saved YAML must be a Deployment named '$DEP' (found kind='$KIND' name='$NAME')."

pass "Verification successful! Deployment '$DEP' with securityContext is created, replicas=3, original Pod removed, and YAML saved."
