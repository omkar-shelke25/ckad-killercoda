#!/bin/bash
set -euo pipefail

# Create namespace
kubectl create namespace sec-ctx

echo "Namespace 'sec-ctx' created for your work."
