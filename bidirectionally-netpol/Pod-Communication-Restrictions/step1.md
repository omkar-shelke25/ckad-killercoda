# 🔒 Configure Pod Communication with NetworkPolicies

## 🎯 Task Overview

In namespace **`ckad-netpol`**, you need to configure pod **`ckad-netpol-newpod`** so it can only send and receive traffic to/from the **`web`** and **`db`** pods.

## 📋 Current Environment

Three pods exist in the namespace:
- **web** 
- **db** 
- **ckad-netpol-newpod**

Multiple NetworkPolicies are already configured to control communication patterns.

## 🚫 Constraints
- **DO NOT** create, edit, or delete any NetworkPolicy
- The solution must ensure bidirectional communication between `ckad-netpol-newpod` and both `web` and `db` pods


## 💡 Try it yourself first!

<details><summary>✅ Solution (expand to view)</summary>

### 🔍 Step 1: Analyze the Current State

First, let's examine the current pod labels:
```bash
kubectl -n ckad-netpol get pods --show-labels
```

You should see:
- `web` pod has label `run=web`
- `db` pod has label `run=db`  
- `ckad-netpol-newpod` pod has label `env=newpod`

### 🔍 Step 2: Analyze NetworkPolicies

Examine the existing NetworkPolicies:
```bash
kubectl -n ckad-netpol describe networkpolicies
```

Key observations:
1. **default-deny-all**: Blocks all traffic by default
2. **web-netpol**: Allows `web` pod to communicate with pods labeled `env=db`
3. **db-netpol**: Allows `db` pod to communicate with pods labeled `run=web`
4. **allow-all**: Currently allows `ckad-netpol-newpod` to communicate only with itself

### 🎯 Step 3: Identify Required Label Changes

For bidirectional communication between `ckad-netpol-newpod`, `web`, and `db`:

1. **web** pod needs `env=db` label to communicate with `ckad-netpol-newpod`
2. **db** pod needs `run=web` label to communicate with `ckad-netpol-newpod`
3. The existing policies will handle the rest

### ✅ Step 4: Apply the Solution

Add the required labels to enable communication:

```bash
# Add env=db label to web pod (so it can communicate via web-netpol)
kubectl -n ckad-netpol label pod web env=db

# Add run=web label to db pod (so it can communicate via db-netpol)  
kubectl -n ckad-netpol label pod db run=web --overwrite
```

### ✅ Step 5: Verify the Configuration

Check the updated labels:
```bash
kubectl -n ckad-netpol get pods --show-labels
```

Expected result:
- `web` pod: `env=db,run=web`
- `db` pod: `run=db,run=web` 
- `ckad-netpol-newpod` pod: `env=newpod`

### 🔍 Step 6: Test Communication (Optional)

Test connectivity between pods:
```bash
# Test from ckad-netpol-newpod to web
kubectl -n ckad-netpol exec ckad-netpol-newpod -- wget -qO- --timeout=2 web

# Test from ckad-netpol-newpod to db  
kubectl -n ckad-netpol exec ckad-netpol-newpod -- wget -qO- --timeout=2 db
```

---

## 📖 Understanding the Solution

The solution works because:

1. **web-netpol** allows pods with `run=web` to communicate with pods having `env=db`
2. **db-netpol** allows pods with `run=db` to communicate with pods having `run=web`  
3. **allow-all** policy for `ckad-netpol-newpod` allows it to communicate with pods having `env=newpod`

By adding appropriate labels, we create communication paths:
- `ckad-netpol-newpod` (env=newpod) ↔ `web` (env=db) via allow-all and web-netpol
- `ckad-netpol-newpod` (env=newpod) ↔ `db` (run=web) via allow-all and db-netpol

</details>
