# CKAD: Debugging ResourceQuota with a Production Deployment

The namespace **`payments-prod`** is protected by a **ResourceQuota** that enforces strict CPU and Memory requests/limits.  
This ensures fair usage and prevents any single service from consuming excessive cluster resources.

A production Deployment, **`checkout-api`**, has been deployed with **3 replicas**.  

However, its Pods are not being scheduled. Inspect the ResourceQuota **`rq-payments-prod`**.

Investigate why the **`checkout-api`** Pods are not running.


---

Click **Start Scenario** to begin.
