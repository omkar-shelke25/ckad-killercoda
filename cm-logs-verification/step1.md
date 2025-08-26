# Use a specific ConfigMap key as an environment variable (and verify via logs)

## Requirements
- Namespace: **`olly`**
- ConfigMap **`message-config`** with:
  - `message: Hello, Kubernetes`
- Pod **`message-pod`** using image **`busybox:1.37.0`**
  - Command: `["sh","-c","while true; do echo \"$MESSAGE\"; sleep 5; done"]`
  - Env var **`MESSAGE`** from **ConfigMap key `message`**
- Verify logs show the value

---

## Try it yourself first!

<details><summary>✅ Solution (expand to view)</summary>

```bash
# 1) ConfigMap
kubectl -n olly create cm message-config --from-literal message='Hello, Kubernetes'

# 2) Pod (inline YAML)
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: message-pod
  namespace: olly
spec:
  containers:
  - name: message-pod
    image: busybox:1.37.0
    command: ["sh","-c","while true; do echo \"$MESSAGE\"; sleep 5; done"]
    env:
    - name: MESSAGE
      valueFrom:
        configMapKeyRef:
          name: message-config
          key: message
EOF

# 3) Verify via logs
kubectl -n olly wait --for=condition=Ready pod/message-pod --timeout=60s
kubectl -n olly logs message-pod --tail=5

```
</details>
