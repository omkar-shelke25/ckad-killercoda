# Externalize Configuration (ConfigMap + Secret)

A service in the `apps` namespace must stop baking configuration into images.  
Provide non‑sensitive settings via **ConfigMap**, sensitive values via **Secret**, and consume both as **environment variables** in a Pod.

Click **Start Scenario** to begin.
