# 🔧 CKAD: Create InitContainer with Shared Volume

Last lunch you told your coworker from department Mars Inc how amazing **InitContainers** are. Now he would like to see one in action.

There is a Deployment yaml at **`/opt/course/17/test-init-container.yaml`**. This Deployment spins up a single Pod of image **`nginx:1.17.3-alpine`** and serves files from a mounted volume, which is empty right now.

## 🎯 Task

Create an **InitContainer** named **`init-con`** which also mounts that volume and creates a file **`index.html`** with content **`check this out!`** in the root of the mounted volume.

For this test we ignore that it doesn't contain valid html.

The InitContainer should be using image **`busybox:1.31.0`**. Test your implementation for example using **`curl/wget`** from a temporary **`nginx:alpine`** Pod.

> use replace command to replace existing deployment 'k replace -f <file-name> --force

---

## 💡 Complete Solution

<details>
<summary>🔍 Click to view full YAML solution</summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-init-container
  namespace: default
  labels:
    app: test-init-container
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-init-container
  template:
    metadata:
      labels:
        app: test-init-container
    spec:
      initContainers:
      - name: init-con
        image: busybox:1.31.0
        command: ['sh', '-c', 'echo "check this out!" > /usr/share/nginx/html/index.html']
        volumeMounts:
        - name: web-content
          mountPath: /usr/share/nginx/html
      containers:
      - name: nginx
        image: nginx:1.17.3-alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: web-content
          mountPath: /usr/share/nginx/html
      volumes:
      - name: web-content
        emptyDir: {}
```

```bash
# Test commands
kubectl replace -f /opt/course/17/test-init-container.yaml --force
kubectl expose deployment test-init-container --port=80
kubectl run tmp --restart=Never --rm -i --image=nginx:alpine -- curl test-init-container
```

</details>
