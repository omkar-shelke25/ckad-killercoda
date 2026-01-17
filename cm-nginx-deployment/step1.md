# 🗺️ CKAD: Create ConfigMap for Nginx Configuration

📋 Team Moonpie has a nginx server Deployment called **`web-moon`** in namespace **`moon`**. Someone started configuring it but it was never completed. 

To complete this please create a ConfigMap called **`configmap-web-moon-html`** containing the content of file `/opt/course/15/web-moon.html` under the data key-name **`index.html`**.

The Deployment **`web-moon`** is already configured to work with this ConfigMap and serve the content, for example by using `curl` from a temporary `nginx:alpine` Pod.

## 💡Reference Solution

<details>
<summary>Click to view solution</summary>

```bash
# 1. Check the source file content
cat /opt/course/15/web-moon.html

# 2. Create the ConfigMap with the HTML content
kubectl create configmap configmap-web-moon-html -n moon --from-file=index.html=/opt/course/15/web-moon.html

# 3. Verify ConfigMap was created correctly
kubectl get configmap configmap-web-moon-html -n moon -o yaml

# 4. Check if the Deployment is ready to use the ConfigMap
kubectl rollout restart deployment -n moon web-moon
kubectl get deployment web-moon -n moon
kubectl get pods -n moon

# 5. Test the nginx server (if properly configured)
kubectl run tmp --restart=Never --rm -i --image=nginx:alpine -- curl web-moon.moon.svc.cluster.local
```

**Note**: The Deployment should already be configured to mount this ConfigMap as a volume at the appropriate nginx location (`/usr/share/nginx/html/index.html`).

</details>
