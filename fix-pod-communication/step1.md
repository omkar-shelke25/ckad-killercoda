## **CKAD: Fix Pod Communication with NetworkPolicies**

You're working in a simulated `production` namespace. 

There are existing NetworkPolicies that strictly control pod-to-pod communication. You are NOT allowed to modify or create any NetworkPolicy. 

A pod named `api-check` needs to **send TCP traffic** to the existing `web-server` and `redis-server` pods. Currently, the `api-check` pod cannot communicate with them.

Your goal is to make `api-check` able to **send requests to** `web-server` and `redis-server` **without touching any existing NetworkPolicy objects.**


> Use the `nc -zv` command to test communication with the Redis server and the `curl` command to test communication with the  web server.



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
