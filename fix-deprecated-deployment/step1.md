# 🔧 CKAD: Identify and Fix API Deprecation Issues

Your DevOps team has discovered that the `legacy-app` deployment in the `migration` namespace is using deprecated API versions. This is causing warnings and may lead to failures in future Kubernetes versions.

## 🎯 Task Requirements

Fix API deprecation issues in existing deployment:
* Deployment `legacy-app` in namespace `migration` uses deprecated API version
* Update to current stable API version  
* Ensure deployment maintains same functionality
* Verify the deployment is using supported API version

## 📂 Files Location
- Deployment YAML: `/opt/course/api-fix/legacy-app.yaml`

<details>
<summary>🔍 Click to view the complete solution</summary>

## 🔍 Investigation Steps

1. **Check current deployment status:**
   ```bash
   kubectl get deployment legacy-app -n migration
   kubectl describe deployment legacy-app -n migration
   ```

2. **Examine the current YAML:**
   ```bash
   cat /opt/course/api-fix/legacy-app.yaml
   ```

3. **Check for deprecation warnings:**
   ```bash
   kubectl apply -f /opt/course/api-fix/legacy-app.yaml --dry-run=client
   kubectl apply -f /opt/course/api-fix/legacy-app.yaml --dry-run=server
   ```

4. **Find the correct API version:**
   ```bash
   kubectl api-resources | grep deployment
   kubectl explain deployment --api-version=apps/v1
   ```

## 🛠️ Fix Implementation

1. **Update the API version** in the deployment YAML
2. **Apply the updated deployment:**
   ```bash
   kubectl apply -f /opt/course/api-fix/legacy-app.yaml
   # or use replace if needed:
   kubectl replace -f /opt/course/api-fix/legacy-app.yaml --force
   ```

3. **Verify the fix:**
   ```bash
   kubectl get deployment legacy-app -n migration -o yaml | grep apiVersion
   kubectl rollout status deployment/legacy-app -n migration
   ```

## 📝 Documentation

Update `/opt/course/api-fix/changes-documented.md` with:
- The deprecated API version you found
- The current API version you updated to
- Commands used for verification
- Any additional changes needed

---

## 💡 Complete Solution

### Step 1: Identify the Issue
```bash
# Check current deployment
kubectl get deployment legacy-app -n migration
cat /opt/course/api-fix/legacy-app.yaml | grep apiVersion

# The deployment uses deprecated extensions/v1beta1
```

### Step 2: Find Correct API Version
```bash
# Check available API versions for Deployment
kubectl api-resources | grep deployment
# Output shows: deployments, deploy, apps/v1
```

### Step 3: Update the YAML
```bash
# Edit the deployment file
sed -i 's/extensions\/v1beta1/apps\/v1/' /opt/course/api-fix/legacy-app.yaml
```

### Step 4: Apply the Fix
```bash
# Apply the updated deployment
kubectl apply -f /opt/course/api-fix/legacy-app.yaml

# Or if needed, force replace
kubectl replace -f /opt/course/api-fix/legacy-app.yaml --force
```

### Step 5: Verify the Fix
```bash
# Check the deployment is using correct API version
kubectl get deployment legacy-app -n migration -o yaml | head -5

# Verify deployment is healthy
kubectl rollout status deployment/legacy-app -n migration
kubectl get pods -n migration -l app=legacy-app
```

### Updated YAML (Fixed Version):
```yaml
apiVersion: apps/v1  # Updated from extensions/v1beta1
kind: Deployment
metadata:
  name: legacy-app
  namespace: migration
  labels:
    app: legacy-app
    version: v1.0.0
    environment: production
spec:
  replicas: 2
  selector:
    matchLabels:
      app: legacy-app
  template:
    metadata:
      labels:
        app: legacy-app
        version: v1.0.0
    spec:
      containers:
      - name: web
        image: nginx:1.20
        ports:
        - containerPort: 80
          name: http
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
        env:
        - name: APP_VERSION
          value: "1.0.0"
        - name: ENVIRONMENT
          value: "production"
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 20
      restartPolicy: Always
```

### Documentation Template:
```markdown
# API Deprecation Fix Documentation

## Changes Made:

### Before (Deprecated):
- API Version: extensions/v1beta1
- Issues Found: Deprecated API version, may not be supported in future K8s versions

### After (Current):
- API Version: apps/v1
- Changes Applied: Updated apiVersion from extensions/v1beta1 to apps/v1

### Verification:
- [x] Deployment is running with current API version
- [x] All functionality is maintained  
- [x] No deprecation warnings

## Commands Used:
kubectl apply -f /opt/course/api-fix/legacy-app.yaml
kubectl rollout status deployment/legacy-app -n migration
kubectl get deployment legacy-app -n migration -o yaml | head -5
```

</details>
