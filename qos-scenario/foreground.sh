#!/bin/bash
# This script runs automatically before the scenario starts

echo "📦 Setting up environment for CKAD Practice..."

# Create mars namespace
kubectl create namespace mars --dry-run=client -o yaml | kubectl apply -f -

echo "✅ mars namespace is ready for the scenario!"
