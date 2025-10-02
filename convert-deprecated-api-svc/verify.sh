#!/bin/bash
set -euo pipefail

NS="interstellar"
DEPLOY="gargantuan"
SERVICE="gargantuan-svc"
NODEPORT_EXPECT=33000

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

echo "==> 0) Check for kubectl convert plugin availability"

# Try 'kubectl convert' (plugin style). Some plugin installations respond with usage and exit 0/1.
if kubectl convert --help >/dev/null 2>&1; then
  pass "kubectl convert appears to be available (as a kubectl plugin)."
else
  # Try checking for a standalone kubectl-convert binary in PATH
  if command -v kubectl-convert >/dev/null 2>&1; then
    pass "kubectl-convert binary found in PATH."
  else
    cat <<EOF
❌ kubectl convert (conversion plugin) not found.

Notes / next steps:
 - The 'convert' feature was removed from the main kubectl and is provided as a plugin/binary. You can:
   * Install a convert-capable plugin/binary, or
   * Use Krew (kubectl plugin manager) to find and install an appropriate plugin.

Useful docs:
 - Extending kubectl with plugins: https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/ (shows plugin mechanism).
 - Krew (plugin manager) quickstart: https://krew.sigs.k8s.io/docs/user-guide/quickstart/

Example (Krew route):
  # install krew (follow platform-specific steps)
  (follow instructions at https://krew.sigs.k8s.io/docs/user-guide/setup/install/)
  kubectl krew update
  kubectl krew search convert
  kubectl krew install <found-plugin-name>

Because conversion is required by this scenario, please install a convert plugin or provide an already-converted file at:
/blackhole/gargantuan.yaml

EOF
    exit 2
  fi
fi

echo
echo "==> 1) Namespace exists"
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."
pass "Namespace '$NS' exists"

echo "==> 2) Deployment exists and apiVersion is apps/v1"
kubectl -n "$NS" get deploy "$DEPLOY" >/dev/null 2>&1 || fail "Deployment '$DEPLOY' not found in namespace '$NS'."
APIVER=$(kubectl -n "$NS" get deploy "$DEPLOY" -o jsonpath='{.apiVersion}')
[[ "$APIVER" == "apps/v1" ]] || fail "Deployment apiVersion must be apps/v1 (found '$APIVER')."
pass "Deployment uses supported apiVersion: $APIVER"

echo "==> 3) Deployment has selector.matchLabels"
SEL=$(kubectl -n "$NS" get deploy "$DEPLOY" -o jsonpath='{.spec.selector.matchLabels}' 2>/dev/null || true)
[[ -n "$SEL" ]] || fail "Deployment missing .spec.selector.matchLabels. Add a selector that matches the pod template labels."
pass "Deployment has selector.matchLabels"

echo "==> 4) Pods are Running"
RUNNING=$(kubectl -n "$NS" get pods -l app=$DEPLOY --field-selector=status.phase=Running -o jsonpath='{.items[*].metadata.name}' || true)
if [[ -z "$RUNNING" ]]; then
  fail "No running pods found for Deployment '$DEPLOY'."
fi
pass "Found running pods: $RUNNING"

POD=$(echo "$RUNNING" | awk '{print $1}')

echo "==> 5) Pod uses expected image"
IMG=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[0].image}')
[[ "$IMG" == "public.ecr.aws/nginx/nginx:latest" ]] || fail "Pod image must be public.ecr.aws/nginx/nginx:latest (found '$IMG')."
pass "Pod is using the expected image: $IMG"

echo "==> 6) Service exists and nodePort is correct"
kubectl -n "$NS" get svc "$SERVICE" >/dev/null 2>&1 || fail "Service '$SERVICE' not found in namespace '$NS'."
NP=$(kubectl -n "$NS" get svc "$SERVICE" -o jsonpath='{.spec.ports[0].nodePort}')
[[ "$NP" == "$NODEPORT_EXPECT" ]] || fail "Service nodePort must be $NODEPORT_EXPECT (found '$NP')."
pass "Service '$SERVICE' exposes nodePort: $NP"

echo "==> 7) Check the HTML file exists inside the pod"
kubectl -n "$NS" exec "$POD" -- test -s /usr/share/nginx/html/gargantua-scifi.html || fail "File /usr/share/nginx/html/gargantua-scifi.html not present or empty in pod $POD."
pass "HTML file is present inside pod: /usr/share/nginx/html/gargantua-scifi.html"

# Optional HTTP check (may not be reachable from sandbox)
if command -v curl >/dev/null 2>&1; then
  if curl -sS --max-time 3 http://127.0.0.1:$NODEPORT_EXPECT/ | grep -q -i "gargantua"; then
    pass "Service responded on http://127.0.0.1:$NODEPORT_EXPECT"
  else
    echo "⚠️ Could not confirm HTTP response from localhost:$NODEPORT_EXPECT (may be blocked in this environment)."
  fi
fi

pass "🎉 Verification complete — all checks passed."
