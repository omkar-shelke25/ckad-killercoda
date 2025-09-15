# 🔐 CKAD: NetworkPolicy - Restrict Redis Access

In namespace **jupiter** 🪐, you'll find three Deployments named **app1**, **app2**, and **redis**.
All Deployments are exposed inside the cluster using Services.

Create a **NetworkPolicy** named **np-redis** which restricts **incoming connections** to Deployment **redis** so that:

* ✅ Only Pods from Deployment **app1** and **app2** can connect to Deployment **redis** on **TCP port 6379**.
* ❌ No other Pods in the namespace should be able to connect to Deployment **redis**.
* 🌐 Pods in Deployment **redis** should still be able to perform DNS lookups (UDP/TCP 53).




## 💪 Try it yourself first!

<details><summary> 🎯 Solution (expand to view)</summary>

### 🧪 Test Requirements:
* `kubectl exec -it <app1-pod> -- nc -zv redis 6379` (should succeed ✅)
* `kubectl exec -it <app2-pod> -- nc -zv redis 6379` (should succeed ✅)  
* `kubectl exec -it <test-pod-pod> -- nc -zv redis 6379` (should fail ❌)


### 🔍 Step 1: Analyze the existing resources

First, examine the deployments and their labels:
```bash
kubectl -n jupiter get deployments --show-labels
kubectl -n jupiter get pods --show-labels
```

You'll see that each deployment creates pods with labels like `app=app1`, `app=app2`, and `app=redis`.

---

### 📝 Step 2: Create the NetworkPolicy

Create a NetworkPolicy that:
- 🎯 Targets pods with `app=redis` 
- ⬇️ Allows ingress from pods with `app=app1` and `app=app2` on port 6379
- ⬆️ Allows egress for DNS (UDP/TCP port 53)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np-redis
  namespace: jupiter
spec:
  podSelector:
    matchLabels:
      app: redis
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: app1
    - podSelector:
        matchLabels:
          app: app2
    ports:
    - protocol: TCP
      port: 6379
  egress:
  - ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
EOF
```

---

### 🔍 Step 3: Verify the NetworkPolicy

Check that the NetworkPolicy was created correctly:
```bash
kubectl -n jupiter get networkpolicy
kubectl -n jupiter describe networkpolicy np-redis
```

---

### 🧪 Step 4: Test the connectivity

Get the pod names first:
```bash
kubectl -n jupiter get pods
```

Test that app1 and app2 can connect to redis:
```bash
# Get pod names (replace with actual names)
APP1_POD=$(kubectl -n jupiter get pods -l app=app1 -o jsonpath='{.items[0].metadata.name}')
APP2_POD=$(kubectl -n jupiter get pods -l app=app2 -o jsonpath='{.items[0].metadata.name}')
TEST_POD=$(kubectl -n jupiter get pods -l app=test-pod -o jsonpath='{.items[0].metadata.name}')

# These should succeed ✅
kubectl -n jupiter exec -it $APP1_POD -- nc -zv redis 6379
kubectl -n jupiter exec -it $APP2_POD -- nc -zv redis 6379

# This should fail ❌ (timeout or connection refused)
kubectl -n jupiter exec -it $TEST_POD -- nc -zv redis 6379
```

---

### 🌐 Step 5: Test DNS functionality

Verify that redis pods can still perform DNS lookups:
```bash
REDIS_POD=$(kubectl -n jupiter get pods -l app=redis -o jsonpath='{.items[0].metadata.name}')
kubectl -n jupiter exec -it $REDIS_POD -- nslookup kubernetes.default
```

---

🎉 **Final result:**

* ✅ Only app1 and app2 pods can connect to redis on port 6379
* ❌ test-pod cannot connect to redis  
* 🌐 Redis pods can still perform DNS lookups
* 🔐 The NetworkPolicy `np-redis` successfully restricts incoming connections while maintaining essential functionality

</details>
