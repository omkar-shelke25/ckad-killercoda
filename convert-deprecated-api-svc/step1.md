# Fix deprecated API Deployment Conversion and Service Exposure

## Scenario

A Deployment manifest is present at `/blackhole/gargantuan-deprecated.yaml`.  
This manifest was created for Kubernetes v1.30 using a deprecated API.
Your cluster is running Kubernetes v1.33 where that API version is no longer supported.

The application defined in this Deployment serves an HTML file that has been placed at `/blackhole/gargantua-scifi.html`.  
The HTML must be mounted into the nginx container using a ConfigMap.  
The container image is `public.ecr.aws/nginx/nginx:latest`, and the application listens on port 80.

## Tasks

1. **Convert the manifest** at `/blackhole/gargantuan-deprecated.yaml` to a supported API version for Kubernetes v1.33 (using the official `kubectl convert` plugin — install it if necessary).

2. **Fix the Deployment manifest** to include a proper `.spec.selector.matchLabels` that matches the pod template labels.

3. **Apply the corrected Deployment** in the namespace `interstellar`.

4. **Create a NodePort Service** named `gargantuan-svc` in namespace `interstellar` that exposes the application on port 80 and maps it to NodePort `33000`.

5. **Verify that**:

   * The Deployment exists and its pods are in the Running state.
   * The pods are using the correct image.
   * The Service `gargantuan-svc` is exposing NodePort `33000`.
   * The file `/usr/share/nginx/html/gargantua-scifi.html` exists inside a running pod.
