# CKAD: ResourceQuota + Pod Resources (Weightage: 6%)

### Reference Docs
- [Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
- [Managing Resources for Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

---

## Task

1. Create a namespace named **`production-apps`**.

2. In `production-apps`, create a **ResourceQuota** named **`app-quota`** with:
   - `pods: "4"`
   - `requests.cpu: "2000m"`
   - `requests.memory: "4Gi"`
   - `limits.cpu: "4000m"`
   - `limits.memory: "8Gi"`

3. Create a Deployment named **`web-server`** in `production-apps` with:
   - **3 replicas**
   - the **`nginx`** image
   - Pod template label **`app: web-server`** (the verifier selects pods using this label — it must match exactly)

4. Configure the container's resources:
   - requests: `cpu: 200m`, `memory: 256Mi`
   - limits: `cpu: 500m`, `memory: 512Mi`

5. Confirm all 3 pods come up `Running` and `Ready`, and that the ResourceQuota's `status.used` reflects them.

---

## Solution

Try it yourself first, then check the solution if needed:

<details>
<summary>Click to view Solution</summary>

### Step 1: Create the namespace

```bash
kubectl create namespace production-apps
```

### Step 2: Create the ResourceQuota

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: app-quota
  namespace: production-apps
spec:
  hard:
    pods: "4"
    requests.cpu: "2000m"
    requests.memory: "4Gi"
    limits.cpu: "4000m"
    limits.memory: "8Gi"
EOF
```

### Step 3: Create the Deployment

> The Pod template label must be `app: web-server` — the verifier looks up pods with `kubectl get pods -l app=web-server`. Using a different label (e.g. `app: nginx`) will cause verification to find zero pods even if the Deployment itself is correct.

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-server
  namespace: production-apps
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-server
  template:
    metadata:
      labels:
        app: web-server
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        resources:
          requests:
            cpu: "200m"
            memory: "256Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
EOF
```

> **Note:** `selector.matchLabels` and `template.metadata.labels` must match — this is a hard Kubernetes requirement for Deployments, not just a verification preference. If they don't match, the Deployment will be rejected by the API server.

### Step 4: Confirm it's all running within quota

```bash
kubectl -n production-apps get pods
kubectl -n production-apps describe resourcequota app-quota
```

You should see 3 pods `Running`/`Ready`, and the quota's `Used` column showing `600m` CPU requests (3 × 200m) and `3` pods used out of the `4` allowed.

</details>
