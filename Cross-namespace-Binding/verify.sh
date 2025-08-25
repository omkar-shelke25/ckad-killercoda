#!/bin/bash
# Setup script: Create RBAC resources for log-scraper-sa to read pods/log in app-prod
set -euo pipefail

NS_TARGET="app-prod"
NS_SA="default"
SA="log-scraper-sa"
ROLE="log-reader-role"
RB="log-scraper-binding"

echo "🚀 Setting up RBAC for log scraper..."

# --- 1) Create namespaces if they don't exist ---
echo "📁 Checking namespaces..."
if ! kubectl get ns "$NS_TARGET" >/dev/null 2>&1; then
    kubectl create namespace "$NS_TARGET"
    echo "✅ Created namespace '$NS_TARGET'"
else
    echo "✅ Namespace '$NS_TARGET' already exists"
fi

if ! kubectl get ns "$NS_SA" >/dev/null 2>&1; then
    kubectl create namespace "$NS_SA"
    echo "✅ Created namespace '$NS_SA'"
else
    echo "✅ Namespace '$NS_SA' already exists"
fi

# --- 2) Create ServiceAccount ---
echo "👤 Creating ServiceAccount..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $SA
  namespace: $NS_SA
EOF
echo "✅ ServiceAccount '$SA' created in '$NS_SA'"

# --- 3) Create Role (read-only access to pods/log in app-prod) ---
echo "🔐 Creating Role..."
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: $NS_TARGET
  name: $ROLE
rules:
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
EOF
echo "✅ Role '$ROLE' created in '$NS_TARGET'"

# --- 4) Create RoleBinding ---
echo "🔗 Creating RoleBinding..."
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: $RB
  namespace: $NS_TARGET
subjects:
- kind: ServiceAccount
  name: $SA
  namespace: $NS_SA
roleRef:
  kind: Role
  name: $ROLE
  apiGroup: rbac.authorization.k8s.io
EOF
echo "✅ RoleBinding '$RB' created in '$NS_TARGET'"

# --- 5) Verify the setup ---
echo "🔍 Verifying RBAC setup..."
sleep 2  # Give RBAC a moment to propagate

SA_FQN="system:serviceaccount:${NS_SA}:${SA}"

# Test positive permission
if kubectl auth can-i get pods --subresource=log -n "$NS_TARGET" --as="$SA_FQN" --quiet 2>/dev/null; then
    echo "✅ ServiceAccount CAN get pods/log in '$NS_TARGET'"
else
    echo "❌ ServiceAccount CANNOT get pods/log in '$NS_TARGET'"
fi

# Test negative permissions
if kubectl auth can-i get pods -n "$NS_TARGET" --as="$SA_FQN" --quiet 2>/dev/null; then
    echo "❌ ServiceAccount should NOT be able to get pods (without subresource)"
else
    echo "✅ ServiceAccount correctly CANNOT get pods (without subresource)"
fi

if kubectl auth can-i list pods --subresource=log -n "$NS_TARGET" --as="$SA_FQN" --quiet 2>/dev/null; then
    echo "❌ ServiceAccount should NOT be able to list pods/log"
else
    echo "✅ ServiceAccount correctly CANNOT list pods/log"
fi

echo ""
echo "🎉 RBAC setup complete!"
echo ""
echo "📋 Summary:"
echo "   • ServiceAccount: $NS_SA/$SA"
echo "   • Role: $NS_TARGET/$ROLE"
echo "   • RoleBinding: $NS_TARGET/$RB"
echo "   • Permissions: GET pods/log in $NS_TARGET namespace only"
echo ""
echo "🧪 To test manually:"
echo "   kubectl auth can-i get pods --subresource=log -n $NS_TARGET --as=system:serviceaccount:$NS_SA:$SA"
