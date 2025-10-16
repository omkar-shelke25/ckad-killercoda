# CKAD: Automating Backups with CronJob

The finance team needs to automate their database backup process using a **Kubernetes CronJob** in the `payment` namespace.  

### Part 1: CronJob Requirements
- Name: **`db-backup`**  
- Schedule: **Every 10 minutes**
- Container Image: **`busybox`**  
- Command: print the current date and the message **"`Starting backup`"**  
- Restart Policy: **`OnFailure`**  
- Retain **3 successful job histories** 
- Retain **1 failed job history**
- Allow missed jobs to start within **`100` seconds**

---

### Part 2: Manual Job Trigger
After creating the CronJob, immediately trigger a **manual one-time backup Job** based on it.  
- Name this Job: **`manual-db-backup`**  
- It must run in the same **`payment`** namespace.  

---

## Try it yourself first!

<details><summary>✅ Solution (expand to view)</summary>
  
#### Create the CronJob
```bash
kubectl create cronjob db-backup \
  --image=busybox \
  --schedule="*/10 * * * *" \
  -n payment \
  --dry-run=client -oyaml \
  -- /bin/sh -c "date; echo Starting backup" > 1.yaml
```

#### add extra spec fields not supported by kubectl create cronjob  
```yaml
#update yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: db-backup
  namespace: payment
spec:
  schedule: "*/10 * * * *"
  startingDeadlineSeconds: 100
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: backup
            image: busybox
            command:
            - /bin/sh
            - -c
            - |
              date
              echo "Starting backup"
```

#### Create a manual one-time Job from the CronJob
```bash
kubectl create job manual-db-backup --from=cronjob/db-backup -n payment
```
</details>

