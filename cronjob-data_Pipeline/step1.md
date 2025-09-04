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

  
