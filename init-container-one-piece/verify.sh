#!/bin/bash
set -euo pipefail

NS="one-piece"
CM="strawhat-cm"
DEP="strawhat-deploy"
SVC="strawhat-svc"
EXPECT_REPLICAS="1"
EXPECT_PORT="80"
EXPECT_NODEPORT="32100"
EXPECT_IMAGE="public.ecr.aws/nginx/nginx:latest"
EXPECT_INIT_IMAGE="public.ecr.aws/docker/library/busybox:latest"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# 1) Namespace exists
kubectl get namespace "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."

# 2) ConfigMap exists and has index.html (case-insensitive title check)
kubectl -n "$NS" get configmap "$CM" >/dev/null 2>&1 || fail "ConfigMap '$CM' not found in namespace '$NS'."
CM_HTML="$(kubectl -n "$NS" get configmap "$CM" -o jsonpath='{.data.index\.html}' || true)"
[[ -n "${CM_HTML}" ]] || fail "ConfigMap '$CM' has no 'index.html' key."
echo "$CM_HTML" | grep -qi "One Piece Terminal - Straw Hat Pirates Database" \
  || fail "ConfigMap '$CM' index.html missing expected title text."
pass "ConfigMap '$CM' contains index.html with expected title."

# 3) Deployment exists
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || fail "Deployment '$DEP' not found in namespace '$NS'."

# 4) Replica count
REPLICAS="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.replicas}')"
[[ "$REPLICAS" == "$EXPECT_REPLICAS" ]] || fail "Expected replicas=$EXPECT_REPLICAS but found '${REPLICAS:-<none>}'."

# 5) Main container name and image
CONTAINER_NAME="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].name}')"
[[ "$CONTAINER_NAME" == "strawhat-nginx" ]] || fail "Expected container name 'strawhat-nginx' but found '$CONTAINER_NAME'."

IMG="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].image}')"
[[ "$IMG" == "$EXPECT_IMAGE" ]] || fail "Expected image '$EXPECT_IMAGE' but found '$IMG'."
pass "Deployment '$DEP' has correct replicas, container name, and image."

# 6) InitContainer name and image
INIT_NAME="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.initContainers[0].name}')"
[[ "$INIT_NAME" == "init-copy" ]] || fail "Expected initContainer name 'init-copy' but found '$INIT_NAME'."

INIT_IMG="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.initContainers[0].image}')"
[[ "$INIT_IMG" == "$EXPECT_INIT_IMAGE" ]] || fail "Expected initContainer image '$EXPECT_INIT_IMAGE' but found '$INIT_IMG'."
pass "InitContainer '$INIT_NAME' configured correctly."

# 7) Volumes: a ConfigMap-backed volume and an emptyDir volume must both exist,
#    and must be wired up correctly between the InitContainer and main container.
DEP_JSON="$(kubectl -n "$NS" get deploy "$DEP" -o json)"

CM_VOL_NAME="$(echo "$DEP_JSON" | jq -r --arg cm "$CM" \
  '.spec.template.spec.volumes[]? | select(.configMap.name == $cm) | .name' | head -n1)"
[[ -n "$CM_VOL_NAME" ]] || fail "No volume backed by ConfigMap '$CM' found in Deployment '$DEP'."

EMPTYDIR_VOL_NAME="$(echo "$DEP_JSON" | jq -r \
  '.spec.template.spec.volumes[]? | select(has("emptyDir")) | .name' | head -n1)"
[[ -n "$EMPTYDIR_VOL_NAME" ]] || fail "No emptyDir volume found in Deployment '$DEP' (needed to share the copied file with the main container)."
pass "Deployment defines a ConfigMap volume ('$CM_VOL_NAME') and an emptyDir volume ('$EMPTYDIR_VOL_NAME')."

# InitContainer must mount both the ConfigMap volume (to read the source file)
# and the emptyDir volume at /usr/share/nginx/html (to write the copy destination).
INIT_MOUNTS_CM="$(echo "$DEP_JSON" | jq -r --arg v "$CM_VOL_NAME" \
  '.spec.template.spec.initContainers[0].volumeMounts[]? | select(.name == $v) | .name')"
[[ -n "$INIT_MOUNTS_CM" ]] || fail "InitContainer '$INIT_NAME' does not mount the ConfigMap volume '$CM_VOL_NAME'."

