# 🛠️ Create Namespace and Configure Pod Resource Requests

## 📋 Mission Brief

You need to set up a production-ready nginx web service for **Project One** with guaranteed resource allocation. This ensures the service can handle expected traffic loads without resource contention.

## 🎯 Task Requirements

### Step 1: Create Project Namespace
- ✅ Create namespace **`project-one`**
- ✅ This namespace will isolate Project One resources

### Step 2: Deploy Resource-Configured Pod
- ✅ Pod name: **`nginx-resources`**  
- ✅ Namespace: **`project-one`**
- ✅ Image: **`nginx`**
- ✅ CPU request: **`200m`** (200 milliCPU = 0.2 cores)
- ✅ Memory request: **`1Gi`** (1 Gigabyte)



---

## 💡 Try It Yourself First!

<details><summary>📋 Complete Solution (Click to expand)</summary>


### Method 1: Using YAML Manifest (Production approach)

```bash
# Step 1: Create the namespace
kubectl create namespace project-one

# Step 2: Create and apply pod manifest
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx-resources
  namespace: project-one
  labels:
    app: nginx-resources
    project: project-one
    tier: frontend
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
    resources:
      requests:
        cpu: 200m
        memory: 1Gi
      limits:
        cpu: 500m
        memory: 2Gi
    env:
    - name: PROJECT_NAME
      value: "project-one"
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
EOF
```

### Step 3: Verify the Configuration

```bash
# Check namespace creation
kubectl get namespaces

# Verify pod creation and status
kubectl -n project-one get pods

# Check resource requests are applied
kubectl -n project-one describe pod nginx-resources

# View resource allocation
kubectl -n project-one get pod nginx-resources -o yaml | grep -A 10 resources:
```

### Step 4: Validate Resource Requests

```bash
# Check if pod is scheduled and running
kubectl -n project-one get pod nginx-resources -o wide

# Verify resource requests in pod specification
kubectl -n project-one describe pod nginx-resources | grep -A 5 "Requests:"

# Check node resource usage (if metrics available)
kubectl top nodes
kubectl top pods -n project-one
```

---

### ✅ Success Criteria

After completion, verify:

1. **Namespace `project-one` exists**
2. **Pod `nginx-resources` is running in `project-one` namespace**
3. **Pod uses `nginx` image**
4. **Pod has CPU request of `200m`**
5. **Pod has memory request of `1Gi`**
6. **Pod is scheduled on a node with sufficient resources**

</details>

---

