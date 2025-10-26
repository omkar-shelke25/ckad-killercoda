# CKAD: Kubernetes Job — Parallelism & Completions

Team **Neptune** needs a **Job** template located at `/opt/course/3/job.yaml`.

Requirements:
- The **Job** should:
  - Use image `public.ecr.aws/docker/library/busybox:stable`
  - Execute the command: `sleep 2 && echo done`
- Namespace: `neptune`
- Name: `neb-new-job`
- Container name: `neb-new-job-container`
- The Job should run **`3` completions** and allow **`2` runs in parallel**
- Each Pod created should have a label: `id=awesome-job`
- *Job* template located at `/opt/course/3/job.yaml`

<details> <summary>✅ Solution</summary>

# Step 1: Create the YAML file
cat <<EOF > /opt/course/3/job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: neb-new-job
  namespace: neptune
spec:
  parallelism: 2              # Two pods can run at the same time
  completions: 3              # Total of three successful pod completions needed
  template:
    metadata:
      labels:
        id: awesome-job       # Label added to identify pods
    spec:
      containers:
      - name: neb-new-job-container
        image: public.ecr.aws/docker/library/busybox:stable
        command: ["sh", "-c", "sleep 2 && echo done"]
      restartPolicy: Never     # Pods will not restart after completion or failure
EOF

Apply and verify:

```bash
# Display manifest for confirmation
cat /opt/course/3/job.yaml

# Apply the Job
kubectl apply -f /opt/course/3/job.yaml

# Check Job status
kubectl -n neptune get jobs

# Describe Job for details
kubectl -n neptune describe job neb-new-job

# check pod with complete status
kubectl get po -n neptune

# check logs of pod --> pod name will be diffrent in your case
kubectl  logs -n neptune neb-new-job-92f7j 
```

</details>



