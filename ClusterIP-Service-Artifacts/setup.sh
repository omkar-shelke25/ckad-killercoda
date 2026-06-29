#!/bin/bash

NS="pluto"

# Create namespace
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

# Create artifact directory with open permissions
mkdir -p /opt/course/10
chmod 0777 /opt/course/10

echo ""
echo "======================================"
echo "Setup complete!"
echo "Namespace  : $NS"
echo "Artifacts  : /opt/course/10"
echo ""
echo "Your task: Create the Pod, Service, and save the artifacts."
echo "======================================"
