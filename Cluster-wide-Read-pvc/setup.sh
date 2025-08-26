#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

# Create a demo namespace
kubectl get ns storage-lab >/dev/null 2>&1 || kubectl create namespace storage-lab

# Create a demo StorageClass (no dynamic provisioning; just for RBAC list/get)
if ! kubectl get sc demo-slow >/dev/null 2>&1; then
cat <<'EOF' | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: demo-slow
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF
fi

# Create a demo PersistentVolume
if ! kubectl get pv demo-pv >/dev/null 2>&1; then
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: demo-pv
spec:
  capacity:
    storage: 5Mi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: demo-slow
  hostPath:
    path: "/mnt/data/demo-pv"
EOF
fi

# Create a demo PVC (should bind to demo-pv)
if ! kubectl -n storage-lab get pvc demo-claim >/dev/null 2>&1; then
cat <<'EOF' | kubectl apply -n storage-lab -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: demo-claim
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Mi
  storageClassName: demo-slow
EOF
fi

echo "Setup complete! StorageClass, PV, and PVC are ready."
