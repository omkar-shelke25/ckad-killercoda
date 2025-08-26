# Ingress Path Rewrite (/app → /) — namespace: `legacy`


You have a legacy application that **expects traffic at `/`** (root). Marketing wants to publish it at **`https://legacy.example.com/app`** without changing the app code or image.  
Solution: configure an **Ingress** to match `/app` and **rewrite** the request path to `/` **before** sending it to the service.

Click **Start Scenario** to begin.
