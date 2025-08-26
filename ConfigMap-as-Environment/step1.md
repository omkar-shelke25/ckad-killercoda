# ConfigMap → Environment Variables (default namespace)

## Objective
Create a **ConfigMap** and expose its keys as **environment variables** in a Pod (running in the **default** namespace).

## Requirements
- ConfigMap `app-config` with:
  - `APP_MODE: production`
  - `APP_VERSION: 1.0`
- create Pod `app-pod` using image `nginx:1.29.0`
- Inject the ConfigMap keys as env vars:
  - `APP_MODE` → `APP_MODE`
  - `APP_VERSION` → `APP_VERSION`
- Verify via a shell in the Pod that variables are set.

---

## Try it yourself first!


✅ Solution (expand to view)
<details><summary>Full commands</summary>

```bash
# 1) Create ConfigMap (default namespace)
kubectl create cm app-config \
  --from-literal APP_MODE=production \
  --from-literal APP_VERSION=1.0

# 2) Create Pod from inline YAML
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app-pod
    image: nginx:1.29.0
    envFrom:
    - configMapRef:
        name: app-config
EOF

# 3) Verify env values inside the running container
kubectl wait --for=condition=Ready pod/app-pod --timeout=60s
kubectl exec app-pod -- sh -c 'echo APP_MODE=$APP_MODE; echo APP_VERSION=$APP_VERSION'

```
</details>
