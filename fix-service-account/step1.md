# CKAD: Fix Payment API ServiceAccount


In the namespace `payment`, the Deployment **`payment-api`** is running with pods that use the **default ServiceAccount**.  

These pods must instead use the dedicated ServiceAccount `payment-sa`, which already has the correct RBAC permissions to access secrets.

---

### Task
Update the Deployment `payment-api` in the `payment` namespace to use the ServiceAccount `payment-sa`.


## Try it yourself first!

<details><summary>✅ Solution (expand to view)</summary>

```bash
kubectl -n payment set serviceaccount deployment/payment-api payment-sa
```
```bash
#Alternative Step
k -n payment edit deployment/payment-api
# edit the Deployment to include serviceAccountName: payment-sa
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-api
  namespace: payment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: payment-api
  template:
    metadata:
      labels:
        app: payment-api
    spec:
      serviceAccountName: payment-sa   # ✅ Fixed here
      containers:
      - name: payment-api
        image: nginx:1.25.3
        command: ["/bin/sh","-c","echo starting payment api && sleep 3600"]
```

</details>
