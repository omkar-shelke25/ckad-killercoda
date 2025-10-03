# 🌌 CKAD: Warp Core Probe Systems in Galaxy Namespace

A namespace named `galaxy` already exists. A Deployment named `warp-core` is already running in this namespace. The application inside the Pods is **listening on port 80**.

Your mission is to upgrade the Deployment with **probe systems** to keep the warp core stable:

## Requirements:

1. Add a **readinessProbe** that checks HTTP path `/readyz` on the application's listening port.
   - `initialDelaySeconds: 2`
   - `periodSeconds: 5`

2. Add a **livenessProbe** that checks HTTP path `/helathz` on the application's listening port.
   - `initialDelaySeconds: 5`
   - `periodSeconds: 10`
   - `failureThreshold: 3`

3. Apply the changes and confirm the Deployment updates successfully in the `galaxy` namespace.
4. After applying your changes, check the Deployment logs to verify that Apache is running and serving traffic. Also, confirm that the `/helathz` and `/readyz` endpoints return an `HTTP 200 OK` response.


<details>
<summary>✅ Solution</summary>

**Option 1: Using kubectl edit**
```bash
kubectl -n galaxy edit deployment warp-core
```

Add the following probes under the `httpd` container section:

```yaml
        readinessProbe:
          httpGet:
            path: /readyz
            port: 80
          initialDelaySeconds: 2
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /helathz
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
          failureThreshold: 3
```

**Option 2: Using kubectl patch**
```bash
kubectl -n galaxy patch deployment warp-core --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/readinessProbe",
    "value": {
      "httpGet": {
        "path": "/readyz",
        "port": 80
      },
      "initialDelaySeconds": 2,
      "periodSeconds": 5
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/livenessProbe",
    "value": {
      "httpGet": {
        "path": "/helathz",
        "port": 80
      },
      "initialDelaySeconds": 5,
      "periodSeconds": 10,
      "failureThreshold": 3
    }
  }
]'
```

**Option 3: Complete YAML**
```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: warp-core
  namespace: galaxy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: warp-core
  template:
    metadata:
      labels:
        app: warp-core
    spec:
      containers:
      - name: httpd
        image: public.ecr.aws/docker/library/httpd:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: health-pages
          mountPath: /usr/local/apache2/htdocs
        readinessProbe:
          httpGet:
            path: /readyz
            port: 80
          initialDelaySeconds: 2
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /helathz
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
          failureThreshold: 3
      volumes:
      - name: health-pages
        configMap:
          name: warp-core-pages
EOF
```

**Verify the deployment:**
```bash
kubectl -n galaxy get deployment warp-core
kubectl -n galaxy get pods
kubectl -n galaxy describe deployment warp-core
```

</details>
