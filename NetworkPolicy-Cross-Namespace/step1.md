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


---

## **Solution (expand to view)**

<details>
<summary>Show YAML</summary>

- **Same namespace → just use podSelector.**
- **Cross namespace → use namespaceSelector + podSelector together (so you don’t accidentally allow Pods in other namespaces that reuse the same labels).**
  
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
