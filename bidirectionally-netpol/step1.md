📘 [Network Policies | Kubernetes ](https://kubernetes.io/docs/concepts/services-networking/network-policies/) 

## 🔧 Configure Network Isolation for Production Workload

## 📖 Scenario Context

You're working as a DevOps engineer for a fintech company. The security team has implemented NetworkPolicies for a payment processing platform, but during deployment, the pods were labeled incorrectly. 

In namespace **`payment-platform`**, three microservices pods exist:

- **`frontend-service`** 
- **`database-service`** 
- **`payment-processor`** 

## 🎯 Task Requirements

The **`payment-processor`** pod must be able to communicate **`bidirectionally`** with both the `frontend-service` and `database-service` pods, as defined by the existing NetworkPolicies.

### 🚫 Important Constraints
- You are **NOT allowed** to create, modify, or delete any NetworkPolicy

---

## 💡 Try It Yourself First!

**Hint**: Examine the existing NetworkPolicies to understand what labels they expect:
```bash
kubectl -n payment-platform describe networkpolicy
```

<details><summary>🔧 Solution (Click to expand)</summary>

### Step 1: Examine the Current State

First, check the current pod labels and NetworkPolicies:

```bash
kubectl -n payment-platform get pods --show-labels
```

```bash
kubectl -n payment-platform get networkpolicy
```

### Step 2: Analyze NetworkPolicy Requirements

Examine what labels each NetworkPolicy expects:

```bash
kubectl -n payment-platform describe networkpolicy payment-processor-policy
```

You'll see the policy selects pods with `tier=payment` and allows traffic from/to pods with `tier=frontend` and `tier=database`.

### Step 3: Update Pod Labels

Apply the correct labels to align with NetworkPolicies:

```bash
# Label the frontend service
kubectl -n payment-platform label pod frontend-service tier=frontend --overwrite

# Label the database service  
kubectl -n payment-platform label pod database-service tier=database --overwrite

# Label the payment processor
kubectl -n payment-platform label pod payment-processor tier=payment --overwrite
```

### Step 4: Verify the Labels

```bash
kubectl -n payment-platform get pods --show-labels
```

You should see:
```
NAME                READY   STATUS    RESTARTS   AGE   LABELS
frontend-service    1/1     Running   0          5m    tier=frontend,version=v1.2.3
database-service    1/1     Running   0          5m    tier=database,version=v2.1.0
payment-processor   1/1     Running   0          5m    component=payment,tier=payment,version=v1.0.0
```

### Step 5: Test Network Connectivity (Optional)

You can test the network policies by executing into pods and testing connectivity:

```bash
# Test from payment-processor to frontend-service
kubectl -n payment-platform exec payment-processor -- curl -m 5 frontend-service

# Test from payment-processor to database-service  
kubectl -n payment-platform exec payment-processor -- curl -m 5 database-service
```

---

### 🎉 Success Criteria

✅ **payment-processor** pod has label `tier=payment`  
✅ **frontend-service** pod has label `tier=frontend`  
✅ **database-service** pod has label `tier=database`  
✅ NetworkPolicies now properly isolate traffic according to security requirements

</details>

