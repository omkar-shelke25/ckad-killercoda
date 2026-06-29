#!/bin/bash

echo "Preparing lab environment..."

NS="pluto"
POD_NAME="holy-api"
RAW_DIR="/opt/course/9"
RAW_POD="${RAW_DIR}/holy-api-pod.yaml"

# Namespace
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

# Ensure directory exists
mkdir -p "$RAW_DIR"

# Write the raw Pod template — students will use this as the base for their Deployment
cat > "$RAW_POD" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: holy-api
  labels:
    app: holy-api
spec:
  containers:
  - name: app
    image: busybox:latest
    command: ["/bin/sh", "-c", "sleep 1d"]
EOF

# Create the Pod if it doesn't already exist
if ! kubectl -n "$NS" get pod "$POD_NAME" >/dev/null 2>&1; then
  kubectl -n "$NS" apply -f "$RAW_POD"
  kubectl -n "$NS" wait --for=condition=Ready pod/"$POD_NAME" --timeout=90s || true
fi

echo ""
echo "======================================"
echo "Setup complete!"
echo "Namespace : $NS"
echo "Pod       : $POD_NAME"
echo "Template  : $RAW_POD"
echo ""
echo "Your task: Convert the Pod into a Deployment!"
echo "======================================"