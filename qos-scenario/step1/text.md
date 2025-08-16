# Question (Weightage: 8)

## Context
You are working as a DevOps engineer for a space exploration company. The **mars** namespace hosts a microservice that needs to run with a burstable Quality of Service (QoS) class to optimize resource usage while allowing bursts in load.

Your manager initially asked you to deploy the service, and now — after some time in production — they want a quick way to check all Pods in the mars namespace along with their QoS class for monitoring purposes.

## Tasks

### Task 1 (Weightage: 2 points)
In the **mars** namespace, create a Deployment named **app-server** using image **nginx:1.21** with **3** replicas.

### Task 2 (Weightage: 2 points)
Configure resource requests and limits so that the Pods run with QoS class: **Burstable**.

**Resource specifications:**
- CPU request: **200m**
- Memory request: **128Mi** 
- CPU limit: **500m**
- Memory limit: **256Mi**

### Task 3 (Weightage: 4 point)
Create a script file **/opt/mars/qos-check.sh** that lists all Pod names and their QoS class in the **mars** namespace.

**Required output format:**
NAME   QOS
pod1   Burstable
pod2   Burstable
pod3   Burstable
