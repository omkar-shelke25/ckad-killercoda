# Namespace-Local Ingress Only

A team needs to enforce the following rule in `netpol-demo6`: pods in the namespace may receive traffic **only** from other pods in the same namespace. Ingress originating from **any other namespace** must be denied.

Pods `pod-a` and `pod-b` already exist in `netpol-demo6` and are running NGINX.

## Task

In the `netpol-demo6` namespace:

- Create a NetworkPolicy named `internal-only` that:
  - **Selects all pods** in the namespace.
  - **Allows ingress** from **any pod** in the same namespace.
  - **Denies ingress** from pods in **other namespaces**.

### Notes
- Use `policyTypes: ["Ingress"]`.
- Use a `podSelector` that matches all pods in the namespace.
- Use an `ingress.from` rule that allows peers selected by a (same-namespace) `podSelector`.

### Solution
<details>
<summary>Create NetworkPolicy using imperative command</summary>

```bash  
kubectl create networkpolicy internal-only \
  --namespace=netpol-demo6 \
  --pod-selector="" \
  --ingress="" \
  --ingress-from-selector=""
```
</details>

<details>
<summary>yaml File Solution</summary>

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: internal-only
  namespace: netpol-demo6
spec:
  podSelector: {}        # select all pods in this namespace
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}    # allow any pod from the same namespace
```
</details>
