# 🧪 Canary Deployment: 20% Traffic on nginx:1.20

You have an existing deployment named **frontend** running image **nginx:1.19** with **5 replicas** in the **default** namespace.
  
Create a **canary deployment** that runs **nginx:1.20** alongside the existing pods, handling **20% of the traffic**. Canary deployment named is `frontend-canary`.

Assume a **Service** exists targeting the `frontend` pods by label.  



---

## Try to solve this yourself first!

<details>
<summary>Short Notes On Canary and Blue-Green</summary>

## 📝 Short Notes

### **Canary Deployment**

* 🐤 **New version** runs **alongside** the old version in the same Service.
* ✅ **No Service change** required (both stable + canary share the same selector).
* 🔀 **Traffic split** by scaling replicas (e.g., 4 old + 1 new = \~20% new traffic).
* 🎯 Used for **gradual rollout** → observe metrics, then increase canary pods.
* 🔄 **Rollback** = scale down canary replicas to 0 (old version still runs).
* 💰 Lower resource usage (partial duplication).

---

### **Blue-Green Deployment**

* 🔵 Old = **Blue**, 🟢 New = **Green**.
* 🏗️ Create a **completely new Deployment** (Green) separate from Blue.
* ⚙️ **Service selector** (or Ingress) must be **changed** to route traffic to Green.
* 🚀 **Instant cutover**: 100% traffic moves from Blue → Green.
* 🔄 **Rollback** = switch Service back to Blue.
* 💰 Requires **full duplication** of environment (more resources).


---

### 📊 Quick Comparison

| Aspect          | Canary 🐤                                       | Blue-Green 🔵🟢                       |
| --------------- | ----------------------------------------------- | ------------------------------------- |
| Deployment      | Add new version alongside old                   | Create completely separate deployment |
| Service changes | **No change needed**                            | **Service/Ingress must switch**       |
| Traffic routing | Gradual (by replica scaling or ingress weights) | Instant 100% switch                   |
| Rollback        | Scale down/remove canary                        | Flip Service back to Blue             |
| Resource usage  | Partial duplication                             | Full duplication                      |

---
</details>


<details><summary>✅ Solution (expand to view)</summary>

---

### 🔁 Shifting traffic with canary

* Kubernetes **Services** distribute traffic evenly across all **ready Pods** that match the selector.
* By **scaling replicas**, you change the ratio of stable vs canary Pods → which indirectly changes traffic split.

---

### Example phases

* **80/20**: `frontend=4`, `frontend-canary=1` → 1 of 5 Pods is canary ≈ 20%.
* **60/40**: `frontend=3`, `frontend-canary=2` → 2 of 5 Pods are canary ≈ 40%.
* **50/50**: `frontend=2`, `frontend-canary=2` → equal split.
* **0/100**: `frontend=0`, `frontend-canary=5` → all traffic goes to canary.

---

### Canary Deployment YAML

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-canary
  labels:
    app: frontend
    version: v2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
      version: v2
  template:
    metadata:
      labels:
        app: frontend
        version: v2
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 80
```

---

### Scaling command

```bash
kubectl scale deploy/frontend --replicas=4
```

→ Ensures 4 stable Pods + 1 canary Pod = \~80/20 traffic split.
</details>
