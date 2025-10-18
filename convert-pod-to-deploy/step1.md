# CKAD: Convert Pod → Deployment (namespace: pluto)

In Namespace **`pluto`** there is single Pod named holy-api. It has been working okay for a while now but Team Pluto needs it to be more reliable.

Convert the Pod into a Deployment named **`holy-api`** with **`3` replicas** &  delete the single Pod once done. The raw Pod template file is available at **`/opt/course/9/holy-api-pod.yaml`**.

In addition, the new Deployment should set **`allowPrivilegeEscalation: false`** and **`privileged: false`** for the security context on container level.

Please create the Deployment and save its yaml under **`/opt/course/9/holy-api-deployment.yaml`.**

---

## Try it yourself first!

<details><summary> ✅ Solution (expand to view)</summary>
  
```bash
  
# Start from the raw Pod (already provided):
cat /opt/course/9/holy-api-pod.yaml

# Create a Deployment YAML from that Pod (edit to fit below spec) and save as:
touch /opt/course/9/holy-api-deployment.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: holy-api
  namespace: pluto
  labels:
    app: holy-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: holy-api
  template:
    metadata:
      labels:
        app: holy-api
    spec:
      containers:
      - name: app
        image: public.ecr.aws/docker/library/busybox:stable
        command: ["/bin/sh","-c","sleep 1d"]
        securityContext:
          allowPrivilegeEscalation: false
          privileged: false
#Save this file as /opt/course/9/holy-api-deployment.yaml, then:
```

```bash
kubectl -n pluto apply -f /opt/course/9/holy-api-deployment.yaml
kubectl -n pluto delete pod holy-api
kubectl -n pluto rollout status deploy/holy-api --timeout=120s
kubectl -n pluto get deploy holy-api -o wide
```
</details>






