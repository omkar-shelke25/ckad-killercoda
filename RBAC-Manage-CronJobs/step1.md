# Grant CronJob-Only Permissions in a Namespace

## Objective
A data science team needs permissions to **manage the lifecycle of CronJobs** in their dedicated namespace, **`batch-processing`**, but they **must not** be able to manage other workload types like **Deployments** or **Pods** directly.

## Requirements
- Create a **ServiceAccount** named **`cron-manager-sa`** in **`batch-processing`**.
- Create a **Role** named **`cronjob-lifecycle-role`** in **`batch-processing`** that allows verbs:  
  `get, list, watch, create, update, patch, delete` on **`cronjobs`** (API group **`batch`**).
- Create a **RoleBinding** named **`bind-cron-manager`** to grant the role to the ServiceAccount **`cron-manager-sa`**.
- Verify the service account **can create a CronJob** but **cannot create a Pod**.

> 📝 **Scope Notes**
> - Use **Role**/**RoleBinding** (namespace-scoped), not ClusterRole/ClusterRoleBinding.
> - Resource should be **`cronjobs`** in API group **`batch`** (you can use `cronjobs.batch` in imperative commands).

---

## Try it yourself first!

✅ Solution (expand to view)

<details><summary>Commands</summary>

```bash

# ServiceAccount
kubectl create sa cron-manager-sa -n batch-processing

# Role
kubectl create role cronjob-lifecycle-role \
  -n batch-processing \
  --verb=get,list,watch,create,update,patch,delete \
  --resource=cronjobs.batch

# RoleBinding
kubectl create rolebinding bind-cron-manager \
  -n batch-processing \
  --role=cronjob-lifecycle-role \
  --serviceaccount=batch-processing:cron-manager-sa
```
</details>

<details><summary>YAML</summary>

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cron-manager-sa
  namespace: batch-processing
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: cronjob-lifecycle-role
  namespace: batch-processing
rules:
  - apiGroups: ["batch"]
    resources: ["cronjobs"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: bind-cron-manager
  namespace: batch-processing
subjects:
  - kind: ServiceAccount
    name: cron-manager-sa
    namespace: batch-processing
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: cronjob-lifecycle-role
```

</details>


<details><summary>Verify RBAC Permission</summary>
  
```bash
# Should succeed
kubectl auth can-i create cronjobs.batch \
  --as=system:serviceaccount:batch-processing:cron-manager-sa \
  -n batch-processing

# Should fail
kubectl auth can-i create pods \
  --as=system:serviceaccount:batch-processing:cron-manager-sa \
  -n batch-processing
```

</details>
