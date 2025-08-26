# Use multiple ConfigMaps and a Secret as environment variables (namespace: `api`)

## Requirements
- Namespace: **api**
- ConfigMaps:
  - **frontend-config**: `TITLE=Frontend`
  - **backend-config**: `ENDPOINT=http://backend.local`
- Secret:
  - **api-secret**: `API_KEY=12345`
- Pod:
  - **complex-pod** using image **nginx:1.29.0**
  - Inject env vars from:
    - `frontend-config` → env `TITLE`
    - `backend-config` → env `ENDPOINT`
    - `api-secret` → env `API_KEY`
- Verify that the Pod’s environment has the expected values.
- Bonus: Use **`/opt/env.sh`** to quickly print the values.

---

<details><summary>✅ Solution (expand to view)</summary>
  
```bash
# ConfigMaps
kubectl -n api create cm frontend-config --from-literal TITLE=Frontend
kubectl -n api create cm backend-config  --from-literal ENDPOINT='http://backend.local'

# Secret
kubectl -n api create secret generic api-secret --from-literal API_KEY=12345

# Pod
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: complex-pod
  namespace: api
spec:
  containers:
  - name: complex-pod
    image: nginx:1.29.0
    envFrom:
    - configMapRef:
        name: frontend-config
    - configMapRef:
        name: backend-config
    - secretRef:
        name: api-secret
EOF

# Verify
kubectl -n api wait --for=condition=Ready pod/complex-pod --timeout=90s
kubectl -n api exec complex-pod -- env | egrep '^(TITLE|ENDPOINT|API_KEY)='

```
</details> 
