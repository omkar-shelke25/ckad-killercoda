# CKAD: Externalize Runtime Configuration (ConfigMap + Secret → Env)

### 📚 **Official Kubernetes Documentation**:

- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Using Secrets as Environment Variables](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables)
- [Using ConfigMaps as Environment Variables](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#add-configmap-data-to-a-)

---


A workload in `apps` needs a database endpoint (non‑sensitive) and a third‑party API credential (sensitive). The workload reads both **only via environment variables** at runtime.

## Task

Work only in the `apps` namespace and implement the following:

- **ConfigMap**  
  Create a ConfigMap named **`app-config`** with the key **`database.url`** set to:  
  `postgres://db.example.com:5432/production`  
  *Note: No credentials in this URL; credentials are managed separately.*

- **Secret**  
  Create a Secret named **`api-credentials`** with the key **`api.key`** set to:  
  `s3cr3t-ap1-k3y-f0r-pr0d`

- **Pod**  
  Create a Pod named **`app-pod`** using image **`busybox:1.36`** that remains running.  
  Expose the configuration as environment variables:
  - **`DATABASE_URL`** ← from ConfigMap `app-config` key **`database.url`**
  - **`API_KEY`**      ← from Secret `api-credentials` key **`api.key`**

- Do not mount files; consume **via env vars** only.

> Use sleep in the command so the container stays alive and the Pod remains Running. Example: -- sh -c "sleep 3600" (sleeps for an hour).

---

## (Optional) Reference solution

<details>
<summary>Click to view YAML</summary>

```bash
kubectl -n apps create configmap app-config \
  --from-literal=database.url='postgres://db.example.com:5432/production'
```
```bash
kubectl -n apps create secret generic api-credentials \
  --from-literal=api.key='s3cr3t-ap1-k3y-f0r-pr0d'
```
```bash
kubectl -n apps run app-pod \
  --image=busybox:1.36 \
  --command -- sh -c "tail -f /dev/null" \
  --dry-run=client -o yaml > pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
  namespace: apps
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["/bin/sh","-c","tail -f /dev/null"]
    env:
    - name: DATABASE_URL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database.url
    - name: API_KEY
      valueFrom:
        secretKeyRef:
          name: api-credentials
          key: api.key
```
</details> 
