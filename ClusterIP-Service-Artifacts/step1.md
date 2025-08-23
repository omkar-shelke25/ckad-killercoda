# Challenge: Team Pluto – Internal Service with Port Redirect

Create a Pod called **project-plt-6cc-api** in the **pluto** namespace using the image **nginx:1.17.3-alpine**.  
The Pod should be labelled with **project=plt-6cc-api**.

Create a ClusterIP Service called **project-plt-6cc-svc** in the **pluto** namespace.  
The service should use tcp port redirection of **3333:80**

From a temporary client Pod in the same namespace, make an HTTP request to  
**http://project-plt-6cc-svc:3333/**

- Save the response body to:  **/opt/course/10/service_test.html**
- Save the logs from Pod **project-plt-6cc-api** to:  /opt/course/10/service_test.log


## **Solution**

Try to solve this yourself first, then check the solution if needed:

<details>
<summary>Click to view Solution</summary>

# 1) Pod with label project=plt-6cc-api
```bash
kubectl -n pluto run project-plt-6cc-api \
  --image=nginx:1.17.3-alpine \
  --labels=project=plt-6cc-api \
  --restart=Never
```


# 2) ClusterIP Service: port 3333 -> targetPort 80/TCP
```bash
kubectl -n pluto expose pod project-plt-6cc-api \
  --name=project-plt-6cc-svc \
  --type=ClusterIP \
  --port=3333 \
  --target-port=80 \
  --protocol=TCP
```


3) **Functional check & artifacts**
- Run a temporary client Pod and directly fetch the Service:
  ```bash
  kubectl -n pluto run tmp-client --rm -i --restart=Never --image=busybox:1.36 \
    -- wget -qO- http://project-plt-6cc-svc:3333/ > /opt/course/10/service_test.html
  ```
# 4) Save backend pod logs to host
```bash
kubectl -n pluto logs project-plt-6cc-api > /opt/course/10/service_test.log
```
</details>
