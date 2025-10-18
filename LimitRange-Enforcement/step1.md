# Task: LimitRange (memory) + Defaulted Pod

**Objective:** Enforce memory governance in a new namespace and validate defaulting via LimitRange.

## Requirements
1. Create a namespace: **`team-a`**.
2. In **`team-a`**, create a **LimitRange** named **`mem-limit-range`** (type: `Container`) with:
   - **`min`** memory request: `64Mi`
   - **`max`** memory limit: `512Mi`
   - **`defaultRequest`** (memory): `128Mi`
   - **`default`** (memory): `256Mi`
3. Create a Pod **`busy-pod`** in **`team-a`** using image **`public.ecr.aws/docker/library/busybox:latest`**.
   - **Do not** set any resources in the Pod spec (no requests/limits).
4. Confirm the Pod **starts successfully** and received memory **`request=128Mi`** and **`limit=256Mi`** from the LimitRange.

   > Below Command it’s just for your own verification.
   
   > kubectl -n team-a get pod busy-pod -o jsonpath='{.spec.containers[0].resources}'

<details><summary>✅ Solution (expand to view)</summary>
  
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: mem-limit-range
  namespace: team-a
spec:
  limits:
  - type: Container
    min:
      memory: 64Mi
    max:
      memory: 512Mi
    defaultRequest:
      memory: 128Mi
    default:
      memory: 256Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: busy-pod
  namespace: team-a
spec:
  containers:
  - name: bb
    image: public.ecr.aws/docker/library/busybox:latest
    command: ["sh","-c","sleep 3600"]
```

```bash
#verify:
#Inspect defaulted resources on the live Pod spec
kubectl -n team-a get pod busy-pod -o jsonpath='{.spec.containers[0].resources}'
```

</details>
