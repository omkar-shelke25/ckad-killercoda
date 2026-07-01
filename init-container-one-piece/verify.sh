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
ROLLOUT_TIMEOUT="60s"   # was 120s — 1 replica of nginx doesn't need 2 minutes

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# 1) Namespace exists
kubectl get namespace "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."

# 2) ConfigMap exists and has index.html — ONE call instead of two
CM_JSON="$(kubectl -n "$NS" get configmap "$CM" -o json 2>/dev/null)" \
  || fail "ConfigMap '$CM' not found in namespace '$NS'."
CM_HTML="$(echo "$CM_JSON" | jq -r '.data["index.html"] // empty')"
[[ -n "${CM_HTML}" ]] || fail "ConfigMap '$CM' has no 'index.html' key."
echo "$CM_HTML" | grep -qi "One Piece Terminal - Straw Hat Pirates Database" \
  || fail "ConfigMap '$CM' index.html missing expected title text."
pass "ConfigMap '$CM' contains index.html with expected title."

# 3-7) Deployment: fetch the full object ONCE, then derive everything with jq.
#      (was ~9 separate kubectl calls — now just this one)
DEP_JSON="$(kubectl -n "$NS" get deploy "$DEP" -o json 2>/dev/null)" \
  || fail "Deployment '$DEP' not found in namespace '$NS'."

REPLICAS="$(echo "$DEP_JSON" | jq -r '.spec.replicas')"
[[ "$REPLICAS" == "$EXPECT_REPLICAS" ]] || fail "Expected replicas=$EXPECT_REPLICAS but found '${REPLICAS:-<none>}'."

CONTAINER_NAME="$(echo "$DEP_JSON" | jq -r '.spec.template.spec.containers[0].name')"
[[ "$CONTAINER_NAME" == "strawhat-nginx" ]] || fail "Expected container name 'strawhat-nginx' but found '$CONTAINER_NAME'."

IMG="$(echo "$DEP_JSON" | jq -r '.spec.template.spec.containers[0].image')"
[[ "$IMG" == "$EXPECT_IMAGE" ]] || fail "Expected image '$EXPECT_IMAGE' but found '$IMG'."
pass "Deployment '$DEP' has correct replicas, container name, and image."

INIT_NAME="$(echo "$DEP_JSON" | jq -r '.spec.template.spec.initContainers[0].name // empty')"
[[ "$INIT_NAME" == "init-copy" ]] || fail "Expected initContainer name 'init-copy' but found '${INIT_NAME:-<none>}'."

INIT_IMG="$(echo "$DEP_JSON" | jq -r '.spec.template.spec.initContainers[0].image // empty')"
[[ "$INIT_IMG" == "$EXPECT_INIT_IMAGE" ]] || fail "Expected initContainer image '$EXPECT_INIT_IMAGE' but found '${INIT_IMG:-<none>}'."
pass "InitContainer '$INIT_NAME' configured correctly."

CM_VOL_NAME="$(echo "$DEP_JSON" | jq -r --arg cm "$CM" \
  '.spec.template.spec.volumes[]? | select(.configMap.name == $cm) | .name' | head -n1)"
[[ -n "$CM_VOL_NAME" ]] || fail "No volume backed by ConfigMap '$CM' found in Deployment '$DEP'."

EMPTYDIR_VOL_NAME="$(echo "$DEP_JSON" | jq -r \
  '.spec.template.spec.volumes[]? | select(has("emptyDir")) | .name' | head -n1)"
[[ -n "$EMPTYDIR_VOL_NAME" ]] || fail "No emptyDir volume found in Deployment '$DEP' (needed to share the copied file with the main container)."
pass "Deployment defines a ConfigMap volume ('$CM_VOL_NAME') and an emptyDir volume ('$EMPTYDIR_VOL_NAME')."

INIT_MOUNTS_CM="$(echo "$DEP_JSON" | jq -r --arg v "$CM_VOL_NAME" \
  '.spec.template.spec.initContainers[0].volumeMounts[]? | select(.name == $v) | .name')"
[[ -n "$INIT_MOUNTS_CM" ]] || fail "InitContainer '$INIT_NAME' does not mount the ConfigMap volume '$CM_VOL_NAME'."

INIT_HTML_MOUNT="$(echo "$DEP_JSON" | jq -r --arg v "$EMPTYDIR_VOL_NAME" \
  '.spec.template.spec.initContainers[0].volumeMounts[]? | select(.name == $v) | .mountPath')"
[[ "$INIT_HTML_MOUNT" == "/usr/share/nginx/html" ]] \
  || fail "InitContainer '$INIT_NAME' must mount the emptyDir volume at /usr/share/nginx/html (found '${INIT_HTML_MOUNT:-<not mounted>}')."

