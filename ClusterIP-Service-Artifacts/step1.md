# Challenge: Team Pluto – Internal Service with Port Redirect

Create a Pod called **project-plt-6cc-api** in the **pluto** namespace using the image **nginx:1.17.3-alpine**.  
The Pod should be labelled with **project=plt-6cc-api**.

Create a ClusterIP Service called **project-plt-6cc-svc** in the **pluto** namespace.  
It should expose port **3333** and forward traffic to **port 80** of the Pod.

From a temporary client Pod in the same namespace, make an HTTP request to  
**http://project-plt-6cc-svc:3333/**

- Save the response body to:  **/opt/course/10/service_test.html**
- Save the logs from Pod **project-plt-6cc-api** to:  /opt/course/10/service_test.log
