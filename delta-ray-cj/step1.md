
## 📚 Documentation Links

- [CronJobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
- [Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job/)


## 🧩 CKAD — "Delta-Ray Diagnostic CronJob" 🚀


Create a CronJob named **`delta-ray`** in the **`delta`** namespace using the image **`public.ecr.aws/docker/library/busybox:stable`**.

The CronJob should run every **`45` minutes** and must retain the last **`33` successful jobs** and **`19` failed jobs** in its history.

Each job created by this CronJob should automatically terminate if it runs longer than **`50`seconds**.

And the pod inside the job should have its restart policy set to **`Never`**.

Use the following command in the container to simulate the Delta-Ray diagnostic sequence:

```
command: ["/bin/sh", "-c", "echo '🛰️ Initiating Delta-Ray Diagnostic...'; for i in $(seq 1 5); do echo '🔭 Cycle '$i'/5 — Scanning cosmic field...'; date; sleep 5; done; echo '💾 Telemetry uplink complete — ✅ Mission success ✨'"]
```{{copy}}


After creating the CronJob, create a separate Job named **`manual-delta-ray`** in the same namespace using the same configuration as the CronJob to perform manual testing.

Ensure that the **manual job** runs successfully and displays the expected diagnostic messages from the command output.


---

# 🧠 Try it yourself first!

<details><summary>✅ Solution For Your Reference</summary>

Cron expressions use the format: `minute hour day month weekday`

For "every 45 minutes": `*/45 * * * *`

- `*/45` = every 45 minutes
- `*` = every hour
- `*` = every day
- `*` = every month
- `*` = every weekday


Important fields to configure:
- `spec.schedule` - cron expression
- `spec.successfulJobsHistoryLimit` - number of successful jobs to keep
- `spec.failedJobsHistoryLimit` - number of failed jobs to keep
- `spec.jobTemplate.spec.activeDeadlineSeconds` - job timeout
- `spec.jobTemplate.spec.template.spec.restartPolicy` - pod restart policy


**Using kubectl create command**

```bash
# Create CronJob (then edit to add history limits)
kubectl create cronjob delta-ray \
  --image=public.ecr.aws/docker/library/busybox:stable \
  --schedule="*/45 * * * *" \
  -n delta \
  -- /bin/sh -c "echo '🛰️ Initiating Delta-Ray Diagnostic...'; for i in \$(seq 1 5); do echo '🔭 Cycle '\$i'/5 — Scanning cosmic field...'; date; sleep 5; done; echo '💾 Telemetry uplink complete — ✅ Mission success ✨'"

# Edit to add history limits and activeDeadlineSeconds
kubectl edit cronjob delta-ray -n delta
# Add:
#   successfulJobsHistoryLimit: 33
#   failedJobsHistoryLimit: 19
#   jobTemplate.spec.activeDeadlineSeconds: 50
#   jobTemplate.spec.template.spec.restartPolicy: Never

# Create manual job from cronjob
kubectl create job manual-delta-ray \
  --from=cronjob/delta-ray \
  -n delta
```

</details>

