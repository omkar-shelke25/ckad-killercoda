# CKAD: Automating Backups with CronJob

The finance team needs to automate their database backup process using a **Kubernetes CronJob** in the `payment` namespace.  

### Part 1: CronJob Requirements
- Name: **db-backup**  
- Schedule: **Every 10 minutes** (`*/10 * * * *`)  
- Container Image: **busybox**  
- Command: print the current date and the message **"Starting backup"**  
- Restart Policy: **OnFailure**  
- Retain **3 successful job histories** (`successfulJobsHistoryLimit: 3`)  
- Retain **1 failed job history** (`failedJobsHistoryLimit: 1`)  
- Allow missed jobs to start within **100 seconds** (`startingDeadlineSeconds: 100`)  

---

### Part 2: Manual Job Trigger
After creating the CronJob, immediately trigger a **manual one-time backup Job** based on it.  
- Name this Job: **manual-db-backup**  
- It must run in the same `payment` namespace.  

---
