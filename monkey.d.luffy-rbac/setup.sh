#!/bin/bash
# Killercoda setup script – runs as root in the background before the scenario starts
# Using || true on non-critical steps so a single hiccup doesn't abort everything.

NS="one-piece"
DEP="monkey-d-luffy"
MONITOR_DEP="crew-monitor"
# Docker Hub bitnami/kubectl is reliably available on Killercoda nodes
BASE_IMAGE="bitnami/kubectl:latest"
BASE_REPLICAS=2

echo "Preparing lab environment..."

# ---------- Namespace ----------
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

# ---------- Deployment 1: monkey-d-luffy (uses default SA — will fail RBAC) ----------
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $DEP
  namespace: $NS
  labels:
    app: luffy
    crew: strawhat
spec:
  replicas: $BASE_REPLICAS
  selector:
    matchLabels:
      app: luffy
  template:
    metadata:
      labels:
        app: luffy
    spec:
      # No serviceAccountName → uses "default" SA (student must fix this)
      containers:
        - name: luffy-container
          image: $BASE_IMAGE
          command: ["/bin/sh", "-c"]
          args:
            - |
              echo "Luffy's pod starting..."
              while true; do
                echo "--- \$(date) ---"
                kubectl get deployments -n one-piece 2>&1 | head -5
                sleep 60
              done
          resources:
            requests:
              cpu: "50m"
              memory: "32Mi"
            limits:
              cpu: "100m"
              memory: "64Mi"
EOF

# ---------- ServiceAccount for crew-monitor (no Role/RoleBinding yet) ----------
kubectl create serviceaccount nami-navigator -n "$NS" --dry-run=client -o yaml | kubectl apply -f -

# ---------- Deployment 2: crew-monitor (has SA, but no Role/RoleBinding yet) ----------
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $MONITOR_DEP
  namespace: $NS
  labels:
    app: crew-monitor
    crew: strawhat
spec:
  replicas: 1
  selector:
    matchLabels:
      app: crew-monitor
  template:
    metadata:
      labels:
        app: crew-monitor
    spec:
      serviceAccountName: nami-navigator
      securityContext:
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: monitor-container
          image: $BASE_IMAGE
          command: ["/bin/sh", "-c"]
          args:
            - |
              echo "Crew Monitor starting..."
              while true; do
                echo "--- \$(date) ---"
                if kubectl get deployments -n one-piece 2>&1; then
                  echo "SUCCESS: deployments listed."
                else
                  echo "ERROR: RBAC denied. Fix the Role and RoleBinding!"
                fi
                sleep 30
              done
          resources:
            requests:
              cpu: "50m"
              memory: "32Mi"
            limits:
              cpu: "100m"
              memory: "64Mi"
          securityContext:
            allowPrivilegeEscalation: false
            # readOnlyRootFilesystem intentionally NOT set:
            # kubectl needs a writable /tmp to cache discovery info.
            runAsUser: 1000
            runAsGroup: 1000
EOF

# ---------- Wait (best-effort) ----------
kubectl -n "$NS" rollout status deploy/"$DEP"        --timeout=120s || true
kubectl -n "$NS" rollout status deploy/"$MONITOR_DEP" --timeout=120s || true

echo ""
echo "=========================================="
echo "Lab environment ready!"
echo "Namespace : $NS"
echo ""
echo "Deployments:"
echo "  $DEP      → uses 'default' SA  (RBAC errors expected)"
echo "  $MONITOR_DEP  → uses 'nami-navigator' SA (RBAC errors expected)"
echo ""
echo "View errors with:"
echo "  kubectl logs deployment/$DEP -n $NS --tail=5"
echo "  kubectl logs deployment/$MONITOR_DEP -n $NS --tail=5"
echo ""
echo "Your task: Fix RBAC so both deployments can list deployments!"
echo "=========================================="
