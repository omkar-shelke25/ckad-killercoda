# 🟢 Create Green, then Switch Service (namespace: `ios`)

You have a live deployment named **web-app-blue** running **nginx:1.19** with **3 replicas** in the **ios** namespace. 

Create a new deployment called **web-app-green** running **nginx:1.20** with **3 replicas**, **but do not route traffic to it yet**.

Then, update the existing service **web-app-service** to send traffic to the **green** deployment pods instead of **blue** with **zero downtime**.

Web-app-service selector switched to color=green → traffic now goes to **GREEN**

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


<details>
<summary>✅ Solution (expand to view)</summary>
  
#### copy web-blue deployment in new yaml file. Change according to green environment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-green
  namespace: ios
  labels:
    app: web-app
    color: green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
      color: green
  template:
    metadata:
      labels:
        app: web-app
        color: green
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 2
          periodSeconds: 5
```

```bash
# 🧪 Quick Checks

kubectl get svc -n ios  -owide

kubectl get po -n ios --show-labels | grep web-app-green

# for shift blue to green we need change service selector(pod-labels)
# two way -> 1) `edit command` 2) `patch command`

kubectl edit -n ios svc # change selector for green deployment

# Patch selector: color from blue → green
kubectl -n ios patch svc web-app-service --type='merge' -p '{"spec":{"selector":{"app":"web-app","color":"green"}}}'

kubectl get svc -n ios  -owide

# After switching (endpoints should now be green)
kubectl -n ios get endpoints web-app-service -o wide || kubectl -n ios describe svc web-app-service

```

</details>

