# CKAD: Kubernetes Job — Parallelism & Completions

Team **Neptune** needs a **Job** template located at `/opt/course/3/job.yaml`.

Requirements:
- The **Job** should:
  - Use image `busybox:1.31.0`
  - Execute the command: `sleep 2 && echo done`
- Namespace: `neptune`
- Name: `neb-new-job`
- Container name: `neb-new-job-container`
- The Job should run **3 completions** and allow **2 runs in parallel**
- Each Pod created should have a label: `id=awesome-job`

<details> <summary>✅ Solution</summary>

```yaml
apiVersion: batch/v1        # Using batch/v1 API for Job
kind: Job                   # Resource type is Job
metadata:
  name: neb-new-job         # Job name
  namespace: neptune        # Placed in namespace 'neptune'
spec:
  parallelism: 2            # 2 Pods can run in parallel
  completions: 3            # Job should complete 3 successful runs
  template:
    metadata:
      labels:
        id: awesome-job     # Add label to Pods
    spec:
      containers:
      - name: neb-new-job-container          # Container name
        image: busybox:1.31.0                # Container image
        command: ["sh", "-c", "sleep 2 && echo done"]  # Command to run
      restartPolicy: Never   # Required for Jobs (no restart on success/failure)
````

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



