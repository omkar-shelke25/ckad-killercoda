# 🚀 Challenge: Team Pluto – Internal Service with Port Redirect

Create a Pod called **project-plt-6cc-api** in the **pluto** namespace using the image **nginx:1.17.3-alpine**.
The Pod should be labelled with **project=plt-6cc-api**.

Create a ClusterIP Service called **project-plt-6cc-svc** in the **pluto** namespace.
The service should use tcp port redirection of **3333:80**

From a temporary client Pod in the same namespace, make an HTTP request to **http://project-plt-6cc-svc:3333/**

* 💾 Save the response body to `/opt/course/10/service_test.html`, and 📄 service_test.html should contain the HTML code from the Nginx default directory. 🌐 Use wget/curl for that.
* 💾 Save the `wget/curl` logs from the Pod project-plt-6cc-api to `/opt/course/10/service_test.log`.

## ✅ **Solution**

Try to solve this yourself first, then check the solution if needed:

<details> <summary>🔍 Click to view Solution</summary> 

### **1️⃣ Pod with label project=plt-6cc-api**

```bash
kubectl -n pluto run project-plt-6cc-api \
  --image=nginx:1.17.3-alpine \
  --labels=project=plt-6cc-api \
  --restart=Never
```

### **2️⃣ ClusterIP Service: port 3333 -> targetPort 80/TCP**

```bash
kubectl -n pluto expose pod project-plt-6cc-api \
  --name=project-plt-6cc-svc \
  --type=ClusterIP \
  --port=3333 \
  --target-port=80 \
  --protocol=TCP
```

### **3️⃣ Using Wget/Curl**

#### **🔄 Using With curl**

```bash
kubectl -n pluto run tmp --image=nginx -it --rm --restart=Never -- \
curl -s -m5 project-plt-6cc-svc:3333 | head -n25 > /opt/course/10/service_test.html
```

#### **📡 Using With wget**

* Run a temporary client Pod and directly fetch the Service:

```bash
kubectl -n pluto run svc-tester --image=busybox:1.36 --restart=Never --command -- sh -c "sleep 3600"
```

```bash
kubectl -n pluto exec svc-tester -- sh -c "wget -qO- http://project-plt-6cc-svc:3333/" \> /opt/course/10/service_test.html 
```

### **4️⃣ 📜 Save backend pod logs to host**

```bash
# Extract logs from the nginx Pod and save to local file
kubectl -n pluto logs project-plt-6cc-api > /opt/course/10/service_test.log
```

</details>
