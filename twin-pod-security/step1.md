# Two Containers, One Pod — Permissions Fix

## Situation

A QA team is testing a Pod that runs two cooperating processes.  
Their note says:

> “Both processes must live in the same Pod.  
> They run the same image, but each under a different user ID.  
> File access only works if the Pod has a common group ID.  
> We monitor it as `twin-uid` in namespace `sec-ctx`.”

---

## Task

- Work in namespace **sec-ctx**.  
- Create a Pod named **twin-uid**.  
- It should run **two containers** (`preproc` and `shipper`).  
- Both containers must:
  - Use the **same image** (e.g., `busybox:1.36`).  
  - Stay alive (e.g., `sleep 1d`).  
- Security requirements for containers:
  - `preproc` → runs as UID **1000**  
  - `shipper` → runs as UID **2000**  
- Pod-level `fsGroup` so they share file group ownership.
 
    
> Choose any valid `fsGroup` value between 1000 and 65535 (for example, 1000 or 2000) to allow both containers to share group file access.


---


<details> <summary>Reference Manifest (check only if stuck)</summary>
  
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: twin-uid
  namespace: sec-ctx
spec:
  securityContext:
    fsGroup: 3000
  containers:
  - name: preproc
    image: busybox:1.36
    securityContext:
      runAsUser: 1000
    command: ["sh","-c","sleep 1d"]
  - name: shipper
    image: busybox:1.36
    securityContext:
      runAsUser: 2000
    command: ["sh","-c","sleep 1d"]
```

</details>
