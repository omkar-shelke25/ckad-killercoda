# ExternalName Service Integration Challenge

## **Question (Weightage: 4)**

A frontend Pod named `frontend-pod` exists in the `store` namespace. It tries to reach its backend using the DNS name `backend-service`. The backend, however, is not running inside the cluster. It is hosted at the external domain `backend.prod.internal`.

### **Task:**

**Create a Service named `backend-service` in the `store` namespace with:**
- Type: ExternalName
- External domain: backend.prod.internal

**Ensure that the Pod `frontend-pod` can reach this external backend via the service DNS `backend-service.store.svc.cluster.local`.**

---

## **Solution**

Try to solve this yourself first, then check the solution if needed:

<details>
<summary>Click to view Solution</summary>

### Theory On Externam Name

**Notes On External Name**

An **ExternalName Service** is a special Service that works only as a **DNS alias**, with no Pods or selectors.
It redirects traffic at the DNS level to an external hostname — no proxying, no cluster IP.

Flow: `frontend-pod → backend-service.store.svc.cluster.local → CNAME → backend.prod.internal → external server`.
You can check if the Pod has any URL environment variable with:

```bash
kubectl exec -it frontend-pod -n store -- printenv | grep URL
```
----

### Imperative and Yaml Solution
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

**Verify the Solution**
```bash
# Check if service was created
kubectl get svc -n store

# Describe the service
kubectl describe svc backend-service -n store

# Test DNS resolution
kubectl exec -n store frontend-pod -- nslookup backend-service.store.svc.cluster.local
```

</details>
