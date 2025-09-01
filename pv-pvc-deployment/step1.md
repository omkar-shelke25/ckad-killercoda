# CKAD: PV, PVC, and Deployment

1. Create a PersistentVolume called **earth-project-earthflower-pv** that has a capacity of 2Gi, access mode ReadWriteOnce, and hostPath `/Volumes/Data`.It must not have a storageClassName.  

2. In the namespace **earth**, create a PersistentVolumeClaim called **earth-project-earthflower-pvc** that requests 2Gi of storage, access mode ReadWriteOnce, and does not specify a storageClassName. Ensure the PVC is bound to the PV.  

3. In the namespace **earth**, create a Deployment called **project-earthflower** that uses the image `httpd:2.4.41-alpine`. The Deployment’s Pods must mount the PVC **earth-project-earthflower-pvc** at `/tmp/project-data`.



## Try it yourself first!

<details><summary> ✅ Solution (expand to view)</summary>

```bash
# Create PersistentVolume
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: earth-project-earthflower-pv
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/Volumes/Data"
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""   # ensures no storageClassName
EOF

# Create PersistentVolumeClaim
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: earth-project-earthflower-pvc
  namespace: earth
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: ""   # ensures no storageClassName
EOF

# Create Deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: project-earthflower
  namespace: earth
spec:
  replicas: 1
  selector:
    matchLabels:
      app: project-earthflower
  template:
    metadata:
      labels:
        app: project-earthflower
    spec:
      containers:
      - name: web
        image: httpd:2.4.41-alpine
        volumeMounts:
        - name: project-storage
          mountPath: /tmp/project-data
      volumes:
      - name: project-storage
        persistentVolumeClaim:
          claimName: earth-project-earthflower-pvc
EOF


```
