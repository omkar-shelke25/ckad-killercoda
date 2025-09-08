# 🔧 CKAD: Create Sidecar Container for Logging

The Tech Lead of Mercury2D decided it's time for more logging, to finally fight all these missing data incidents. There is an existing container named `cleaner-con` in Deployment `cleaner` in Namespace `mercury`. This container mounts a volume and writes logs to a file called `cleaner.log`.

The yaml for the existing Deployment is available at **`/opt/course/16/cleaner.yaml`**. Persist your changes at **`/opt/course/16/cleaner-new.yaml`** but also make sure the Deployment is running.

## 🎯 Task

Create a sidecar container named **`logger-con`**, image **`busybox:1.31.0`**, which mounts the same volume and writes the content of `cleaner.log` to stdout. You can use the `tail -f` command for this. This way it can be picked up by `kubectl logs`.

Check if the logs of the new container reveal something about the missing data incidents.

> **Note:** Use `kubectl replace -f <file-name> --force` to replace the existing deployment

---

## 💡 Complete Solution

<details>
<summary>📝 Click to view full YAML solution</summary>

Edit `/opt/course/16/cleaner-new.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cleaner
  namespace: mercury
  labels:
    app: cleaner
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
      containers:
      - name: cleaner-con
        image: busybox:1.31.0
        command: ['sh', '-c', 'while true; do echo "$(date): cleaning data" >> /tmp/cleaner.log; sleep 10; done']
        volumeMounts:
        - name: logs
          mountPath: /tmp
      - name: logger-con
        image: busybox:1.31.0
        command: ['sh', '-c', 'tail -f /tmp/cleaner.log']
        volumeMounts:
        - name: logs
          mountPath: /tmp
      volumes:
      - name: logs
        emptyDir: {}
```

**Test Commands:**
```bash
# Apply the changes
kubectl replace -f /opt/course/16/cleaner-new.yaml --force

# Wait for the pod to be ready
kubectl wait --for=condition=Ready pod -l app=cleaner -n mercury --timeout=60s

# Check logs from the sidecar container
kubectl logs -n mercury deployment/cleaner -c logger-con

# Follow logs in real-time
kubectl logs -n mercury deployment/cleaner -c logger-con -f

## 🔍 Key Concepts

- **Sidecar Pattern**: A secondary container that extends/enhances the main container
- **Shared Volumes**: Both containers mount the same volume to share data
- **Container Logs**: Use `kubectl logs -c <container-name>` for multi-container pods
- **Log Processing**: Sidecar processes logs and outputs to stdout for centralized logging
```

</details>



