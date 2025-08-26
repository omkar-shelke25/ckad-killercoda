# Ingress with a Default Backend (Custom 404) — namespace: `main`

Your company runs a public marketing site at **`main.example.com`**. Marketing wants unknown hosts/paths to show a **custom error page** instead of the default 404.  
Platform engineers decide to add a **default backend** in the cluster’s Ingress so that anything **not** matching `main.example.com` gets routed to a small app that renders a friendly 404/“landing” page.

Click **Start Scenario** to begin.

