## CKAD: Mount Config Files & Gate Readiness


### 📚 **Official Kubernetes Documentation**:

- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Using ConfigMaps as Files](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#add-configmap-data-to-a-volume)
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Container Probes](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes)
- [Readiness Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Exec Probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-command)

---

Create a ConfigMap named `app-config` in the `apps` namespace with the following data:
- **APP_MODE=production**  
- **APP_PORT=8080**

Verify the ConfigMap contains the exact values before proceeding.

Create a deployment named `app-workload` in the `apps` namespace with 2 replicas using `nginx` image.

Mount this ConfigMap to the deployment at `/etc/appconfig` so that each key becomes a separate file.

Add a readiness probe to the container that runs the following command to check exact values of ConfigMap:

```
grep -qx "production" /etc/appconfig/APP_MODE && grep -qx "8080" /etc/appconfig/APP_PORT
```

Ensure the deployment is running successfully with all pods ready.


## Try it yourself first!

<details><summary>Imperative</summary>
  
```bash
# ConfigMap with exact file contents
kubectl -n apps create configmap app-config \
  --from-literal=APP_MODE=production \
  --from-literal=APP_PORT=8080

kubectl -n apps create deployment app-workload \
  --image=nginx:stable \
  --replicas=2 \
  --dry-run=client -o yaml > app-deploy.yaml

#Then edit app-deploy.yaml to add:
#The volumeMounts for /etc/appconfig
#The volumes section referencing ConfigMap: app-config
#The readinessProbe exec checking file contents

```
</details>



<details><summary>Deployment YAML (recommended)</summary>
  
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: apps
data:
  APP_MODE: "production"
  APP_PORT: "8080"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-workload
  namespace: apps
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app-workload
  template:
    metadata:
      labels:
        app: app-workload
    spec:
      containers:
      - name: nginx
        image: nginx:stable
        volumeMounts:
        - name: config
          mountPath: /etc/appconfig
          readOnly: true
        readinessProbe:
          exec:
            command:
              - /bin/sh
              - -c
              - >
                grep -qx "production" /etc/appconfig/APP_MODE
                && grep -qx "8080" /etc/appconfig/APP_PORT
          initialDelaySeconds: 2
          periodSeconds: 5
      volumes:
      - name: config
        configMap:
          name: app-config

```
</details>