INIT_HTML_MOUNT="$(echo "$DEP_JSON" | jq -r --arg v "$EMPTYDIR_VOL_NAME" \
  '.spec.template.spec.initContainers[0].volumeMounts[]? | select(.name == $v) | .mountPath')"
[[ "$INIT_HTML_MOUNT" == "/usr/share/nginx/html" ]] \
  || fail "InitContainer '$INIT_NAME' must mount the emptyDir volume at /usr/share/nginx/html (found '${INIT_HTML_MOUNT:-<not mounted>}')."

# Main container must mount the SAME emptyDir volume at the same path — this is
# what actually shares the copied file after the InitContainer terminates.
MAIN_HTML_MOUNT="$(echo "$DEP_JSON" | jq -r --arg v "$EMPTYDIR_VOL_NAME" \
  '.spec.template.spec.containers[0].volumeMounts[]? | select(.name == $v) | .mountPath')"
[[ "$MAIN_HTML_MOUNT" == "/usr/share/nginx/html" ]] \
  || fail "Container 'strawhat-nginx' must mount the same emptyDir volume ('$EMPTYDIR_VOL_NAME') at /usr/share/nginx/html (found '${MAIN_HTML_MOUNT:-<not mounted, or mounting a different volume>}')."

pass "emptyDir volume is correctly shared between InitContainer and main container at /usr/share/nginx/html."

# 8) Deployment becomes ready
kubectl -n "$NS" rollout status "deploy/$DEP" --timeout=120s >/dev/null 2>&1 \
  || fail "Deployment '$DEP' did not become Ready in time."

READY="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.status.readyReplicas}')"
[[ "$READY" == "$EXPECT_REPLICAS" ]] || fail "Expected $EXPECT_REPLICAS ready replicas but found '${READY:-0}'."
pass "Deployment '$DEP' is ready ($READY/$EXPECT_REPLICAS)."

# 9) Service exists and is NodePort
kubectl -n "$NS" get service "$SVC" >/dev/null 2>&1 || fail "Service '$SVC' not found in namespace '$NS'."

SVC_TYPE="$(kubectl -n "$NS" get service "$SVC" -o jsonpath='{.spec.type}')"
[[ "$SVC_TYPE" == "NodePort" ]] || fail "Expected service type 'NodePort' but found '$SVC_TYPE'."

# 10) Service port
SVC_PORT="$(kubectl -n "$NS" get service "$SVC" -o jsonpath='{.spec.ports[0].port}')"
[[ "$SVC_PORT" == "$EXPECT_PORT" ]] || fail "Expected service port=$EXPECT_PORT but found '${SVC_PORT:-<none>}'."

# 11) NodePort
NODEPORT="$(kubectl -n "$NS" get service "$SVC" -o jsonpath='{.spec.ports[0].nodePort}')"
[[ "$NODEPORT" == "$EXPECT_NODEPORT" ]] || fail "Expected NodePort=$EXPECT_NODEPORT but found '${NODEPORT:-<none>}'."

# 12) Service selector
SELECTOR="$(kubectl -n "$NS" get service "$SVC" -o jsonpath='{.spec.selector.app}')"
[[ "$SELECTOR" == "strawhat" ]] || fail "Expected service selector 'app=strawhat' but found 'app=${SELECTOR:-<none>}'."
pass "Service '$SVC' is NodePort, port $SVC_PORT, nodePort $NODEPORT, selector app=strawhat."

# 13) Content is actually being served (case-insensitive title + a known crew member)
sleep 5
RESPONSE="$(curl -s --max-time 5 localhost:$EXPECT_NODEPORT || true)"
[[ -n "$RESPONSE" ]] || fail "No HTTP response from localhost:$EXPECT_NODEPORT. Are you running this on a cluster node?"
echo "$RESPONSE" | grep -qi "One Piece Terminal - Straw Hat Pirates Database" \
  || fail "Service content check failed: page title not found in HTTP response."
echo "$RESPONSE" | grep -q "MONKEY D\. LUFFY" \
  || fail "Service content check failed: 'MONKEY D. LUFFY' not found in HTTP response."

pass "Verification successful! Deployment '$DEP', ConfigMap '$CM', InitContainer, volumes, and Service '$SVC' (NodePort: $NODEPORT) are correctly configured and serving content."
