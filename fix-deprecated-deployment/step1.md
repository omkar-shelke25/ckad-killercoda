# 🔧 CKAD: Fix API Deprecation Issues in Legacy Deployment

Your team of engineers has been trying to deploy the `legacy-app` but they're encountering errors due to deprecated API versions in the YAML file. The deployment is failing and needs to be fixed before it can be successfully deployed.

## 🎯 Task

The YAML file at `/opt/course/api-fix/legacy-app.yaml` contains a deployment configuration that uses deprecated API versions. Fix the API deprecation issues so the engineers can successfully deploy the application.

<details>
<summary>🔍 Click to view the complete solution</summary>


## 🔍 Steps to Complete

1. **Check what's wrong with the current YAML:**
   ```bash
   cat /opt/course/api-fix/legacy-app.yaml
   ```

2. **Find the correct API version:**
   ```bash
   kubectl api-resources | grep deployment
   ```

3. **Fix the YAML file and deploy:**
   ```bash
   # Edit the file to use the correct API version
   # Then apply it
   kubectl apply -f /opt/course/api-fix/legacy-app.yaml
   ```

4. **Verify the deployment:**
   ```bash
   kubectl get deployment legacy-app -n migration
   kubectl get pods -n migration
   ```
</details>


