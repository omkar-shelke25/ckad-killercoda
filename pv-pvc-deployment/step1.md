# CKAD: PV, PVC, and Deployment

1. Create a PersistentVolume called **earth-project-earthflower-pv** that has a capacity of 2Gi, access mode ReadWriteOnce, and hostPath `/Volumes/Data`.It must not have a storageClassName.  

2. In the namespace **earth**, create a PersistentVolumeClaim called **earth-project-earthflower-pvc** that requests 2Gi of storage, access mode ReadWriteOnce, and does not specify a storageClassName. Ensure the PVC is bound to the PV.  

3. In the namespace **earth**, create a Deployment called **project-earthflower** that uses the image `httpd:2.4.41-alpine`. The Deployment’s Pods must mount the PVC **earth-project-earthflower-pvc** at `/tmp/project-data`.
