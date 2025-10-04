# CKAD: Create Sidecar Container for Logging (Weightage: 6%)

## 📋 Background

The Tech Lead of Mercury2D decided it's time for more logging, to finally fight all these missing data incidents. There is an existing container named `cleaner-con` in Deployment `cleaner` in Namespace `mercury`. This container mounts a volume and writes logs to a file called `cleaner.log`.

The yaml for the existing Deployment is available at `/opt/course/16/cleaner.yaml`.

## 🎯 Task

Do the following:

1. **Examine the existing Deployment** at `/opt/course/16/cleaner.yaml`
2. **Add a sidecar container** named `logger-con` with:
   - Image: `public.ecr.aws/docker/library/busybox:latest`
   - Mount the same volume as `cleaner-con`
   - Use `tail -f` command to stream `/var/log/cleaner.log` to stdout
   - Configure as an init container with `restartPolicy: Always` (sidecar pattern)
3. **Save your changes** to `/opt/course/16/cleaner-new.yaml`
4. **Apply the updated Deployment** to make it running
5. **Verify** the logs are accessible via `kubectl logs`
6. **Check the logs** to find information about the missing data incidents

---

<details>
<summary>📖 Solution</summary>


- In Kubernetes 1.28+, sidecar containers are init containers with `restartPolicy: Always`
- The sidecar container should mount the same volume (`logs`) at the same path (`/var/log`)
- Use `tail -f /var/log/cleaner.log` to continuously stream the log file
- Test with: `kubectl logs -n mercury deployment/cleaner -c logger-con`

```bash
# First, examine the existing deployment
cat /opt/course/16/cleaner.yaml

# Copy and modify the deployment
cp /opt/course/16/cleaner.yaml /opt/course/16/cleaner-new.yaml

# Edit the file to add the sidecar container
# You can use vim, nano, or create a new version
cat <<'EOF' > /opt/course/16/cleaner-new.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cleaner
  namespace: mercury
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cleaner
  template:
    metadata:
      labels:
        app: cleaner
    spec:
      volumes:
      - name: logs
        emptyDir: {}
      initContainers:
      - name: logger-con
        image: public.ecr.aws/docker/library/busybox:latest
        restartPolicy: Always
        volumeMounts:
        - name: logs
          mountPath: /var/log
        command: ["sh", "-c", "tail -f /var/log/cleaner.log"]
      containers:
      - name: cleaner-con
        image: public.ecr.aws/docker/library/busybox:latest
        volumeMounts:
        - name: logs
          mountPath: /var/log
        command: ["sh", "-c"]
        args:
        - |
          while true; do
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Cleaning data..." >> /var/log/cleaner.log
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Found 42 records" >> /var/log/cleaner.log
            echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: 3 records missing!" >> /var/log/cleaner.log
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Data cleanup completed" >> /var/log/cleaner.log
            sleep 10
          done
EOF

# Apply the updated deployment
kubectl apply -f /opt/course/16/cleaner-new.yaml

# Wait for the deployment to roll out
kubectl rollout status deployment/cleaner -n mercury

# Check the logs from the sidecar container
kubectl logs -n mercury deployment/cleaner -c logger-con

# You should see log entries including warnings about missing data:
# "WARNING: 3 records missing!"
```

**Key Points:**
- The `logger-con` container is defined as an `initContainer` with `restartPolicy: Always`
- This makes it a sidecar that runs alongside the main container
- Both containers share the same `logs` volume
- The sidecar uses `tail -f` to continuously stream the log file to stdout
- The logs reveal "WARNING: 3 records missing!" - the missing data incidents!

</details>
