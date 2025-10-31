## **CKAD: Fix Pod Communication with NetworkPolicies**

### **Scenario**

You're working in the **`production`** namespace where strict NetworkPolicies control all pod-to-pod communication. Currently, the following pods exist:

- **`web-server`** - nginx server (labels: `apps.io=web-server`)
- **`redis-server`** - redis cache (labels: `cache.io=redis-server`)
- **`api-check`** - utility pod that needs to communicate with both servers
- **`allow-all`** - test pod with unrestricted access

### **The Problem**

The **`api-check`** pod cannot communicate with **`web-server`** or **`redis-server`**. Try it:

```bash
# This will fail - no response
kubectl exec -n production api-check -- wget -qO- --timeout=2 web-server-svc

# This will also fail
kubectl exec -n production api-check -- wget -qO- --timeout=2 redis-server-svc:6379
```

But the **`allow-all`** pod works fine:

```bash
# This works
kubectl exec -n production allow-all -- curl -s --max-time 2 web-server-svc
```

### **Your Task**

**WITHOUT modifying or creating any NetworkPolicy**, enable the **`api-check`** pod to:

1. Send requests to both **`web-server-svc`** and **`redis-server-svc`**
2. Receive responses back from them

### **Hints**

- 🔍 Examine the existing NetworkPolicies to understand what labels they expect
- 🏷️ NetworkPolicies use `podSelector` with `matchLabels` to identify allowed pods
- 💡 The solution involves modifying the **pod**, not the NetworkPolicies

---

### **Investigation Commands**

```bash
# List all NetworkPolicies
kubectl get networkpolicies -n production

# View a specific NetworkPolicy in detail
kubectl describe networkpolicy utils-network-policy -n production

# Check current labels on api-check pod
kubectl get pod api-check -n production --show-labels

# Check labels required by NetworkPolicies
kubectl get networkpolicy -n production -o yaml | grep -A 5 "matchLabels"
```

---

## Try it yourself first!

✅ Solution (expand to view)

<details><summary>Solution</summary>

### **Understanding the Problem**

The NetworkPolicies are looking for pods with specific labels:

1. **`utils-network-policy`** - Controls traffic for pods with `function=api-check` label
2. **`web-server-netpol`** - Allows traffic from pods with `function=api-check` label
3. **`redis-server-netpol`** - Allows traffic from pods with `function=api-check` label

The **`api-check`** pod was created **without** the `function=api-check` label!

### **Solution: Add the Required Label**

```bash
# Add the missing label to the api-check pod
kubectl label pod api-check -n production function=api-check
```

### **Verify the Fix**

```bash
# Check the label was added
kubectl get pod api-check -n production --show-labels

# Test connectivity to web-server
kubectl exec -n production api-check -- wget -qO- --timeout=2 web-server-svc

# Test connectivity to redis-server (it will connect, though redis responds with binary)
kubectl exec -n production api-check -- timeout 2 nc -zv redis-server-svc 6379
```

### **Why This Works**

1. The **`utils-network-policy`** now applies to `api-check` because it has `function=api-check`
   - Allows egress to pods with `apps.io=web-server` and `cache.io=redis-server`
   - Allows ingress from pods with those same labels

2. The **`web-server-netpol`** and **`redis-server-netpol`** allow traffic from `api-check`
   - They permit ingress from pods with `function=api-check`
   - They permit egress back to pods with `function=api-check`

3. All policies work together to enable bi-directional communication!

### **Key Takeaway**

NetworkPolicies are **label selectors**. To make a pod work with existing policies:
- Identify what labels the policies expect
- Add those labels to your pod
- No need to modify the NetworkPolicies themselves

</details>
