# Mars Microservice Deployment and Monitoring

## Question (Weightage: 8)

### Context
You are working as a DevOps engineer for a space exploration company. The **`mars`** namespace hosts a microservice that needs to run with a burstable Quality of Service (QoS) class to optimize resource usage while allowing bursts in load.

Your manager initially asked you to deploy the service, and now — after some time in production — they want a quick way to check all Pods in the mars namespace along with their QoS class for monitoring purposes.

### Tasks

#### Task 1 (Weightage: 2)
In the **`mars`** namespace, create a Deployment named **`app-server`** using image **`nginx:1.21`** with **`3`** replicas.

#### Task 2 (Weightage: 2)
Configure resource requests and limits so that the Pods run with QoS class: **`Burstable`**.

**Resource specifications:**
- CPU request: **`200m`**
- Memory request: **`128Mi`**
- CPU limit: **`500m`**
- Memory limit: **`256Mi`**

#### Task 3 (Weightage: 4)
Create a script file **`/opt/mars/qos-check.sh`** that lists all Pod names and their QoS class in the **`mars`** namespace.

**Required output format:**

| NAME  | QOS       |
|-------|-----------|
| pod1  | Burstable |
| pod2  | Burstable |
| pod3  | Burstable |

### Solution

<details>
<summary>Click to view Solution</summary>


#### Deployment Configuration
The `app-server-deployment.yaml` file defines a Deployment in the `mars` namespace with 3 replicas using the `nginx:1.21` image. Resource requests and limits are set to ensure the **Burstable** QoS class.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-server
  namespace: mars
spec:
  replicas: 3
  selector:
    matchLabels:
      app: app-server
  template:
    metadata:
      labels:
        app: app-server
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        resources:
          requests:
            cpu: "200m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "256Mi"
```

**Apply the Deployment:**
```bash
kubectl apply -f app-server-deployment.yaml
```

#### QoS Check Script
The `qos-check.sh` script, saved as `/opt/mars/qos-check.sh`, lists all Pods in the `mars` namespace with their QoS class.

```bash
echo 'kubectl get pods -n mars -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass' > /opt/mars/qos-check.sh
```

**Run the Script:**
1. Save the script to `/opt/mars/qos-check.sh`.
2. Make it executable: `chmod +x /opt/mars/qos-check.sh`.
3. Execute: `/opt/mars/qos-check.sh`.

This will output the Pod names and their QoS classes in the specified format.


</details>
