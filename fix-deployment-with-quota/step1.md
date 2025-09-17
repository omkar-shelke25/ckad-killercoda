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


---
## Try it yourself first!

✅ Solution (expand to view)
<details><summary>Solution</summary>


### 1. Fix with YAML

Edit the Deployment and add resources:

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "300Mi"
  limits:
    cpu: "200m"
    memory: "500Mi"
```

Apply:

```bash
kubectl apply -f checkout-api.yaml
```

---

### 2. Alternative Solution - Fix with Command

```bash
kubectl -n payments-prod set resources deploy/checkout-api \
  --requests=cpu=100m,memory=300Mi \
  --limits=cpu=200m,memory=500Mi
```

---

### 3. Explanation

* **Requests** = minimum guaranteed resources per Pod

  * CPU: `100m` (\~0.1 vCPU)
  * Memory: `300Mi` (\~300 MB)
* **Limits** = maximum Pod can use

  * CPU: `200m`
  * Memory: `500Mi`

With **3 replicas**:

* Total requests = **300m CPU, 900Mi memory** (under quota `600m`, `1536Mi`)
* Total limits = **600m CPU, 1500Mi memory** (under quota `1 CPU`, `3Gi`)

✅ Fits within the ResourceQuota → Pods will be admitted and run.

</details>
