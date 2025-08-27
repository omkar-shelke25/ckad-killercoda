# CKAD: Secrets into an existing Pod (namespace: moon)

You need to make changes on an existing Pod in Namespace moon called **secret-handler**. Create a new Secret secret1 which contains **user=test** and **pass=pwd**. 

The Secret’s content should be available in Pod secret-handler as environment variables **SECRET1_USER** and **SECRET1_PASS**. The yaml for Pod secret-handler is available at **/opt/course/14/secret-handler.yaml**.

There is existing yaml for another Secret at **/opt/course/14/secret2.yaml**; create this Secret and mount it inside the same Pod at **/tmp/secret2**. Your changes should be saved under **/opt/course/14/secret-handler-new.yaml**. 

Both Secrets should only be available in Namespace **moon**.

---


<details><summary>✅ Solution (expand to view)</summary>

```bash
# 1) Create secret1 in namespace moon (user=test, pass=pwd)
kubectl -n moon create secret generic secret1 \
  --from-literal=user=test \
  --from-literal=pass=pwd

# 2) Create the provided secret2 from YAML
kubectl -n moon apply -f /opt/course/14/secret2.yaml

# 3) Start from the raw Pod YAML and save a new file to edit
cp /opt/course/14/secret-handler.yaml /opt/course/14/secret-handler-new.yaml

# 4) Edit /opt/course/14/secret-handler-new.yaml:
#   - add env vars from secret1
#   - add volume + volumeMount for secret2 at /tmp/secret2
# Reference YAML is shown in the next section.

# 5) Recreate/replace the Pod with the new spec
kubectl -n moon delete pod secret-handler --ignore-not-found
kubectl -n moon apply -f /opt/course/14/secret-handler-new.yaml
kubectl -n moon wait --for=condition=Ready pod/secret-handler --timeout=120s
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-handler
  namespace: moon
  labels:
    app: secret-handler
spec:
  containers:
  - name: app
    image: busybox:1.37.0
    command: ["/bin/sh","-c","sleep 1d"]
    env:
    - name: SECRET1_USER
      valueFrom:
        secretKeyRef:
          name: secret1
          key: user
    - name: SECRET1_PASS
      valueFrom:
        secretKeyRef:
          name: secret1
          key: pass
    volumeMounts:
    - name: secret2-vol
      mountPath: /tmp/secret2
      readOnly: true
  volumes:
  - name: secret2-vol
    secret:
      secretName: secret2

# Save your final file at /opt/course/14/secret-handler-new.yaml and apply it.

```
</details> 
