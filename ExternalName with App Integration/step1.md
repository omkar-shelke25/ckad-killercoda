
📦 **Kubernetes Challenge**
🌐 **Networking – ExternalName Service**

🔹 Question: ExternalName with App Integration

In the store namespace, a frontend Pod (frontend-pod) is deployed that tries to reach its backend using the DNS name backend-service.

The backend, however, is not running inside the cluster. It is hosted at the external domain backend.prod.internal.

Your task:

* Create a Service named backend-service in the store namespace.
* The service should be of type ExternalName.
* It should resolve DNS queries to backend.prod.internal.
* Ensure that the Pod frontend-pod can reach this external backend via the service DNS backend-service.store.svc.cluster.local.


---

## **Solution**

Try to solve this yourself first, then check the solution if needed:

<details>
<summary>Click to view Solution</summary>

### **Step 1: Create the ExternalName Service**

```bash
kubectl create service externalname backend-service \
  --external-name=backend.prod.internal \
  -n store
```

**Alternative Method: Using YAML**
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: store
spec:
  type: ExternalName
  externalName: backend.prod.internal
EOF
```

### **Step 2: Verify the Solution**
```bash
# Check if service was created
kubectl get svc -n store

# Describe the service
kubectl describe svc backend-service -n store

# Test DNS resolution
kubectl exec -n store frontend-pod -- nslookup backend-service.store.svc.cluster.local
```

</details>
