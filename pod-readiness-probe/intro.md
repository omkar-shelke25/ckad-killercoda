# CKAD Simulator

**Solve this question on instance:** `ssh ckad5601` (example)

Create a single **Pod** named **`pod6`** in **Namespace `default`** of image **`busybox:1.31.0`**.  
The **Pod** should have a **readiness-probe** executing `cat /tmp/ready`. It should **initially wait 5** and **periodically wait 10 seconds**. This will set the container **ready only if the file `/tmp/ready` exists**.

The **Pod** should run the command `touch /tmp/ready && sleep 1d`, which will create the necessary file to be ready and then idle. 

Click **Start Scenario** to begin.

