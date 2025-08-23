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
