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
   - the **`nginx:alpine`** image
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
  name: app-quota              # name the verifier looks for
  namespace: production-apps
spec:
  hard:
    pods: "4"                  # max 4 pods total in this namespace
    requests.cpu: "2000m"      # sum of all pod CPU requests can't exceed 2 cores
    requests.memory: "4Gi"     # sum of all pod memory requests can't exceed 4Gi
    limits.cpu: "4000m"        # sum of all pod CPU limits can't exceed 4 cores
    limits.memory: "8Gi"       # sum of all pod memory limits can't exceed 8Gi
EOF
```

### Step 3: Create the Deployment

> The Pod template label must be `app: web-server` — the verifier looks up pods with `kubectl get pods -l app=web-server`. Using a different label (e.g. `app: nginx`) will cause verification to find zero pods even if the Deployment itself is correct.

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-server                 # name the verifier looks for
  namespace: production-apps
spec:
  replicas: 3                      # must match exactly — quota allows up to 4
  selector:
    matchLabels:
      app: web-server              # must match template.metadata.labels below
  template:
    metadata:
      labels:
        app: web-server            # verifier finds pods using this label
    spec:
      containers:
      - name: nginx
        image: nginx:alpine        # smaller image, faster pull, same nginx
        resources:
          requests:                # what the scheduler reserves per pod
            cpu: "200m"
            memory: "256Mi"
          limits:                  # hard cap enforced by the kubelet
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
