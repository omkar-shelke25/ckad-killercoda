# 🧪 Canary Deployment: 20% Traffic on nginx:1.20

You have an existing deployment named **frontend** running image **nginx:1.19** with **5 replicas** in the **default** namespace.  
Create a **canary deployment** that runs **nginx:1.20** alongside the existing pods, handling **20% of the traffic**. Assume a **Service** exists targeting the `frontend` pods by label.  
**Describe how you would gradually shift traffic** from the old version to the new version.


---



<details><summary>✅ Solution (expand to view)</summary>
  
🔁 How to shift traffic

- Replica weighting (Service-only): adjust replicas between stable (frontend) and canary (frontend-canary) since the Service balances per endpoint.

- Example phases:
   - 80/20: frontend=4, frontend-canary=1 
   - 60/40: frontend=3, frontend-canary=2
   - 50/50: frontend=2, frontend-canary=2 (total 4), or 3/3
   - 0/100: frontend=0, frontend-canary=5


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

```bash
# Adjust stable to 4 replicas → ~80/20 split
kubectl scale deploy/frontend --replicas=4
```
</details>
