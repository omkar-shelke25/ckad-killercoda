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

**3.** From a temporary client Pod in the `pluto` namespace, make an HTTP request (via `curl` or `wget`) to `http://project-plt-6cc-svc:3333/` and save the response body to:
```
/opt/course/10/service_test.html
```
The file must contain **only** the raw nginx HTML response — nothing else added (no kubectl messages, prompts, or other extra output mixed in).

> 💡 Tip: Don't use `kubectl run ... --rm`. When the Pod deletes itself automatically, kubectl can print a line like `pod "client" deleted` right into your saved file — and in some cases that's *all* that ends up in the file, with no actual HTTP response at all (no error shown, it just silently fails). Instead, create the client Pod separately first, then use `kubectl exec` to send the request and save the output. Once you've checked the file looks correct, delete the Pod with its own separate command — that way the deletion message never gets mixed into your saved file.

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

⚠️ **Avoid `kubectl run ... --rm -i ...`.** In practice this can fail silently: if the attach/stream to the Pod doesn't complete properly (slow node, brief network hiccup, pod exiting before the watch attaches), your redirected file ends up containing **only** kubectl's `pod "client" deleted` cleanup message — no actual HTTP response at all, with no error shown. Use the separate Pod + `exec` method below instead; it has no streaming/attach race to fail.

**Method (recommended) — separate Pod + `exec`**

Create the client Pod on its own first and keep it running (no `--rm`):
```bash
kubectl -n pluto run client --image=curlimages/curl --restart=Never -- sleep 3600
kubectl -n pluto wait --for=condition=Ready pod/client --timeout=60s
```

`exec` into it to run the request — this is a plain synchronous call, not a stream attach, so it doesn't have the same failure mode:
```bash
kubectl -n pluto exec client -- curl -s http://project-plt-6cc-svc:3333 > /opt/course/10/service_test.html
```
(If using a busybox image instead: `kubectl -n pluto exec client -- wget -qO- http://project-plt-6cc-svc:3333 > /opt/course/10/service_test.html`)

Check the file looks right **before** deleting the Pod:
```bash
cat /opt/course/10/service_test.html
```
If it's empty or wrong, the Pod is still alive (`sleep 3600`) — just retry the `exec` line above, no need to recreate anything.

Once it looks correct, delete the Pod as its own, separate, unredirected command — so its "pod deleted" message only prints to your terminal, never into the file:
```bash
kubectl -n pluto delete pod client
```

**One-line version of the same (recommended) method:**
```bash
kubectl -n pluto run client --image=busybox:latest --restart=Never -- sleep 3600 && kubectl -n pluto wait --for=condition=Ready pod/client --timeout=60s && kubectl -n pluto exec client -- wget -qO- http://project-plt-6cc-svc:3333 > /opt/course/10/service_test.html && kubectl -n pluto delete pod client
```
This chains the same four steps with `&&`. The `>` redirect only applies to the `exec` command in the middle, so the pod's "deleted" message still only prints to your terminal — it never touches the file.

**Alternative — one-liner with `--rm`** (faster, but riskier — see warning above)

```bash
kubectl -n pluto run client --image=busybox:latest --restart=Never --rm -i \
  --command -- wget -qO- http://project-plt-6cc-svc:3333 > /opt/course/10/service_test.html
```

**Example of a common mistake with this method** — your file might end up looking like this:
```
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>
<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>
<p><em>Thank you for using nginx.</em></p>
</body>
</html>
pod "client" deleted from pluto namespace   ⬅️ NOT part of the HTML — kubectl's own cleanup message leaked in. Must be removed.
```
Everything through `</html>` is correct nginx output. The last line is **not** part of `index.html` — strip it:
```bash
sed -i '/pod .* deleted/d' /opt/course/10/service_test.html
```

After running this, always check the file actually contains the HTML and not just a deletion message:
```bash
cat /opt/course/10/service_test.html
```
If it only shows `pod "client" deleted from pluto namespace`, the request itself failed silently — delete the leftover file and switch to the `exec` method above:
```bash
rm -f /opt/course/10/service_test.html
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
