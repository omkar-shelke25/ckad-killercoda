# Task: Fix Pods Failing Due to ResourceQuota

In namespace **`payments-prod`**, the following resources already exist:

- A **ResourceQuota** named `rq-payments-prod` that enforces:
  - `requests.cpu: 600m`
  - `requests.memory: 1536Mi`
  - `limits.cpu: 1`
  - `limits.memory: 3Gi`

- A **Deployment** named `checkout-api` with **3 replicas**.

- Its Pods are not being created.  Investigate why the **`checkout-api`** Pods are not running.

