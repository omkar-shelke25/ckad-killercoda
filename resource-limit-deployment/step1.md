# CKAD: Configure Resource Requests and Limits

Two anime-themed deployments are running in the **manga** namespace, but they don't have any resource requests or limits configured. This can lead to resource contention and unstable cluster performance.

Your mission is to configure appropriate resource constraints for both deployments following Kubernetes best practices.

## 📋 Your Tasks

### Task 1: Configure Resources for naruto Deployment

Update the **naruto** deployment in the **manga** namespace to include:

**Resource Requests:**
- Memory: `100Mi`
- CPU: `100m`

> **Note:** Requests define the minimum resources guaranteed to a container. The scheduler uses these to decide which node to place the pod on.

### Task 2: Configure Resources for demon-slayer Deployment

Update the **demon-slayer** deployment in the **manga** namespace to include:

**Resource Limits:**
- Memory: `200Mi`
- CPU: `200m`

> **Note:** Limits define the maximum resources a container can use. If a container exceeds its memory limit, it will be terminated. If it exceeds CPU limits, it will be throttled.

---

## 🔍 Verify Your Work

After completing the tasks, verify your configuration:

```bash
# Check naruto deployment resources
kubectl describe deployment naruto -n manga | grep -A 10 "Containers:"

# Check demon-slayer deployment resources
kubectl describe deployment demon-slayer -n manga | grep -A 10 "Containers:"

# View all pods and their resource configurations
kubectl get pods -n manga -o custom-columns=NAME:.metadata.name,CPU-REQUEST:.spec.containers[0].resources.requests.cpu,CPU-LIMIT:.spec.containers[0].resources.limits.cpu,MEM-REQUEST:.spec.containers[0].resources.requests.memory,MEM-LIMIT:.spec.containers[0].resources.limits.memory
```

---

## 💡 CKAD Exam Tips

1. **Imperative Commands:** You can use `kubectl set resources` command for quick updates
2. **Units Matter:** 
   - CPU: Use `m` for millicores (1000m = 1 CPU core)
   - Memory: Use `Mi` (Mebibytes) or `Gi` (Gibibytes)
3. **Requests vs Limits:**
   - Requests: Minimum guaranteed resources
   - Limits: Maximum allowed resources
4. **Both can be set:** A pod can have both requests AND limits
5. **QoS Classes:** Kubernetes assigns QoS based on requests/limits:
   - **Guaranteed:** requests = limits for all resources
   - **Burstable:** requests < limits or only requests set
   - **BestEffort:** No requests or limits set

---

# Try it yourself first!

<details><summary>✅ Solution - Method 1: Imperative Commands</summary>

```bash
# Task 1: Configure requests for naruto
kubectl set resources deployment naruto \
  --requests=cpu=100m,memory=100Mi \
  -n manga

# Wait for rollout
kubectl rollout status deployment/naruto -n manga

# Task 2: Configure limits for demon-slayer
kubectl set resources deployment demon-slayer \
  --limits=cpu=200m,memory=200Mi \
  -n manga

# Wait for rollout
kubectl rollout status deployment/demon-slayer -n manga

# Verify
kubectl get pods -n manga -o custom-columns=NAME:.metadata.name,CPU-REQ:.spec.containers[0].resources.requests.cpu,CPU-LIM:.spec.containers[0].resources.limits.cpu,MEM-REQ:.spec.containers[0].resources.requests.memory,MEM-LIM:.spec.containers[0].resources.limits.memory
```

</details>

<details><summary>✅ Solution - Method 2: Declarative (Edit Deployment)</summary>

```bash
# Task 1: Edit naruto deployment
kubectl edit deployment naruto -n manga
```

Add the following under `spec.template.spec.containers[0]`:

```yaml
        resources:
          requests:
            cpu: "100m"
            memory: "100Mi"
```

```bash
# Task 2: Edit demon-slayer deployment
kubectl edit deployment demon-slayer -n manga
```

Add the following under `spec.template.spec.containers[0]`:

```yaml
        resources:
          limits:
            cpu: "200m"
            memory: "200Mi"
```

</details>

<details><summary>✅ Solution - Method 3: Patch Command</summary>

```bash
# Task 1: Patch naruto deployment with requests
kubectl patch deployment naruto -n manga --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/resources",
    "value": {
      "requests": {
        "cpu": "100m",
        "memory": "100Mi"
      }
    }
  }
]'

# Task 2: Patch demon-slayer deployment with limits
kubectl patch deployment demon-slayer -n manga --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/resources",
    "value": {
      "limits": {
        "cpu": "200m",
        "memory": "200Mi"
      }
    }
  }
]'

# Verify both deployments
kubectl rollout status deployment/naruto -n manga
kubectl rollout status deployment/demon-slayer -n manga
```

</details>

