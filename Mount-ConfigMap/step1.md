# Config as Files

🔹 Question (Weightage: 4)

A workload in the `apps` namespace must read configuration only from files at `/etc/appconfig`. The container image is `nginx`. The process considers startup successful only if both files exist with exact contents:

* `/etc/appconfig/APP_MODE` → `production`
* `/etc/appconfig/APP_PORT` → `8080`

The app image cannot be modified and does not read environment variables.
Operations require a Kubernetes-native approach (no hostPath, no baked-in files, no env vars).

Task:

In the `apps` namespace:

1. Provide configuration via a Kubernetes object so that each key is rendered as an individual file under `/etc/appconfig`.
2. Create a Deployment named `web-app` that:

   * runs 2 replicas
   * uses image `nginx`
   * mounts the configuration read-only at `/etc/appconfig`
3. Ensure Pods become Ready. (If files are missing/wrong, readiness will not be met.)

Constraints:

* Do not use env vars or `envFrom`.
* File names and contents must be exact.
* Assume namespace may not exist; create it if needed.

---

Solution (expand):
<details>
<summary>Show solution</summary>

Ensure namespace:

```
kubectl create ns apps --dry-run=client -o yaml | kubectl apply -f -
```

ConfigMap with keys:

```
kubectl -n apps create configmap app-config \
  --from-literal=APP_MODE=production \
  --from-literal=APP_PORT=8080
```

Deployment:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: apps
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: nginx
        image: nginx
        volumeMounts:
        - name: app-config-vol
          mountPath: /etc/appconfig
          readOnly: true
      volumes:
      - name: app-config-vol
        configMap:
          name: app-config
```

Quick check:

```
kubectl -n apps rollout status deploy/web-app
POD=$(kubectl -n apps get pod -l app=web-app -o jsonpath='{.items[0].metadata.name}')
kubectl -n apps exec "$POD" -- sh -c 'ls -1 /etc/appconfig && echo "---" && for f in /etc/appconfig/*; do echo "$f => $(cat "$f")"; done'
```
</details>
