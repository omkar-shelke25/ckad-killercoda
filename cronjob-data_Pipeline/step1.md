# 🛠️ CKAD: Real-Life Data Pipeline CronJob

You are working in the **batch** namespace. The data engineering team needs a recurring **CronJob** that simulates their ETL (extract–transform–load) pipeline. The CronJob must be resilient, non-overlapping, and keep only minimal job history for observability.

Create the CronJob according to the following requirements:

---

### 1. CronJob Spec
- Name: **data-pipeline**  
- Schedule: **every 10 minutes** (`*/10 * * * *`)  
- Concurrency policy: **Forbid** (no overlapping jobs should run)  
- History limits: keep only the **last 2 successful jobs** and **1 failed job**

---

### 2. Job Template (`.spec.jobTemplate`)
- Retry limit: **3 attempts** (`backoffLimit: 3`)  
- Each job must complete **2 Pods successfully** (`completions: 2`)  
- At most **1 Pod** should run at a time (`parallelism: 1`)  
- Jobs must be **deleted 90 seconds** after finishing (`ttlSecondsAfterFinished: 90`)  
- Jobs should fail if they run longer than **50 seconds** (`activeDeadlineSeconds: 50`)

---

### 3. Pod Template (`.spec.jobTemplate.template.spec`)
- Container image: **busybox**  
- Pods must not restart once completed (restartPolicy: Never)
- Command:
  ```bash
  /bin/sh -c "echo Running Data Job && sleep 40"
  ```


## Try to solve this yourself first!

<details>
<summary>✅ Solution (expand to view)</summary>
  
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: data-pipeline
  namespace: batch
spec:
  schedule: "*/10 * * * *"            # runs every 10 minutes
  concurrencyPolicy: Forbid           # prevent overlapping jobs
  successfulJobsHistoryLimit: 2       # keep 2 successful job records
  failedJobsHistoryLimit: 1           # keep 1 failed job record
  jobTemplate:
    spec:
      backoffLimit: 3                 # max retries for failed pods
      completions: 2                  # 2 pods must complete
      parallelism: 1                  # 1 pod at a time
      ttlSecondsAfterFinished: 90     # auto-delete after 90s
      activeDeadlineSeconds: 50       # fail if runs >50s
      template:
        spec:
          restartPolicy: Never        # don't restart failed containers
          containers:
          - name: runner
            image: busybox
            command:
            - /bin/sh
            - -c
            - echo Running Data Job && sleep 40
```
 </details> 
