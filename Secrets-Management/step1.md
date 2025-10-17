
# Database Credentials Security Challenge

There is a pod called `db-client` in the `banking` namespace.
The Pod currently has plain environment variables for database credentials.

**Task:**
- Find the plain environment variables used for the database inside the Pod.
- Move those credentials into a Secret named `db-secret` in the `banking` namespace.
- Then, update the `db-client` pod to use the values from the Secret instead of plain environment variables.
- Make sure the new Pods are running correctly with the updated configuration.

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
  --from-literal=DB_HOST=mysql-service
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



