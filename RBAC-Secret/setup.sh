#!/bin/bash

echo "Preparing lab environment..."

NS="finance"

# Pre-create only the namespace — student creates everything else
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

echo ""
echo "======================================"
echo "Setup complete!"
echo "Namespace '$NS' is ready."
echo ""
echo "Your task: Create the Secret, ServiceAccount, Role, and RoleBinding."
echo "======================================"