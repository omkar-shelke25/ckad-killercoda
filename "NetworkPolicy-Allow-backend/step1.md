# Allow Only Frontend Pods to Reach Backend on TCP/80

## **Question (Weightage: 4)**

In the `netpol-demo1` namespace there are:
- Pod `backend` labeled `app=backend`
- Pod `frontend` labeled `role=frontend`

### **Task**

Create a NetworkPolicy named **`allow-frontend`** in the `netpol-demo1` namespace that:
- Selects **only** the backend Pod (`app=backend`) via `podSelector`
- Uses `policyTypes: [Ingress]`
- Allows **ingress** to the backend **only** from Pods labeled `role=frontend`
- Restricts the allowed traffic to **TCP port 80**

> ⚠️ This policy is purely an *allow-list* for the backend. For a full lock-down, you’d also pair this with a **default-deny** ingress policy affecting other Pods, but that’s not required here.


---

## **Solution (expand to view)**

<details>
<summary>Show YAML</summary>

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend
  namespace: netpol-demo1
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 80
```

</details>
