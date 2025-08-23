# Configure Pod and Container Security Contexts

A new policy requires workloads to run with least privilege. A Pod must:
- Run as a non-root user/group at the **Pod level**.
- Have a **read-only** root filesystem at the **container level**.

## Task

In the `security` namespace:

- Create a Pod named **secure-app-pod**.
- At the **Pod** level (`spec.securityContext`), ensure all containers run with:
  - `runAsUser: 1000`
  - `runAsGroup: 3000`
  - (Rationale: UIDs below 1000 are typically system users; use 1000/3000 for app identity.)
- The Pod contains one container:
  - Name: `app-container`
  - Image: `busybox:1.36`
  - Command: `sleep 3600` (container must remain running)
- At the **container** level (`securityContext`):
  - Set `readOnlyRootFilesystem: true`
  - (Note: Container-level settings override Pod-level ones where fields overlap.)

### Acceptance criteria

- `Pod/secure-app-pod` is **Running** in `security`.
- Inside the container:
  - `id -u` returns **1000**, and `id -g` returns **3000**.
  - Attempting `touch /newfile` fails with **"Read-only file system"**.

---

## (Optional) Reference solution

<details>
<summary>Click to view YAML</summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-app-pod
  namespace: security
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    runAsNonRoot: true
  containers:
  - name: app-container
    image: busybox:1.36
    command: ["/bin/sh","-c","sleep 3600"]
    securityContext:
      readOnlyRootFilesystem: true
```
</details> 
