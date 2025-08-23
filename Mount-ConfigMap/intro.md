**ConfigMap-as-Files Challenge **

You’re onboarding a web app in the **apps** namespace. The app expects its configuration *as files* mounted inside the container.

**Your mission**
- Create **ConfigMap** `app-config` with:
  - `APP_MODE=production`
  - `APP_PORT=8080`
- Create **Deployment** `web-app` (2 replicas) using image **nginx**.
- Mount the ConfigMap as a **volume** at **/etc/appconfig** so each key appears as an individual file (e.g., `/etc/appconfig/APP_MODE`).

Click **Start Scenario** to begin!
