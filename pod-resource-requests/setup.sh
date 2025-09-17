#!/bin/bash
set -euo pipefail

echo "🚀 Setting up production environment for Project One..."

# Check if cluster has sufficient resources
echo "🔍 Checking cluster resource capacity..."

# Get node resources
kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.allocatable.cpu,MEMORY:.status.allocatable.memory

echo ""
echo "📊 Current resource usage:"
kubectl top nodes 2>/dev/null || echo "⚠️  Metrics server not available - continuing with setup"

echo ""
echo "📦 Environment ready for Project One deployment!"
echo ""
echo "🎯 Your Mission:"
echo "   1. Create namespace 'project-one' for project organization"
echo "   2. Deploy nginx pod 'nginx-resources' with specific resource requests"
echo "   3. Ensure guaranteed resource allocation for production workload"
echo ""
echo "📋 Requirements:"
echo "   • Namespace: project-one"
echo "   • Pod Name: nginx-resources"
echo "   • Image: nginx"
echo "   • CPU Request: 200m (0.2 CPU cores)"
echo "   • Memory Request: 1Gi (1 Gigabyte)"
echo ""
echo "💡 Resource Requests ensure your pod gets guaranteed resources!"
echo "   This prevents resource starvation in multi-tenant environments."
