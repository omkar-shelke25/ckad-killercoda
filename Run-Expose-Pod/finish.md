# 🎉 Nicely done!

You created a Pod and exposed it imperatively, with correct labels and ports:

- Pod: `data-mining` (image `httpd:trixie`, containerPort 80, label `app=crypto-mining`)
- Service: `data-mining` (ClusterIP, port 80) pointing to the Pod
- Endpoints populated ✅

**Exam tip:** If the prompt hints at a quick test or one-off Pod, think `kubectl run --restart=Never` and (optionally) `--expose`. Verify endpoints to ensure the Service selects your Pod.
