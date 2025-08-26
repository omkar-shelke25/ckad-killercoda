#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

NS="storage-lab"
SC="demo-slow"
PV="demo-pv"
PVC="demo-claim"

# Create namespace for the PVC
if ! kubectl get ns "$NS" >/dev/null 2>&1; then
  kubectl create namespace "$NS"
fi

# Ensure StorageClass exists AND uses Immediate binding (so PVC binds without a consumer Pod)
create_sc_immediate() {
cat <<'EOF' | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: demo-slow
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: Immediate
EOF
}

if ! kubectl get sc "$SC" >/dev/null 2>&1; then
  echo "Creating StorageClass '$SC' (Immediate binding)..."
  create_sc_immediate
else
  MODE=$(kubectl get sc "$SC" -o jsonpath='{.volumeBindingMode}')
  if [[ "${MODE,,}" != "immediate" ]]; then
    echo "StorageClass '$SC' exists with volumeBindingMode='$MODE'. Recreating with Immediate..."
    kubectl delete sc "$SC"
    create_sc_immediate
  else
    echo "StorageClass '$SC' already set to Immediate."
  fi
fi

# Create a simple PersistentVolume that matches the StorageClass and PVC
if ! kubectl get pv "$PV" >/dev/null 2>&1; then
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${PV}
spec:
  capacity:
    storage: 5Mi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ${SC}
  hostPath:
    path: "/mnt/data/${PV}"
EOF
else
  echo "PV '${PV}' already exists."
fi

# Create (or re-create) the PVC to ensure binding happens with the Immediate SC
if kubectl -n "$NS" get pvc "$PVC" >/dev/null 2>&1; then
  PHASE=$(kubectl -n "$NS" get pvc "$PVC" -o jsonpath='{.status.phase}')
  if [[ "$PHASE" != "Bound" ]]; then
    echo "Recreating PVC '$PVC' to trigger binding..."
    kubectl -n "$NS" delete pvc "$PVC"
  fi
fi

if ! kubectl -n "$NS" get pvc "$PVC" >/dev/null 2>&1; then
cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${PVC}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Mi
  storageClassName: ${SC}
EOF
fi

# Wait for PVC to become Bound
echo "Waiting for PVC '${PVC}' to be Bound..."
kubectl -n "$NS" wait --for=jsonpath='{.status.phase}'=Bound pvc/"$PVC" --timeout=60s || {
  echo "PVC did not bind within 60s. Current status:"
  kubectl -n "$NS" get pvc "$PVC" -o wide
  kubectl get pv "$PV" -o wide
  exit 1
}

echo "Setup complete! Namespace, StorageClass (Immediate), PV, and Bound PVC are ready."
