## CKAD: Use a TLS Secret as a Volume in a Pod (namespace: security)


## 📚 **Official Kubernetes Documentation**:

- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [TLS Secrets](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)
- [Create a Secret from Files](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#create-a-secret)
- [Using Secrets as Files](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-files-from-a-pod)
- [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)
- [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)

---

## Objective
Create a **TLS Secret** (`kubernetes.io/tls`) and mount it into a Pod at `/etc/tls`.

## Requirements
- Namespace: **security**
- Secret: **tls-secret**
  - `tls.crt` → use file `task4.crt`
  - `tls.key` → use file `task4.key`
- Pod: **secure-pod** using image **redis:8.0.2**
- Mount the Secret at **`/etc/tls`**
- Verify `tls.crt` and `tls.key` are present inside the container

---

## Try it yourself first!

✅ Solution (expand to view)
<details><summary>Solution</summary>
  
```bash
# 1) Create TLS Secret
kubectl -n security create secret tls tls-secret \
  --key ./task4.key \
  --cert ./task4.crt

# 2) Create Pod
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: security
spec:
  containers:
  - name: secure-pod
    image: redis:8.0.2
    volumeMounts:
    - name: secret-vol
      mountPath: /etc/tls
      readOnly: true
  volumes:
  - name: secret-vol
    secret:
      secretName: tls-secret
EOF

# 3) Verify
kubectl -n security wait --for=condition=Ready pod/secure-pod --timeout=90s
kubectl -n security exec secure-pod -- ls -l /etc/tls
kubectl -n security exec secure-pod -- sh -c 'ls -l /etc/tls/tls.*'
```
</details>
