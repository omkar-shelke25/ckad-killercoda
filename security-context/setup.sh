#!/bin/bash
set -e

# Create a dedicated namespace for the challenge
kubectl get ns security >/dev/null 2>&1 || kubectl create namespace security

echo "✅ Setup complete. Namespace 'security' is ready."
