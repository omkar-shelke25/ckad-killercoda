# Create `pod6` with a readiness-probe (default namespace)

## Task
Create a single Pod named **`pod6`** in Namespace **`default`** using image **`busybox:1.31.0`**.

- Add a **readinessProbe** that runs: `cat /tmp/ready`
- Set:
  - `initialDelaySeconds: 5`
  - `periodSeconds: 10`
- Command for the container should be:
  - `touch /tmp/ready && sleep 1d`
- Confirm the Pod becomes **Ready**.

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
