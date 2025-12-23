## CKAD: Mount ConfigMap as Files into an NGINX Pod (default namespace)

### 📚 **Official Kubernetes Documentation**:

- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Create ConfigMap from Literal Values](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#create-a-configmap)
- [Using ConfigMaps as Files](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#add-configmap-data-to-a-volume)
- [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)

---

## Requirements
1. Create `ConfigMap` **`html-config`** with keys and contents:
   - `index.html`: `<h1>Welcome to Kubernetes</h1>`
   - `error.html`: `<h1>Error Page</h1>`
2. Create Pod **`web-pod`** using image **`nginx:1.29.0`**.
3. Mount the ConfigMap as a volume at **`/usr/share/nginx/html`**.
4. Verify that **`index.html`** and **`error.html`** exist in the container at that path (and contain the expected text).

---

## Try it yourself first!

✅ Solution (expand to view)
<details><summary>Solution</summary>

```bash

# 1) ConfigMap
kubectl create cm html-config \
  --from-literal=index.html='<h1>Welcome to Kubernetes</h1>' \
  --from-literal=error.html='<h1>Error Page</h1>'

# 2) Pod (inline YAML)
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: web-pod
spec:
  containers:
  - name: web-pod
    image: nginx:1.29.0
    volumeMounts:
    - name: conf-vol
      mountPath: /usr/share/nginx/html
  volumes:
  - name: conf-vol
    configMap:
      name: html-config
EOF

# 3) Verify
kubectl wait --for=condition=Ready pod/web-pod --timeout=60s
kubectl exec web-pod -- ls /usr/share/nginx/html
kubectl exec web-pod -- sh -c 'cat /usr/share/nginx/html/index.html && echo && cat /usr/share/nginx/html/error.html'

```
</details>


