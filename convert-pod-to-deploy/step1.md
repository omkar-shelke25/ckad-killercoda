# CKAD: Convert Pod → Deployment (namespace: pluto)

### 📚 Reference Docs

- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
- [Configure Service Accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)

---
In namespace **`pluto`** there is a single Pod named **`holy-api`**. It has been working fine, but Team Pluto needs it to be more reliable.

Your tasks:

1. Convert the Pod into a **Deployment** named **`holy-api`** with **3 replicas**.
2. Add a **container-level** `securityContext` with:
   - `allowPrivilegeEscalation: false`
   - `privileged: false`
3. **Delete** the original Pod after creating the Deployment.
4. Save the Deployment manifest to **`/opt/course/9/holy-api-deployment.yaml`**.

The raw Pod template is already available at **`/opt/course/9/holy-api-pod.yaml`** — use it as your starting point.

---

## ✅ Verify Your Work

```bash
kubectl get deploy holy-api -n pluto
kubectl get pods -n pluto
kubectl rollout status deploy/holy-api -n pluto
```

---

<details>
<summary>💡 Solution (try it yourself first!)</summary>

**Step 1 — View the existing Pod template**

```bash
cat /opt/course/9/holy-api-pod.yaml
```

**Step 2 — Create the Deployment manifest**

Save the following to `/opt/course/9/holy-api-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: holy-api
  namespace: pluto
  labels:
    app: holy-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: holy-api
  template:
    metadata:
      labels:
        app: holy-api
    spec:
      containers:
      - name: app
        image: busybox:latest
        command: ["/bin/sh", "-c", "sleep 1d"]
        securityContext:
          allowPrivilegeEscalation: false
          privileged: false
```

**Step 3 — Apply, delete the old Pod, and verify**

```bash
kubectl apply -f /opt/course/9/holy-api-deployment.yaml
kubectl delete pod holy-api -n pluto
kubectl rollout status deploy/holy-api -n pluto
kubectl get pods -n pluto
```

</details>
