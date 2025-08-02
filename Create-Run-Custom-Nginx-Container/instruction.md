# 🐳 Create and Run a Custom Nginx Container 

## 🎯 Scenario Goal
You are a DevOps engineer tasked with creating a custom Nginx web server using Docker. Your goal is to build a Docker image from scratch and run a container that serves a custom web page. 

### 📋 Tasks
1. ✍️ **Create the Dockerfile**:
   - Create a `Dockerfile` in the `~/scenario` directory.
   - Use the `nginx:1.27-alpine` base image.
   - Copy a custom `index.html` file to `/usr/share/nginx/html/index.html`.
   - Expose port `80`.
   - Ensure Nginx runs in the foreground.
2. 📜 **Create the index.html File**:
   - Create an `index.html` file in the `~/scenario` directory.
   - Include an `<h1>` tag with the text "Welcome to My Custom Nginx Server".
3. 🛠 **Build the Docker Image**:
   - Build a Docker image named `custom-nginx` using the `Dockerfile`.
   - Ensure you are in the `~/scenario` directory.
4. 🚀 **Run the Container**:
   - Run a container from the `custom-nginx` image.
   - Name the container `my-nginx`.
   - Map port `8080` on the host to port `80` in the container.
   - Run the container in detached mode.
5. ✅ **Verify the Setup**:
   - Confirm the container is running.
   - Verify the custom `index.html` is served at `http://localhost:8080` using `curl`.

### ℹ️ Instructions
- 📂 Work in the `~/scenario` directory.
- 🐳 Use `docker` commands to build and run the container.
- 🚫 No hints or files are provided, simulating exam conditions.
- 🌐 Use `curl http://localhost:8080` to verify the web server output.
- 📛 Ensure the container is named exactly `my-nginx`.
- 📝 The `index.html` must contain "<h1>Welcome to My Custom Nginx Server</h1>".

### 💡 Tips
- 🔎 Use `docker ps` to check running containers.
- 📜 Use `docker logs` to troubleshoot container issues.
- 📍 Verify your `Dockerfile` syntax before building.
- 🌟 Ensure all files are created in the `~/scenario` directory.

Good luck! 🚀
