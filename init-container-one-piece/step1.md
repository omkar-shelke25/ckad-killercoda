# CKAD: Deploy Strawhat Crew with InitContainer

### Reference Docs
- [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Create ConfigMap from File](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#create-a-configmap-from-a-file)
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [NodePort Services](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport)

---

## Context

In the `one-piece` namespace, deploy an Nginx application serving a custom HTML page using a ConfigMap and an InitContainer.

Mounting the ConfigMap directly into `/usr/share/nginx/html` would wipe out anything else in that directory. Instead, use an InitContainer to copy just the file you need into a shared `emptyDir` volume — that volume is tied to the **Pod's** lifetime, so it survives after the InitContainer exits, ready for the main container to serve from.

## Task

1. **ConfigMap** `strawhat-cm` — created from `/one-piece/index.html`

2. **Deployment** `strawhat-deploy`:
   - Replicas: `1`, selector: `app=strawhat`
   - Container `strawhat-nginx`: image `public.ecr.aws/nginx/nginx:latest`, port `80`
   - InitContainer `init-copy`: image `public.ecr.aws/docker/library/busybox:latest` — copies `index.html` into `/usr/share/nginx/html/` before the main container starts
   - Volumes:
     - A ConfigMap-backed volume, mounted into the InitContainer (so it can read `index.html`)
     - An `emptyDir` volume, mounted into **both** the InitContainer and the main container at `/usr/share/nginx/html` (this is what carries the copied file across)

3. **Service** `strawhat-svc`: type `NodePort`, port `80`, nodePort `32100`, selector `app=strawhat`

4. From the terminal navigation (top right), select the relevant item and confirm the page loads on port `32100`.

   ![One Piece terminal screenshot](https://github.com/user-attachments/assets/56ec5f6a-e274-4494-8cc4-9b038073e77e)

---

## Solution

Try it yourself first, then check the solution if needed:

<details>
<summary>Click to view Solution</summary>

### Step 1: Create the ConfigMap from file

```bash
kubectl create configmap strawhat-cm \
  --from-file=/one-piece/index.html \
  -n one-piece
```

> `--from-file` uses the file's basename as the data key, so this produces a ConfigMap with key `index.html` — exactly what the InitContainer will look for.

### Step 2: Create the Deployment with the InitContainer

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: strawhat-deploy
  namespace: one-piece
spec:
  replicas: 1
  selector:
    matchLabels:
      app: strawhat
  template:
    metadata:
      labels:
        app: strawhat
    spec:
      initContainers:
      - name: init-copy
        image: public.ecr.aws/docker/library/busybox:latest
        command: ['sh', '-c', 'cp /config/index.html /usr/share/nginx/html/']
        volumeMounts:
        - name: config-volume
          mountPath: /config
        - name: html-volume
          mountPath: /usr/share/nginx/html
      containers:
      - name: strawhat-nginx
        image: public.ecr.aws/nginx/nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html-volume
          mountPath: /usr/share/nginx/html
      volumes:
      - name: config-volume
        configMap:
          name: strawhat-cm
      - name: html-volume
        emptyDir: {}
EOF
```

> Both containers mount the same volume, `html-volume`, but only the InitContainer also mounts `config-volume` (that's where it reads the ConfigMap file from). The InitContainer copies the file into `html-volume`, then exits. Right after, the main container starts and just serves whatever's already sitting in `html-volume`.
>
> Where does that file actually live? `html-volume` is an `emptyDir`, which means Kubernetes creates a plain empty folder on the node's disk for this Pod to use — **not RAM**. (You'd only get RAM-backed storage if the volume definition explicitly set `emptyDir: { medium: Memory }`, which this solution doesn't.) That folder is tied to the Pod, not to any single container in it, so when the InitContainer exits, the folder and the file inside it stick around. The main container mounts that same folder a moment later and finds the file waiting for it.

### Step 3: Create the NodePort Service

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: strawhat-svc
  namespace: one-piece
spec:
  type: NodePort
  selector:
    app: strawhat
  ports:
  - port: 80
    targetPort: 80
    nodePort: 32100
EOF
```

### Step 4: Wait for rollout and verify

```bash
kubectl rollout status deployment/strawhat-deploy -n one-piece
curl localhost:32100
```

You should see the rendered HTML page, including the Straw Hat crew database content.

---

#### Other valid ways to get here

This isn't the only correct path — a few things can be done differently and still pass:

- **ConfigMap creation:** `kubectl create configmap --from-file=...` (imperative, shown above) or a full YAML manifest with `data.index.html: |` inline — both produce the same result.
- **Service creation:** the YAML manifest shown above, or `kubectl expose deployment strawhat-deploy --type=NodePort --port=80 --name=strawhat-svc -n one-piece` followed by `kubectl edit svc strawhat-svc -n one-piece` to set `nodePort: 32100` (`kubectl expose` alone can't set a specific NodePort).
- **InitContainer copy command:** `cp /config/index.html /usr/share/nginx/html/`, `cp -r /config/. /usr/share/nginx/html/`, or `cat /config/index.html > /usr/share/nginx/html/index.html` — any of these move the file across correctly.

**One thing that *won't* pass here:** mounting the ConfigMap directly into `/usr/share/nginx/html` (with or without `subPath`) and skipping the InitContainer entirely. It would technically serve the file, but this scenario specifically verifies for an InitContainer named `init-copy` — the point of the exercise is practicing that pattern, not just getting content on screen by the shortest route.

</details>
