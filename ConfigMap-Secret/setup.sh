#!/bin/bash
set -e

# Prepare namespace for the challenge
kubectl get ns apps >/dev/null 2>&1 || kubectl create namespace apps

echo "✅ Setup complete. Namespace 'apps' is ready."
