#!/bin/bash
set -euo pipefail

NS="earth"
PV="earth-project-earthflower-pv"
PVC="earth-project-earthflower-pvc"
DEP="project-earthflower"

pass(){ echo "✅ $1"; exit 0; }
fail(){ echo "❌ $1"; exit 1; }

# PV verification
kubectl get pv "$PV" >/dev/null 2>&1 || fail "PersistentVolume $PV was not found."
CAP=$(kubectl get pv "$PV" -o jsonpath='{.spec.capacity.storage}')
[[ "$CAP" == "2Gi" ]] || fail "PersistentVolume $PV must have a capacity of 2Gi (found $CAP)."
AM=$(kubectl get pv "$PV" -o jsonpath='{.spec.accessModes[0]}')
[[ "$AM" == "ReadWriteOnce" ]] || fail "PersistentVolume $PV must have access mode ReadWriteOnce (found $AM)."
HP=$(kubectl get pv "$PV" -o jsonpath='{.spec.hostPath.path}')
[[ "$HP" == "/Volumes/Data" ]] || fail "PersistentVolume $PV must use hostPath /Volumes/Data (found $HP)."
SC=$(kubectl get pv "$PV" -o jsonpath='{.spec.storageClassName}' || true)
[[ -z "$SC" ]] || fail "PersistentVolume $PV must not have a storageClassName (found $SC)."

# PVC verification
kubectl -n "$NS" get pvc "$PVC" >/dev/null 2>&1 || fail "PersistentVolumeClaim $PVC was not found in namespace $NS."
REQ=$(kubectl -n "$NS" get pvc "$PVC" -o jsonpath='{.spec.resources.requests.storage}')
[[ "$REQ" == "2Gi" ]] || fail "PersistentVolumeClaim $PVC must request 2Gi (found $REQ)."
AM_PVC=$(kubectl -n "$NS" get pvc "$PVC" -o jsonpath='{.spec.accessModes[0]}')
[[ "$AM_PVC" == "ReadWriteOnce" ]] || fail "PersistentVolumeClaim $PVC must use access mode ReadWriteOnce (found $AM_PVC)."
SC_PVC=$(kubectl -n "$NS" get pvc "$PVC" -o jsonpath='{.spec.storageClassName}' || true)
[[ -z "$SC_PVC" ]] || fail "PersistentVolumeClaim $PVC must not have a storageClassName (found $SC_PVC)."
STATUS=$(kubectl -n "$NS" get pvc "$PVC" -o jsonpath='{.status.phase}')
[[ "$STATUS" == "Bound" ]] || fail "PersistentVolumeClaim $PVC must be bound (current status: $STATUS)."

# Deployment verification
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || fail "Deployment $DEP was not found in namespace $NS."
IMG=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].image}')
[[ "$IMG" == "httpd:2.4.41-alpine" ]] || fail "Deployment $DEP must use image httpd:2.4.41-alpine (found $IMG)."
MOUNT=$(kubectl -n "$NS" get deploy "$DEP" -o json | jq -r '.spec.template.spec.containers[0].volumeMounts[0].mountPath')
[[ "$MOUNT" == "/tmp/project-data" ]] || fail "Deployment $DEP must mount the PVC at /tmp/project-data (found $MOUNT)."
VOL=$(kubectl -n "$NS" get deploy "$DEP" -o json | jq -r '.spec.template.spec.volumes[0].persistentVolumeClaim.claimName')
[[ "$VOL" == "$PVC" ]] || fail "Deployment $DEP must mount the PersistentVolumeClaim $PVC (found $VOL)."

pass "✅ All requirements satisfied: PV, PVC, and Deployment are configured correctly according to the question."
