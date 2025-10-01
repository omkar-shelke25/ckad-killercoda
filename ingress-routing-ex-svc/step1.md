# CKAD: Fix Ingress Routing with ExternalName Service

A cloud-native startup has deployed an **Ingress** in the `exam-app` namespace to route API traffic to an external service. However, users are currently experiencing **503 errors** when accessing the API endpoint because the backend Service was never created.

The Ingress resource named **api-ingress** is configured to route traffic to a Service named `external-api`, but this Service does not exist yet.

### Your Tasks

1. Create a **Service** named `external-api` in the `exam-app` namespace.
   - The Service type must be **ExternalName**.
   - It should point to the DNS hostname: `httpbin.org`.
2. Ensure the Ingress is able to forward traffic correctly to the external backend via this Service.
3. Verify that accessing the Ingress no longer returns a **503 error**.
4. Ingress URL stored in `cat /tmp/ingress_url.txt`


> Wait 1–2 minutes for setup, then check the ingress URL with `cat /tmp/ingress_url.txt`


> curl -i http://localhost:NodePort/api/get #You should see a 200 OK response 


---

# Try it yourself first!

<details><summary>✅ Solution For Your Reference</summary>

```bash
# Method 1: Using kubectl create command (Quick!)
kubectl -n exam-app create service externalname external-api --external-name httpbin.org

# Method 2: Using YAML
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: external-api
  namespace: exam-app
spec:
  type: ExternalName
  externalName: httpbin.org
EOF

# Verify the Service was created
kubectl -n exam-app get svc external-api
kubectl -n exam-app describe svc external-api

# Test the Ingress endpoint (should work now!)
INGRESS_URL=$(cat /tmp/ingress_url.txt)
curl -i ${INGRESS_URL}get

# You should see a 200 OK response from httpbin.org
# The response will contain JSON data about the request
```

**Expected behavior after creating the Service**:
- The Ingress will successfully route traffic to httpbin.org
- You'll receive a 200 OK response instead of 503
- The response body will contain JSON data from httpbin.org

</details>
