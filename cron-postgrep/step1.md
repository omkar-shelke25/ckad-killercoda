# CKAD: CronJob for Database Backup

Your company runs a **PostgreSQL database** in the `production` namespace.  
The SRE team wants **automated daily backups** to ensure business continuity.  

Create a **CronJob** named **`database-backup`** in the `production` namespace that:  

- Runs **every day at 3:00 AM**, the off-peak backup window.  
- Uses the image **`postgres:13-alpine`**.  
- Simulates a backup by running:
  
  ```bash
    /bin/bash -c echo 'Starting DB backup...' && sleep 10 && echo "Backup complete at $(date)"
  ```
  
- Ensures no overlapping backups (concurrencyPolicy: Forbid).
- If a job is missed, it must be started within 2 minutes of the schedule (startingDeadlineSeconds: 120).
- Backup pods must never restart (restartPolicy: Never).
- Keep only the last 3 successful runs and 1 failed run in history.

## Try it yourself first!

<details><summary>✅ Solution (expand to view)</summary>


```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: database-backup
  namespace: production
spec:
  schedule: "0 3 * * *"
  concurrencyPolicy: Forbid
  startingDeadlineSeconds: 120
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
          - name: db-backup
            image: postgres:13-alpine
            command:
            - /bin/bash
            - -c
            - |
              echo 'Starting DB backup...' && sleep 10 && echo "Backup complete at $(date)"
```

</details>
