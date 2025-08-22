# Secure Nginx on Port 80

You will deploy Nginx on port 80 **without** running as root.  
Use securityContext settings and only the **NET_BIND_SERVICE** capability so the container can bind to a privileged port safely.

Click **Start Scenario** to begin.
