# Create `pod6` with a readiness-probe (default namespace)

## Task
Create a single **Pod** named **`pod6`** in **Namespace `default`** of image **`busybox:1.31.0`**.  
The **Pod** should have a **readiness-probe** executing `cat /tmp/ready`. It should **initially wait 5** and **periodically wait 10 seconds**.
This will set the container **ready only if the file `/tmp/ready` exists**.

Use below command:
- `command: ["/bin/sh","-c","touch /tmp/ready && sleep 1d"]`

---

## Try it yourself first!

<details><summary>✅ Solution (expand to view)</summary>

```bash 
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: pod6
  namespace: default
spec:
  containers:
  - name: pod6
    image: busybox:1.31.0
    command: ["/bin/sh","-c","touch /tmp/ready && sleep 1d"]
    readinessProbe:
      exec:
        command: ["/bin/sh","-c","cat /tmp/ready"]
      initialDelaySeconds: 5
      periodSeconds: 10
EOF
kubectl wait --for=condition=Ready pod/pod6 --timeout=60s
```
</details>
