# CKAD: SecurityContext & Capabilities (Weightage: 8%)

## 📋 Background

The security team has identified that the `joker-deployment` in namespace `joker` needs hardening. The deployment is currently running with default security settings, which pose potential security risks.

The manifest file for the existing Deployment can be found at `/opt/course/20/joker-deployment.yaml`.

## 🎯 Task

Modify the existing Deployment named **`joker-deployment`** running in namespace **`joker`** so that its containers:

1. **Run with user ID `3000`**
2. **Privilege escalation is forbidden** (set `allowPrivilegeEscalation: false`)
3. **Add the following Linux capabilities:**
   - `NET_BIND_SERVICE`
   - `NET_RAW`
   - `NET_ADMIN`
4. Check the logs of the deployment.

**Requirements:**
- Save your modified YAML to **`/opt/course/20/joker-deployment-new.yaml`**
- Apply the changes to update the running deployment
- Verify all pods are running successfully with the new security configuration


---

<details>
<summary>📖 Solution</summary>

```bash
# First, examine the existing deployment
cat /opt/course/20/joker-deployment.yaml

# Copy the file to create a new version
cp /opt/course/20/joker-deployment.yaml /opt/course/20/joker-deployment-new.yaml

# Edit the file to add security context and capabilities
cat <<'EOF' > /opt/course/20/joker-deployment-new.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: joker-deployment
  namespace: joker
spec:
  replicas: 2
  selector:
    matchLabels:
      app: joker
  template:
    metadata:
      labels:
        app: joker
    spec:
      containers:
      - name: joker-container
        image: public.ecr.aws/docker/library/busybox:latest
        command: ["sh", "-c"]
        args:
        - |
          echo "Joker application starting..."
          echo "User ID: $(id -u)"
          echo "Capabilities: $(cat /proc/self/status | grep Cap)"
          while true; do
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Joker is running..."
            sleep 30
          done
        securityContext:
          runAsUser: 3000
          allowPrivilegeEscalation: false
          capabilities:
            add:
            - NET_BIND_SERVICE
            - NET_RAW
            - NET_ADMIN
EOF

# Apply the updated deployment
kubectl apply -f /opt/course/20/joker-deployment-new.yaml

# Wait for the rollout to complete
kubectl rollout status deployment/joker-deployment -n joker

# Verify the changes
kubectl get pods -n joker
kubectl describe deployment joker-deployment -n joker | grep -A 10 "Security Context"

# Check a pod to verify user ID
POD=$(kubectl get pods -n joker -l app=joker -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n joker $POD -- id

# Should show: uid=3000 gid=0(root)
```

**Alternative using kubectl edit:**

```bash
# Edit the deployment directly
kubectl edit deployment joker-deployment -n joker

# Add the securityContext section under containers:
#   securityContext:
#     runAsUser: 3000
#     allowPrivilegeEscalation: false
#     capabilities:
#       add:
#       - NET_BIND_SERVICE
#       - NET_RAW
#       - NET_ADMIN

# Save the current state to the required file
kubectl get deployment joker-deployment -n joker -o yaml > /opt/course/20/joker-deployment-new.yaml
```

**Key Points:**
- **runAsUser: 3000** - Forces the container to run as user ID 3000 (non-root)
- **allowPrivilegeEscalation: false** - Prevents gaining more privileges than the parent process
- **capabilities.add** - Grants specific Linux capabilities without running as root:
  - `NET_BIND_SERVICE` - Bind to ports below 1024
  - `NET_RAW` - Use RAW and PACKET sockets
  - `NET_ADMIN` - Network administration tasks

This configuration follows the principle of least privilege by:
- Running as a non-root user
- Preventing privilege escalation
- Only adding the specific capabilities needed

</details>
