# Database Credentials Security Challenge

## **Question (Weightage: 7)**

A Deployment named `db-client` exists in the `banking` namespace. It currently uses hardcoded environment variables for database credentials.

### **Task:**

**Create a Secret named `db-secret` in the `banking` namespace with:**
- DB_USER=bankadmin
- DB_PASS=securePass123
- DB_HOST=mysql-service

**Update the `db-client` Deployment so that the environment variables `DB_USER`,`DB_PASS` & `DB_HOST` are loaded from the Secret instead of plain values.**

**Ensure the updated Pods are running with the new configuration.**



---

## **Solution**

Try to solve this yourself first, then check the solution if needed:

<details>
<summary>Click to view Solution</summary>

### **Step 1: Create the Secret**
```bash
kubectl create secret generic db-secret \
  --from-literal=DB_USER=bankadmin \
  --from-literal=DB_PASS=securePass123 \
  -n banking
```

### **Step 2: Update the Deployment**
```bash
# Method 1: Using kubectl edit
kubectl edit deployment db-client -n banking
# Replace the env section with:
#        env:
#        - name: DB_USER
#          valueFrom:
#            secretKeyRef:
#              name: db-secret
#              key: DB_USER
#        - name: DB_PASS
#          valueFrom:
#            secretKeyRef:
#              name: db-secret
#              key: DB_PASS
#        - name: DB_HOST
#          valueFrom:
#            secretKeyRef:
#              name: db-secret
#              key: DB_HOST
               
                
                   
```

**Alternative Method 2: Apply new YAML**
```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db-client
  namespace: banking
spec:
  replicas: 1
  selector:
    matchLabels:
      app: db-client
  template:
    metadata:
      labels:
        app: db-client
    spec:
      containers:
      - name: db-client
        image: busybox:latest
        command: ['sleep', '3600']
        env:
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: DB_USER
        - name: DB_PASS
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: DB_PASS
        - name: DB_HOST
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: DB_HOST
EOF
```

### **Step 3: Verify the Solution**
```bash
# Check rollout status
kubectl rollout status deployment/db-client -n banking

# Verify pods are running
kubectl get pods -n banking

# Check environment variables
POD_NAME=$(kubectl get pods -n banking -l app=db-client -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n banking $POD_NAME -- env | grep DB_
```

</details>



