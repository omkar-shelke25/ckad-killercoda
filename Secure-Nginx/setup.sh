#!/bin/bash
set -e

# Prepare namespace for the challenge
kubectl get ns web >/dev/null 2>&1 || kubectl create namespace web

echo "✅ Setup complete. Namespace 'web' is ready."
