# 🔄CKAD: Configure and Execute Rolling Update

## 📋 Mission Brief

The production web platform `web1` needs to be updated to a new version with **zero downtime**. You must configure strict rolling update parameters and demonstrate the ability to rollback if needed.

### 🎯 Current State
- **Namespace**: `prod`
- **Deployment**: `web1`
- **Current Image**: `public.ecr.aws/nginx/nginx:perl`
- **Replicas**: `10`
- **Status**: Default rolling update strategy (not suitable for production)

### 📝 Task Requirements

#### Part 1: Configure Rolling Update Strategy
Update the deployment `web1` to use:
- ✅ **New Image**: `public.ecr.aws/nginx/nginx:stable-perl`
- ✅ **maxUnavailable**: `0%` (no pods can be unavailable)
- ✅ **maxSurge**: `5%` (maximum 5% extra pods during rollout)
- ✅ **Rolling Update Type**: `RollingUpdate`

#### Part 2: Execute and Monitor Rollout
- ✅ Apply the configuration changes
- ✅ Monitor the rollout progress, including how pods are terminated and replaced during the image update
- ✅ Verify all pods are updated successfully

#### Part 3: Rollback previous version
- ✅ Execute immediate rollback to previous version
- ✅ Verify all pods are back to `perl` image
- ✅ Confirm rollback completed successfully


> In this question, we used maxUnavailable: 0% (no pods can be unavailable) and maxSurge: 5% (allowing up to 5% extra pods during the rollout). Because probes are enabled, it may take some time for all pods to become ready. After performing the image update and rollback, verify that all pods are running with the correct image.


---

## 💡 Try It Yourself First!

<details><summary>📋 Complete Solution (Click to expand)</summary>

### Step 1: Configure Rolling Update Strategy

You can use `kubectl patch` or edit the deployment directly:

**Option A: Using kubectl patch (Recommended for exam speed)**

```bash
# Update the rolling update strategy
kubectl -n prod patch deployment web1 -p '{
  "spec": {
    "strategy": {
      "type": "RollingUpdate",
      "rollingUpdate": {
        "maxUnavailable": "0%",
        "maxSurge": "5%"
      }
    }
  }
}'
```

**Option B: Using kubectl edit**

```bash
kubectl -n prod edit deployment web1
```

Then modify the `strategy` section:

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0%
      maxSurge: 5%
```

**Option C: Apply complete YAML**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web1
  namespace: prod
  labels:
    app: web-frontend
    tier: frontend
    environment: production
spec:
  replicas: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0%
      maxSurge: 5%
  selector:
    matchLabels:
      app: web-frontend
  template:
    metadata:
      labels:
        app: web-frontend
        tier: frontend
        version: perl
    spec:
      containers:
      - name: nginx
        image: public.ecr.aws/nginx/nginx:perl
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 3
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
EOF
```

### Step 2: Update the Image to New Version

```bash
# Update the container image
kubectl -n prod set image deployment/web1 nginx=public.ecr.aws/nginx/nginx:stable-perl
```

**Alternative: Record the change for rollout history**

```bash
kubectl -n prod set image deployment/web1 nginx=public.ecr.aws/nginx/nginx:stable-perl --record
```

### Step 3: Monitor the Rollout

```bash
# Watch the rollout status in real-time
kubectl -n prod rollout status deployment/web1

# In another terminal, watch pods updating
kubectl -n prod get pods -l app=web-frontend -w

# Check rollout history
kubectl -n prod rollout history deployment/web1

# View detailed rollout status
kubectl -n prod describe deployment web1
```

### Step 4: Verify the Update

```bash
# Check current image version
kubectl -n prod get deployment web1 -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

# Verify all pods are running the new image
kubectl -n prod get pods -l app=web-frontend -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'

# Check deployment status
kubectl -n prod get deployment web1
```


### Step 5: Execute Rollback

```bash
# Rollback to previous version
kubectl -n prod rollout undo deployment/web1

# Monitor the rollback progress
kubectl -n prod rollout status deployment/web1

# Alternative: Rollback to specific revision
# kubectl -n prod rollout undo deployment/web1 --to-revision=1
```

### Step 6: Verify Rollback Success

```bash
# Check current image after rollback
kubectl -n prod get deployment web1 -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

# Verify all pods are back to old image
kubectl -n prod get pods -l app=web-frontend -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'

# Check rollout history
kubectl -n prod rollout history deployment/web1

# Verify all replicas are ready
kubectl -n prod get deployment web1
```

---

### 📊 Understanding the Configuration

**maxUnavailable: 0%**
- Ensures no pods are taken down during update
- New pods must be ready before old ones are terminated
- Guarantees zero downtime for users

**maxSurge: 5%**
- Allows maximum 5% extra pods during rollout
- For 10 replicas: 0.5 rounds up to 1 extra pod
- Controls resource usage during update

**Rollout Process with these settings:**
1. Creates 1 new pod (5% surge)
2. Waits for new pod to be ready
3. Terminates 1 old pod
4. Repeats until all pods updated

---

### ✅ Success Criteria

After completion, you should have:

1. ✅ **Deployment configured** with maxUnavailable=0%, maxSurge=5%
2. ✅ **Image updated** to `stable-perl` version
3. ✅ **Rollout completed** successfully with zero downtime
4. ✅ **Rollback executed** back to `perl` version
5. ✅ **All 10 replicas** running and ready
6. ✅ **Rollout history** showing both update and rollback revisions



---


</details>



