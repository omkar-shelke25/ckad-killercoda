## Scenario

A fintech company runs a critical payment API service as a Kubernetes deployment named **api-server** in the **default** namespace. 

The service currently uses Docker image **nginx:1.25.3** with **3 replicas**. Due to a security patch, the DevOps team **paused the rollout** to avoid impact during their monitoring window. 

They then updated the image to **nginx:1.26.0** and **increased replicas to 5** for increased traffic expected during peak hours. 

However, **while the rollout is paused**, the two new pods spin up with the **old image `nginx:1.25.3`**, potentially causing inconsistent behavior for customers.

---

# Try it yourself first!
<details><summary>✅ Solution For reference</summary>
  
```bash
# Confirm paused
kubectl get deploy api-server -o jsonpath='{.spec.paused}'; echo

# Pause / resume
kubectl rollout resume deploy/api-server

# Update image & replicas (while paused)
kubectl set image deploy/api-server '*=nginx:1.26.0' --record=true
kubectl scale deploy/api-server --replicas=5

# Watch pods
kubectl get pods -w -l app=api-server

# History, describe, status
kubectl rollout history deploy/api-server
kubectl describe deploy/api-server | grep -i image
kubectl rollout status deploy/api-server
```
</details>
