## CKAD: Use multiple ConfigMaps and a Secret as environment variables (namespace: `api`)

### 📚 **Official Kubernetes Documentation**:

- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Using Secrets as Environment Variables](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables)
- [Using ConfigMaps as Environment Variables](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#add-configmap-data-to-a-pod)
- [Define Environment Variables for a Container](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)
- [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)

---

## Requirements
- Namespace: **api**
- ConfigMaps:
  - **frontend-config**: `TITLE=Frontend`
  - **backend-config**: `ENDPOINT=http://backend.local`
- Secret:
  - **api-secret**: `API_KEY=12345`
- Pod:
  - **complex-pod** using image **nginx:1.29.0**
  - Inject env vars as envFrom
- Verify that the Pod’s environment has the expected values.

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
