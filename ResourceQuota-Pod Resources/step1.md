# Task (Weightage: 6%)

Do the following:

1. Create a namespace **production-apps**.
2. In **production-apps**, create a **ResourceQuota** named **app-quota** with:
   - `pods: "4"`
   - `requests.cpu: "2000m"`
   - `requests.memory: "4Gi"`
   - `limits.cpu: "4000m"`
   - `limits.memory: "8Gi"`
3. Create a Deployment **web-server** (namespace **production-apps**) with **3 replicas** using the **nginx** image.
4. Configure each container with:
   - requests: `cpu: 200m`, `memory: 256Mi`
   - limits: `cpu: 500m`, `memory: 512Mi`
5. Verify the ResourceQuota is enforced and all 3 pods are running successfully.

---

## Hints (optional)
```bash

kubectl create namespace production-apps

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
