#!/bin/bash
set -euo pipefail

# Prepare namespace (idempotent)
kubectl get ns ops >/dev/null 2>&1 || kubectl create namespace ops

echo "Namespace 'ops' is ready."
echo "Create a Pod 'data-mining' (httpd:trixie, port 80, label app=crypto-mining) and expose it as Service 'data-mining' on port 80."
