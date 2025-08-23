# Allow Egress from `source-pod` to `target-pod` (TCP/80)

## **Question (Weightage: 4)**

Two namespaces exist:
- `netpol-demo9` with a Pod `source-pod` (label `app=source`)
- `external-ns` with a Pod `target-pod` (label `app=target`)

### **Task**

Create a NetworkPolicy named `external-target` **in the `netpol-demo9` namespace** that:
- Selects **only** the Pod with label `app=source`
- Has `policyTypes: [Egress]`
- Allows **egress** from the selected Pod **only** to Pods in namespace `external-ns` with label `app=target` on **TCP port 80**

> ⚠️ Note: This task **does not** require default-deny. You’re only asked to permit the specific egress path. (In production, you’d often pair this with a default-deny egress policy.)


---

## **Solution (expand to view)**

<details>
<summary>Show YAML</summary>

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: external-target
  namespace: netpol-demo9
spec:
  podSelector:
    matchLabels:
      app: source
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: external-ns
      podSelector:
        matchLabels:
          app: target
    ports:
    - protocol: TCP
      port: 80
```
</details>
