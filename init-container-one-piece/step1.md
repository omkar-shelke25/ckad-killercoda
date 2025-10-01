# CKAD: Deploy Strawhat Crew with InitContainer

In the `one-piece` namespace, deploy an Nginx application serving custom Strawhat crew HTML using ConfigMap and InitContainer.

## Your Tasks

1. **Create ConfigMap** named `strawhat-cm` from `/one-piece/index.html`
2. **Create Deployment** named `strawhat-deploy`:
   - **Replicas**: 1
   - **Container** `strawhat-nginx`: `public.ecr.aws/nginx/nginx:latest`
   - **InitContainer** `init-copy`: `public.ecr.aws/docker/library/busybox:latest`
     - Copies `index.html` from ConfigMap to `/usr/share/nginx/html/`
3. **Create Service** named `strawhat-svc`:
   - Type: **NodePort**
   - Port: **80**
   - NodePort: **32100**
4. From the terminal navigation (top right), select the item. The service should be accessible on port 32100. Verify that the `index.html` page is displayed.
 ![One Piece terminal screenshot](https://github.com/user-attachments/assets/56ec5f6a-e274-4494-8cc4-9b038073e77e)



---

<details><summary>✅ Solution (expand to view)</summary>

```bash
# 1. Create ConfigMap from file
kubectl create configmap strawhat-cm \
  --from-file=/one-piece/index.html \
  -n one-piece

# 2. Create Deployment with InitContainer
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: strawhat-deploy
  namespace: one-piece
spec:
  replicas: 1
  selector:
    matchLabels:
      app: strawhat
  template:
    metadata:
      labels:
        app: strawhat
    spec:
      initContainers:
      - name: init-copy
        image: public.ecr.aws/docker/library/busybox:latest
        command: ['sh', '-c', 'cp /config/index.html /usr/share/nginx/html/']
        volumeMounts:
        - name: config-volume
          mountPath: /config
        - name: html-volume
          mountPath: /usr/share/nginx/html
      containers:
      - name: strawhat-nginx
        image: public.ecr.aws/nginx/nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html-volume
          mountPath: /usr/share/nginx/html
      volumes:
      - name: config-volume
        configMap:
          name: strawhat-cm
      - name: html-volume
        emptyDir: {}
EOF

# 3. Create NodePort Service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: strawhat-svc
  namespace: one-piece
spec:
  type: NodePort
  selector:
    app: strawhat
  ports:
  - port: 80
    targetPort: 80
    nodePort: 32100
EOF

# 4. Wait and verify
kubectl rollout status deployment/strawhat-deploy -n one-piece
curl localhost:32100
```

</details>
