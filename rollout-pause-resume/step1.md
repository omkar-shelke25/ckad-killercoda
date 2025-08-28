# CKAD: Update a Paused Deployment
A fintech company runs a critical payment API service as a Kubernetes deployment named **api-server** in the **default** namespace. The deployment is **paused** (pre-configured). During the maintenance window, you need to update the deployment **while it remains paused**, and only then **resume** it.

### Your Tasks
1. While the deployment is **paused**, set the container image to **nginx:1.26.0**.  
2. Still paused, **scale** the deployment to **5 replicas**.  
3. **Resume** the rollout and wait for it to become **Ready**.


---


# Try it yourself first!
<details><summary>✅ Solution For Your Reference</summary>
  
```bash

# Check current paused state, image, replicas
kubectl get deploy api-server -o jsonpath=$'{\"paused\":{.spec.paused},\"image\":\"{.spec.template.spec.containers[0].image}\",\"replicas\":{.spec.replicas}}\n'

# Identify container name (used below)
kubectl get deploy api-server -o jsonpath='{.spec.template.spec.containers[*].name}'; echo

# Set image (replace <name> with actual container name, often 'nginx' in this setup)
kubectl set image deploy/api-server <name>=nginx:1.26.0

# Scale to 5 replicas
kubectl scale deploy/api-server --replicas=5

# Resume rollout and watch
kubectl rollout resume deploy/api-server
kubectl rollout status deploy/api-server

```
</details>
