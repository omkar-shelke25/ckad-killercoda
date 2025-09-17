# Task: Fix Pods Failing Due to ResourceQuota

In namespace **`payments-prod`**, the following resources already exist:

- A **ResourceQuota** named `rq-payments-prod` that enforces:
  - `requests.cpu: 600m`
  - `requests.memory: 1536Mi`
  - `limits.cpu: 1`
  - `limits.memory: 3Gi`
- A **Deployment** named `checkout-api` with **3 replicas**.
- Its Pods are not being created.  Investigate why the **`checkout-api`** Pods are not running.
- Ensure the **total resource requests across all replicas remain within the quota**:
   - The Deployment’s **combined requests.cpu must be `< 600m`**.  
   - The Deployment’s **combined requests.memory must be `< 1536Mi`**.  
   - The Deployment’s **combined limits must be within limits.cpu = 1 and limits.memory = 3Gi**.
 

> Recommend to use `k set resource` command.


  

