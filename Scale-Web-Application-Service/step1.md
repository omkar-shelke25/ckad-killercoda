# 🔧 Scale Deployment and Create NodePort Service

## 📋 Mission Brief

You're preparing the e-commerce platform for a major product launch. The current deployment `ecommerce-frontend-deployment` needs to be scaled and exposed externally to handle the expected traffic surge.

### 🎯 Current State
- **Namespace**: `ecommerce-platform`
- **Deployment**: `ecommerce-frontend-deployment` (currently 2 replicas)
- **Container Port**: 80 (nginx)
- **Status**: Not exposed externally

### 📝 Task Requirements

#### Part 1: Scale and Label the Deployment
Modify the existing deployment `ecommerce-frontend-deployment` to:
- ✅ **Scale to 5 replicas** for high availability
- ✅ **Add label `role: webfrontend`** to the pod template metadata

#### Part 2: Create NodePort Service
Create a new service `ecommerce-frontend-service` that:
- ✅ **Exposes on TCP port 8000**
- ✅ **Maps to pods** with the deployment's selector labels
- ✅ **Uses NodePort type** for external access
- ✅ **Named**: `ecommerce-frontend-service`

---

## 💡 Try It Yourself First!

<details><summary>📋 Complete Solution (Click to expand)</summary>

### Step 1: Scale the Deployment and Add Labels

Edit the existing deployment:

```bash
kubectl -n ecommerce-platform edit deployment ecommerce-frontend-deployment
```

**OR** use kubectl patch:

```bash
# Scale to 5 replicas
kubectl -n ecommerce-platform scale deployment ecommerce-frontend-deployment --replicas=5

# Add the role label to pod template
kubectl -n ecommerce-platform patch deployment ecommerce-frontend-deployment -p '{"spec":{"template":{"metadata":{"labels":{"role":"webfrontend"}}}}}'
```

**OR** apply the complete updated deployment:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ecommerce-frontend-deployment
  namespace: ecommerce-platform
  labels:
    app: ecommerce-frontend
    tier: frontend
    version: v2.1.0
spec:
  replicas: 5
  selector:
    matchLabels:
      app: ecommerce-frontend
  template:
    metadata:
      labels:
        app: ecommerce-frontend
        tier: frontend
        role: webfrontend
    spec:
      containers:
      - name: frontend
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        env:
        - name: ENVIRONMENT
          value: "production"
        - name: SERVICE_NAME
          value: "ecommerce-frontend"
EOF
```

### Step 2: Create the NodePort Service

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: ecommerce-frontend-service
  namespace: ecommerce-platform
  labels:
    app: ecommerce-frontend
    tier: frontend
spec:
  type: NodePort
  ports:
  - port: 8000
    targetPort: 80
    protocol: TCP
  selector:
    app: ecommerce-frontend
EOF
```

### Step 3: Verify the Configuration

Check that everything is working:

```bash
# Verify deployment scaling
kubectl -n ecommerce-platform get deployment ecommerce-frontend-deployment

# Check all pods are running
kubectl -n ecommerce-platform get pods -l app=ecommerce-frontend --show-labels

# Verify service creation
kubectl -n ecommerce-platform get service ecommerce-frontend-service

# Check service endpoints
kubectl -n ecommerce-platform describe service ecommerce-frontend-service
```

### Step 4: Test External Access

Find the NodePort and test access:

```bash
# Get the NodePort
NODE_PORT=$(kubectl -n ecommerce-platform get service ecommerce-frontend-service -o jsonpath='{.spec.ports[0].nodePort}')
echo "Service accessible on NodePort: $NODE_PORT"

# Test access (if curl is available)
curl http://localhost:$NODE_PORT
```

---

### ✅ Success Criteria

After completion, you should have:

1. **Deployment scaled to 5 replicas**
2. **Pod template includes `role: webfrontend` label**
3. **Service named `ecommerce-frontend-service` created**
4. **Service type is NodePort**
5. **Service exposes port 8000 mapping to container port 80**
6. **Service selector matches deployment's pod labels**

</details>

