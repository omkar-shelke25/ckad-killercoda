# CronJob Challenge

## 🔹 Question (Weightage: 4)

In the `batch` namespace, create a **CronJob** named `task-cron` with the following requirements:

* Schedule: run every 5 minutes
* Image: `busybox`
* Command:

  ```bash
  /bin/sh -c "echo Processing && sleep 30"
  ```
* The Job should **fail if it runs longer than 40 seconds**
* Limit retries to **2** before the Job is marked as failed
* Each Job run must complete **4 successful Pods**
* At most **2 Pods** should run in parallel
* Completed Jobs should be **automatically deleted 120 seconds** after finishing

---

## ✅ Solution

Try solving it yourself first. If needed, expand below:

<details>
<summary>Click to view Solution</summary>

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: task-cron
  namespace: batch
spec:
  schedule: "*/5 * * * *"
  jobTemplate:
    spec:
      backoffLimit: 2
      completions: 4
      parallelism: 2
      ttlSecondsAfterFinished: 120
      activeDeadlineSeconds: 40
      template:
        spec:
          containers:
          - name: task
            image: busybox
            command: ["/bin/sh", "-c", "echo Processing && sleep 30"]
          restartPolicy: Never
```

</details>

---
