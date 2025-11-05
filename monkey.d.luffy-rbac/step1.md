# CKAD: Fix RBAC for Deployment

The Straw Hat Pirates need their monitoring systems to access deployment information. Currently, both **`monkey-d-luffy`** and **`crew-monitor`** deployments in the **`one-piece`** namespace are showing RBAC errors in their logs.

You should see errors like:

```vbnet
Error from server (Forbidden): deployments.apps is forbidden: User "system:serviceaccount:one-piece:default" cannot list resource "deployments"
```

or

```vbnet
Error from server (Forbidden): deployments.apps is forbidden: User "system:serviceaccount:one-piece:nami-navigator" cannot list resource "deployments"
```

## 📋 Your Tasks

### Part 1: Fix monkey-d-luffy Deployment

1. Create a ServiceAccount named **`thousand-sunny`** in the **one-piece** namespace.

2. Create a Role named **`strawhat-role`** in the **`one-piece`** namespace that grants the following permissions on Deployments:
   - `get`
   - `list`
   - `watch`

3. Create a RoleBinding named **`strawhat-rb`** in the **`one-piece`** namespace that binds the **`strawhat-role`** to the **`thousand-sunny`** ServiceAccount.

4. Update the existing Deployment **`monkey-d-luffy`** to use the **`thousand-sunny`** ServiceAccount.

### Part 2: Fix crew-monitor Deployment

The **`crew-monitor`** deployment already has a ServiceAccount (**`nami-navigator`**), but it's missing the Role and RoleBinding!

5. Create a Role named **`navigator-role`** in the **`one-piece`** namespace with the same permissions (`get`, `list`, `watch` on deployments).

6. Create a RoleBinding named **`navigator-rb`** that binds **`navigator-role`** to the **`nami-navigator`** ServiceAccount.

---

## ✅ Verify Your Work

After completing the tasks, check the logs again:

```bash
# These should now show SUCCESS messages!
kubectl logs deployment/monkey-d-luffy -n one-piece --tail=10
kubectl logs deployment/crew-monitor -n one-piece --tail=10
```

---

# Try it yourself first!

<details><summary>✅ Solution For Your Reference</summary>

```bash
# Part 1: Fix monkey-d-luffy
# ===========================

# 1. Create ServiceAccount
kubectl create serviceaccount thousand-sunny -n one-piece

# 2. Create Role with deployment permissions
kubectl create role strawhat-role \
  --verb=get,list,watch \
  --resource=deployments \
  -n one-piece

# 3. Create RoleBinding
kubectl create rolebinding strawhat-rb \
  --role=strawhat-role \
  --serviceaccount=one-piece:thousand-sunny \
  -n one-piece

# 4. Update Deployment to use the ServiceAccount
kubectl set serviceaccount deployment monkey-d-luffy thousand-sunny -n one-piece

# Wait for rollout
kubectl rollout status deployment/monkey-d-luffy -n one-piece


# Part 2: Fix crew-monitor
# ===========================

# 5. Create Role for navigator
kubectl create role navigator-role \
  --verb=get,list,watch \
  --resource=deployments \
  -n one-piece

# 6. Create RoleBinding for nami-navigator ServiceAccount
kubectl create rolebinding navigator-rb \
  --role=navigator-role \
  --serviceaccount=one-piece:nami-navigator \
  -n one-piece

# The crew-monitor deployment will automatically pick up the new permissions
# Check logs to verify
kubectl logs deployment/crew-monitor -n one-piece --tail=20 -f

```

</details>

---

