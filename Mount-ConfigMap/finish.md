# ✅ Completed

You provided configuration **as files** via ConfigMap and mounted it correctly for the workload to start:

- Keys: `APP_MODE=production`, `APP_PORT=8080`
- Deployment: `web-app` (2 replicas), image `nginx`
- Mount: `/etc/appconfig` (file-per-key)

**Exam tip:** When a prompt hints “reads from files / not env”, think **ConfigMap volume**. Verify with `ls` + `cat` inside a Pod.
