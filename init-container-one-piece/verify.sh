#!/bin/bash
set -euo pipefail

NS="one-piece"
CM="strawhat-cm"
DEP="strawhat-deploy"
SVC="strawhat-svc"
EXPECT_REPLICAS="1"
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

# 4) Check replicas
REPLICAS="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.replicas}')"
[[ "$REPLICAS" == "$EXPECT_REPLICAS" ]] || fail "Expected replicas=$EXPECT_REPLICAS but found '${REPLICAS:-<none>}.'"

# 5) Check main container
CONTAINER_NAME="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].name}')"
[[ "$CONTAINER_NAME" == "strawhat-nginx" ]] || fail "Expected container name 'strawhat-nginx' but found '$CONTAINER_NAME'."

IMG="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].image}')"
[[ "$IMG" == "$EXPECT_IMAGE" ]] || fail "Expected image '$EXPECT_IMAGE' but found '$IMG'."

# 6) Check initContainer
INIT_NAME="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.initContainers[0].name}')"
[[ "$INIT_NAME" == "init-copy" ]] || fail "Expected initContainer name 'init-copy' but found '$INIT_NAME'."

INIT_IMG="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.initContainers[0].image}')"
[[ "$INIT_IMG" == "$EXPECT_INIT_IMAGE" ]] || fail "Expected initContainer image '$EXPECT_INIT_IMAGE' but found '$INIT_IMG'."

# 7) Check volumes
CONFIG_VOL="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.volumes[?(@.configMap.name=="'"$CM"'")].name}')"
[[ -n "$CONFIG_VOL" ]] || fail "ConfigMap volume referencing '$CM' not found in deployment."

EMPTY_VOL="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.volumes[?(@.emptyDir)].name}')"
[[ -n "$EMPTY_VOL" ]] || fail "emptyDir volume not found in deployment."

# 8) Deployment should be ready
kubectl -n "$NS" rollout status "deploy/$DEP" --timeout=120s >/dev/null 2>&1 \
  || fail "Deployment '$DEP' did not become Ready in time."

READY="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.status.readyReplicas}')"
[[ "$READY" == "$EXPECT_REPLICAS" ]] || fail "Expected $EXPECT_REPLICAS ready replicas but found '${READY:-0}'."

# 9) Service exists and is NodePort
kubectl -n "$NS" get service "$SVC" >/dev/null 2>&1 || fail "Service '$SVC' not found in namespace '$NS'."

SVC_TYPE="$(kubectl -n "$NS" get service "$SVC" -o jsonpath='{.spec.type}')"
[[ "$SVC_TYPE" == "NodePort" ]] || fail "Expected service type 'NodePort' but found '$SVC_TYPE'."

# 10) Check NodePort
NODEPORT="$(kubectl -n "$NS" get service "$SVC" -o jsonpath='{.spec.ports[0].nodePort}')"
[[ "$NODEPORT" == "$EXPECT_NODEPORT" ]] || fail "Expected NodePort=$EXPECT_NODEPORT but found '${NODEPORT:-<none>}.'"

# 11) Check service selector
SELECTOR="$(kubectl -n "$NS" get service "$SVC" -o jsonpath='{.spec.selector.app}')"
[[ "$SELECTOR" == "strawhat" ]] || fail "Expected service selector 'app=strawhat' but found 'app=${SELECTOR:-<none>}.'"

# 12) Verify content is accessible (case-insensitive title + LUFFY)
sleep 5
RESPONSE="$(curl -s --max-time 5 localhost:$EXPECT_NODEPORT || true)"
[[ -n "$RESPONSE" ]] || fail "No HTTP response from localhost:$EXPECT_NODEPORT. Are you running this on a cluster node?"
echo "$RESPONSE" | grep -qi "One Piece Terminal - Straw Hat Pirates Database" \
  || fail "Service content check failed: page title not found in HTTP response."
echo "$RESPONSE" | grep -q "MONKEY D\. LUFFY" \
  || fail "Service content check failed: 'MONKEY D. LUFFY' not found in HTTP response."

pass "Verification successful! Deployment '$DEP', ConfigMap '$CM', InitContainer, and Service '$SVC' (NodePort: $NODEPORT) are correctly configured and serving content."
