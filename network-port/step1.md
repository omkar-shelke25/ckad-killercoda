# Allow Different Peers by Port

Traffic policy for `netpol-demo8` requires the target pod to accept ingress on:
- **port 80** only from pods labeled `role=frontend`,
- **port 443** only from pods labeled `role=admin`.

Pods `multi-port-pod`, `frontend`, and `admin` are already running in `netpol-demo8`.

## Task

In the `netpol-demo8` namespace:

- Create a NetworkPolicy named **`allow-frontend-and-admin`** that:
  - **Selects** the target pod(s) using label(s) on the target:  
    (the provided pod is labeled `app=multi-port`).
  - Sets `policyTypes: ["Ingress"]`.
  - Allows ingress on **TCP/80** **only** from pods with label `role=frontend` in the **same** namespace.
  - Allows ingress on **TCP/443** **only** from pods with label `role=admin` in the **same** namespace.
  - Do not permit other sources.

### Notes
- Use separate `ingress` rules to express per-port peer sets.
- If you select by `podSelector: {}`, your policy will apply to **all** pods in the namespace; select only the intended target.


## **Solution**

Try to solve this yourself first, then check the solution if needed:

<details>
<summary>Click to view Solution</summary>
  
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-and-admin
  namespace: netpol-demo8
spec:
  podSelector:
    matchLabels:
      app: multi-port
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
  - from:
    - podSelector:
        matchLabels:
          role: admin
    ports:
    - protocol: TCP
      port: 443
```

</details>