MAIN_HTML_MOUNT="$(echo "$DEP_JSON" | jq -r --arg v "$EMPTYDIR_VOL_NAME" \
  '.spec.template.spec.containers[0].volumeMounts[]? | select(.name == $v) | .mountPath')"
[[ "$MAIN_HTML_MOUNT" == "/usr/share/nginx/html" ]] \
  || fail "Container 'strawhat-nginx' must mount the same emptyDir volume ('$EMPTYDIR_VOL_NAME') at /usr/share/nginx/html (found '${MAIN_HTML_MOUNT:-<not mounted, or mounting a different volume>}')."

pass "emptyDir volume is correctly shared between InitContainer and main container at /usr/share/nginx/html."

# 8) Deployment becomes ready (this is a real wait — can't be skipped, but timeout is trimmed)
kubectl -n "$NS" rollout status "deploy/$DEP" --timeout="$ROLLOUT_TIMEOUT" >/dev/null 2>&1 \
  || fail "Deployment '$DEP' did not become Ready in time."

READY="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.status.readyReplicas}')"
[[ "$READY" == "$EXPECT_REPLICAS" ]] || fail "Expected $EXPECT_REPLICAS ready replicas but found '${READY:-0}'."
pass "Deployment '$DEP' is ready ($READY/$EXPECT_REPLICAS)."

# 9-12) Service: fetch ONCE, derive everything with jq (was 5 separate kubectl calls)
SVC_JSON="$(kubectl -n "$NS" get service "$SVC" -o json 2>/dev/null)" \
  || fail "Service '$SVC' not found in namespace '$NS'."

SVC_TYPE="$(echo "$SVC_JSON" | jq -r '.spec.type')"
[[ "$SVC_TYPE" == "NodePort" ]] || fail "Expected service type 'NodePort' but found '$SVC_TYPE'."

SVC_PORT="$(echo "$SVC_JSON" | jq -r '.spec.ports[0].port')"
[[ "$SVC_PORT" == "$EXPECT_PORT" ]] || fail "Expected service port=$EXPECT_PORT but found '${SVC_PORT:-<none>}'."

NODEPORT="$(echo "$SVC_JSON" | jq -r '.spec.ports[0].nodePort')"
[[ "$NODEPORT" == "$EXPECT_NODEPORT" ]] || fail "Expected NodePort=$EXPECT_NODEPORT but found '${NODEPORT:-<none>}'."

SELECTOR="$(echo "$SVC_JSON" | jq -r '.spec.selector.app // empty')"
[[ "$SELECTOR" == "strawhat" ]] || fail "Expected service selector 'app=strawhat' but found 'app=${SELECTOR:-<none>}'."
pass "Service '$SVC' is NodePort, port $SVC_PORT, nodePort $NODEPORT, selector app=strawhat."

# 13) Content is actually being served.
# CHANGED: the old script did a blind `sleep 5` then a single curl attempt — that's
# both slower than necessary when the Service is already up (always pays the 5s tax)
# AND flaky when it's not (a single shot right after rollout can hit the Service
# before kube-proxy/iptables rules have propagated, giving a false failure).
# curl's own retry flags fix both: it returns the instant the endpoint answers,
# and it keeps retrying (specifically on connection-refused) if it's not ready yet.
# -w appends the HTTP status code after the body so we can assert on it too —
# a 4xx/5xx page can still have a non-empty body, so the old "just check
# non-empty" logic would have silently passed on a broken response.
CURL_OUT="$(curl -s \
  --max-time 5 \
  --retry 10 \
  --retry-delay 1 \
  --retry-connrefused \
  -w '\nHTTPSTATUS:%{http_code}' \
  "http://localhost:$EXPECT_NODEPORT" || true)"

HTTP_STATUS="$(echo "$CURL_OUT" | grep -o 'HTTPSTATUS:[0-9]*$' | cut -d: -f2)"
RESPONSE="$(echo "$CURL_OUT" | sed 's/HTTPSTATUS:[0-9]*$//')"

[[ -n "$RESPONSE" ]] || fail "No HTTP response from localhost:$EXPECT_NODEPORT. Are you running this on a cluster node?"
[[ "$HTTP_STATUS" == "200" ]] || fail "Expected HTTP status 200 but got '${HTTP_STATUS:-<none>}'."
pass "Service responded with HTTP 200."

echo "$RESPONSE" | grep -qi "One Piece Terminal - Straw Hat Pirates Database" \
  || fail "Service content check failed: page title not found in HTTP response."
echo "$RESPONSE" | grep -q "MONKEY D\. LUFFY" \
  || fail "Service content check failed: 'MONKEY D. LUFFY' not found in HTTP response."

pass "Verification successful! Deployment '$DEP', ConfigMap '$CM', InitContainer, volumes, and Service '$SVC' (NodePort: $NODEPORT) are correctly configured and serving content."
