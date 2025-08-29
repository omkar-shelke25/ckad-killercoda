# Task: LimitRange (memory) + Defaulted Pod

**Objective:** Enforce memory governance in a new namespace and validate defaulting via LimitRange.

## Requirements
1. Create a namespace: **team-a**.
2. In **team-a**, create a **LimitRange** named **mem-limit-range** (type: `Container`) with:
   - **min** memory request: `64Mi`
   - **max** memory limit: `512Mi`
   - **defaultRequest** (memory): `128Mi`
   - **default** (memory): `256Mi`
3. Create a Pod **busy-pod** in **team-a** using image **busybox**.
   - **Do not** set any resources in the Pod spec (no requests/limits).
4. Confirm the Pod **starts successfully** and received memory **request=128Mi** and **limit=256Mi** from the LimitRange.

---

## Hints (optional)

### LimitRange YAML
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
