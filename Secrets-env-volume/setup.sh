#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

NS="moon"
BASE="/opt/course/14"
RAW_POD="${BASE}/secret-handler.yaml"
SECRET2_YAML="${BASE}/secret2.yaml"

# Namespace
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

# Ensure folder
mkdir -p "$BASE"

# Existing Pod raw template (busybox, no secrets yet)
cat >"$RAW_POD" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: secret-handler
  namespace: moon
  labels:
    app: secret-handler
spec:
  containers:
  - name: app
    image: busybox:1.37.0
    command: ["/bin/sh","-c","sleep 1d"]
EOF

# Apply the existing Pod
if ! kubectl -n "$NS" get pod secret-handler >/dev/null 2>&1; then
  kubectl apply -f "$RAW_POD"
  kubectl -n "$NS" wait --for=condition=Ready pod/secret-handler --timeout=120s || true
fi

# Provide raw YAML for another Secret (learner must kubectl apply it)
# Keys aren't important beyond mounting; include two example keys.
cat >"$SECRET2_YAML" <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: secret2
  namespace: moon
type: Opaque
data:
  alpha: YmV0YQ==
  beta: Zm9v
EOF

echo "Setup complete:"
echo "  - Existing Pod YAML: $RAW_POD"
echo "  - Provided Secret YAML: $SECRET2_YAML"
