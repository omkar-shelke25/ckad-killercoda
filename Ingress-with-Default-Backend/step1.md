# Configure an Ingress with a Default Backend (Catch-all)

## Real-life scenario
Product wants **`main.example.com`** to serve the main site, but any **unknown host/path** should render the custom error page (friendly 404). You’ll configure one Ingress to route the known host to **`main-site-svc`** and **everything else** to **`error-page-svc`** as a **default backend**.

## Requirements
- Namespace: **main**
- Create an Ingress **`site-ingress`**
- Use **`ingressClassName: nginx`**
- Add annotation: `nginx.ingress.kubernetes.io/rewrite-target: "/"`
- Rule: **host** `main.example.com` → **`main-site-svc:80`**
- **Default backend** (catch-all): **`error-page-svc:80`**

> You don’t need a running ingress controller for this verification; we validate the **Ingress spec**.

---

## Try it yourself first!
  
<details><summary>✅ Solution (expand to view)</summary>
  
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
