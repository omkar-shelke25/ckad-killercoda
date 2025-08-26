# Grant CronJob-Only Permissions in a Namespace

## Objective
A data science team needs permissions to **manage the lifecycle of CronJobs** in their dedicated namespace, **`batch-processing`**, but they **must not** be able to manage other workload types like **Deployments** or **Pods** directly.

## Requirements
- Create a new namespace called **`batch-processing`**.
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

**Imperative hints:**
```bash
k create ns batch-processing
k create sa cron-manager-sa -n batch-processing
k create role -n batch-processing cronjob-lifecycle-role \
  --verb get,list,watch,create,update,patch,delete \
  --resource cronjobs.batch
k create rolebinding -n batch-processing bind-cron-manager \
  --role cronjob-lifecycle-role \
  --serviceaccount batch-processing:cron-manager-sa
