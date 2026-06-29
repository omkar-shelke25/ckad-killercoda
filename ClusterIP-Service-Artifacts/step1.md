# CKAD: Create a ClusterIP Service with Port Redirect

### 📚 Reference Docs
- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Connecting Applications with Services](https://kubernetes.io/docs/tutorials/services/connect-applications-service/)
- [kubectl expose](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_expose/)

---

## 🧩 Scenario

Team Pluto needs an internal nginx Pod exposed via a ClusterIP Service with a port redirect. Once running, you will verify connectivity from a temporary client Pod and save both the HTTP response and the nginx access logs to the local filesystem.

---

## 📋 Tasks

All resources must be created in the **`pluto`** namespace.

**1.** Create a Pod named **`project-plt-6cc-api`** with:
- Image: `nginx:1.17.3-alpine`
- Label: `project=plt-6cc-api`

**2.** Create a ClusterIP Service named **`project-plt-6cc-svc`** with:
- Port: `3333`
- TargetPort: `80`
- Protocol: `TCP`
- Selector must match the Pod label above

**3.** From a temporary client Pod in the `pluto` namespace, make an HTTP request to `http://project-plt-6cc-svc:3333/` and save the response body to:
```
/opt/course/10/service_test.html
```

**4.** Save the nginx access logs from Pod `project-plt-6cc-api` to:
```
/opt/course/10/service_test.log
```

---

## ✅ Expected Result

```bash
# Pod is running
kubectl get pod project-plt-6cc-api -n pluto

# Service is configured correctly
kubectl get svc project-plt-6cc-svc -n pluto

# Artifacts exist and are non-empty
cat /opt/course/10/service_test.html   # should show nginx HTML
cat /opt/course/10/service_test.log    # should show GET / request
```

---

<details>
<summary>💡 Solution (try it yourself first!)</summary>

**Step 1 — Create the Pod**

```bash
kubectl -n pluto run project-plt-6cc-api \
  --image=nginx:1.17.3-alpine \
  --labels=project=plt-6cc-api \
  --restart=Never
```

**Step 2 — Expose it as a ClusterIP Service**

```bash
kubectl -n pluto expose pod project-plt-6cc-api \
  --name=project-plt-6cc-svc \
  --type=ClusterIP \
  --port=3333 \
  --target-port=80 \
  --protocol=TCP
```

**Step 3 — Save the HTTP response to service_test.html**

Run a temporary client Pod and fetch the Service:

```bash
kubectl -n pluto run client --image=busybox:latest \
  --restart=Never \
  --rm -it \
  -- wget -qO- http://project-plt-6cc-svc:3333 > /opt/course/10/service_test.html
```

Verify it looks correct:

```bash
cat /opt/course/10/service_test.html
```

**Step 4 — Save nginx access logs to service_test.log**

```bash
kubectl -n pluto logs project-plt-6cc-api > /opt/course/10/service_test.log
```

Verify the GET request was logged:

```bash
cat /opt/course/10/service_test.log
```

</details>
