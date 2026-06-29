# CKAD: Fix RBAC for Deployment ServiceAccounts

### 📚 Reference Docs

- [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Role and ClusterRole](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole)
- [RoleBinding and ClusterRoleBinding](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding)
- [Configure Service Accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)

---

The Straw Hat Pirates need their monitoring systems to access Kubernetes API data. Both deployments in the **`one-piece`** namespace are currently logging RBAC errors.

Check the errors yourself:

```bash
kubectl logs deployment/monkey-d-luffy -n one-piece --tail=5
kubectl logs deployment/crew-monitor   -n one-piece --tail=5
```

You should see messages like:

```
Error from server (Forbidden): deployments.apps is forbidden:
User "system:serviceaccount:one-piece:default" cannot list resource "deployments"
```

---

## 📋 Tasks

### Part 1 — Fix `monkey-d-luffy`

The deployment currently uses the `default` ServiceAccount. You need to create a dedicated one with RBAC and assign it.

**1.** Create a ServiceAccount named **`thousand-sunny`** in the **`one-piece`** namespace.

**2.** Create a Role named **`strawhat-role`** in the **`one-piece`** namespace that grants these verbs on `deployments` (API group: `apps`):
- `get`
- `list`
- `watch`

**3.** Create a RoleBinding named **`strawhat-rb`** that binds **`strawhat-role`** to the **`thousand-sunny`** ServiceAccount.

**4.** Update the **`monkey-d-luffy`** deployment to use the **`thousand-sunny`** ServiceAccount.

---

### Part 2 — Fix `crew-monitor`

This deployment already has the **`nami-navigator`** ServiceAccount assigned — it just has no Role or RoleBinding yet.

**5.** Create a Role named **`navigator-role`** in the **`one-piece`** namespace with the same permissions (`get`, `list`, `watch` on `deployments`).

**6.** Create a RoleBinding named **`navigator-rb`** that binds **`navigator-role`** to the **`nami-navigator`** ServiceAccount.

---

## ✅ Verify

```bash
# Check that logs now show SUCCESS
kubectl logs deployment/monkey-d-luffy -n one-piece --tail=10
kubectl logs deployment/crew-monitor   -n one-piece --tail=10
```

---

<details>
<summary>💡 Solution (try it yourself first!)</summary>

```bash
# ── Part 1: monkey-d-luffy ──────────────────────────────────────────────

# 1. ServiceAccount
kubectl create serviceaccount thousand-sunny -n one-piece

# 2. Role
kubectl create role strawhat-role \
  --verb=get,list,watch \
  --resource=deployments.apps \
  -n one-piece

# 3. RoleBinding
kubectl create rolebinding strawhat-rb \
  --role=strawhat-role \
  --serviceaccount=one-piece:thousand-sunny \
  -n one-piece

# 4. Assign ServiceAccount to the deployment
kubectl set serviceaccount deployment monkey-d-luffy thousand-sunny -n one-piece

# Wait for rollout
kubectl rollout status deployment/monkey-d-luffy -n one-piece

# ── Part 2: crew-monitor ────────────────────────────────────────────────

# 5. Role
kubectl create role navigator-role \
  --verb=get,list,watch \
  --resource=deployments.apps \
  -n one-piece

# 6. RoleBinding
kubectl create rolebinding navigator-rb \
  --role=navigator-role \
  --serviceaccount=one-piece:nami-navigator \
  -n one-piece

# crew-monitor picks up new permissions automatically (no rollout needed)

# ── Verify logs ─────────────────────────────────────────────────────────
kubectl logs deployment/monkey-d-luffy -n one-piece --tail=10
kubectl logs deployment/crew-monitor   -n one-piece --tail=10
```

</details>
