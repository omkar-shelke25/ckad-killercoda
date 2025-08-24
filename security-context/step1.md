# Configure Pod and Container Security Contexts

Your security team has introduced a new **least privilege policy**. One of the workloads in the `security` namespace must be updated to follow these rules.

### Background

* Applications should never run as root.
* System users (UIDs < 1000) must be avoided.
* File systems should be protected against accidental writes.

### Task

In the `security` namespace, create a Pod named **secure-app-pod** that satisfies the following:

* At the **Pod level** (`spec.securityContext`), enforce that all containers run with a **non-root identity** (UID 1000 and GID 3000).
* The Pod should contain a single container named **app-container** running the image `busybox:1.36`.
  * The container must keep running (`sleep 3600`).
* At the **container level**, ensure the root filesystem is **read-only**.
* (Reminder: container-level security context values override Pod-level settings if they overlap.)
* Trying to write a file at `/` (e.g., `touch /newfile`) fails with **"Read-only file system"**.

---

## solution

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


```bash
kubectl exec -n security secure-app-pod -c app-container -- sh -c 'touch /newfile'
```
</details> 
