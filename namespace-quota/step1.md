# 🧮 Calculate and Set Memory Requests Based on Namespace Quota

## 📋 Mission Brief

You're working with **Team Alpha's** production environment where the deployment `backend-api-service` needs proper resource configuration. The platform team requires all deployments to use exactly **50% of the namespace memory quota** as memory requests.

## 🎯 Current Situation
- **Namespace**: `team-alpha-production`
- **Deployment**: `backend-api-service` (2 replicas)
- **Problem**: No memory requests configured
- **Requirement**: Set memory requests to 50% of namespace quota

## 📊 Task Requirements

### Step 1: Analyze Namespace Resource Quota
- ✅ Inspect the resource quota to find maximum memory allocation
- ✅ Calculate 50% of the quota memory limit

### Step 2: Configure Deployment Memory Requests  
- ✅ Modify the `backend-api-service` deployment
- ✅ Set memory requests to calculated value (50% of quota)
- ✅ Ensure the configuration is applied to the container spec

---

## 💡 Try It Yourself First! 

<details><summary>📋 Complete Solution (Click to expand)</summary>

### Step 1: Analyze the Namespace Resource Quota

First, let's examine the resource quota to understand the memory allocation:

```bash
# Check the resource quota details
kubectl -n team-alpha-production describe resourcequota team-alpha-quota
```

You should see output similar to:
```
Name:            team-alpha-quota
Namespace:       team-alpha-production
Resource         Used  Hard
--------         ----  ----
limits.memory    0     8Gi
requests.memory  0     4Gi
```

**Key Information:**
- **Memory Quota Limit**: 4Gi (requests.memory)
- **Required Memory Request**: 50% of 4Gi = **2Gi**

### Step 2: Calculate 50% of Memory Quota

```bash
# The math:
# Namespace memory quota: 4Gi
# Required memory request: 4Gi ÷ 2 = 2Gi per deployment
# With 2 replicas: 2Gi ÷ 2 = 1Gi per pod
```

### Step 3: Configure Deployment Memory Requests

**Method 1: Using kubectl patch (Recommended for CKAD)**

```bash
# Patch the deployment to add memory requests
kubectl -n team-alpha-production patch deployment backend-api-service -p '{"spec":{"template":{"spec":{"containers":[{"name":"api-server","resources":{"requests":{"memory":"1Gi"}}}]}}}}'
```

**Method 2: Using kubectl edit**

```bash
# Edit the deployment interactively
kubectl -n team-alpha-production edit deployment backend-api-service
```

Add the following under the container spec:
```yaml
        resources:
          requests:
            memory: 1Gi
```

**Method 3: Complete YAML Replacement**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-api-service
  namespace: team-alpha-production
  labels:
    app: backend-api
    tier: backend
    team: alpha
    version: v1.3.2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend-api
  template:
    metadata:
      labels:
        app: backend-api
        tier: backend
        team: alpha
    spec:
      containers:
      - name: api-server
        image: nginx:1.21-alpine
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: 1Gi
        env:
        - name: ENVIRONMENT
          value: "production"
        - name: TEAM
          value: "alpha"
        - name: API_VERSION
          value: "v1.3.2"
EOF
```

### Step 4: Verify the Configuration

```bash
# Check deployment resource configuration
kubectl -n team-alpha-production describe deployment backend-api-service | grep -A 5 "Requests:"

# Verify resource quota usage
kubectl -n team-alpha-production describe resourcequota team-alpha-quota

# Check pod resource allocation
kubectl -n team-alpha-production get pods -l app=backend-api -o jsonpath='{.items[*].spec.containers[*].resources.requests.memory}'
```

### Step 5: Validate Quota Compliance

```bash
# Total memory requests should be 2Gi (2 pods × 1Gi each)
kubectl -n team-alpha-production top pods 2>/dev/null || echo "Metrics not available"

# Check quota usage after configuration
kubectl -n team-alpha-production get resourcequota team-alpha-quota -o yaml
```

---

### ✅ Success Criteria

After completion, verify:

1. **Namespace quota analyzed**: 4Gi memory quota identified
2. **Calculation correct**: 50% of 4Gi = 2Gi total request
3. **Per-pod allocation**: 2Gi ÷ 2 replicas = 1Gi per pod  
4. **Deployment updated**: Memory requests configured
5. **Quota compliance**: Resource usage within limits

### 📊 Expected Results

```bash
# Resource quota should show memory usage
kubectl -n team-alpha-production get resourcequota
# NAME               AGE   REQUEST                            LIMIT
# team-alpha-quota   10m   requests.memory: 2Gi/4Gi, ...     limits.memory: 0/8Gi, ...
```

</details>

