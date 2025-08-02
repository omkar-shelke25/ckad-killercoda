# 🐳 Create and Run a Custom Nginx Container

## 🎯 Scenario Goal
As a DevOps engineer, you must create a custom Nginx web server using Docker. Your task is to build a Docker image from scratch and run a container that serves a custom web page. This lab simulates a Docker certification exam question, requiring you to create all necessary files without guidance.

### 📋 Tasks
1. ✍️ **Create the Dockerfile**:
   - Create a `Dockerfile` in the `~/scenario` directory.
   - Use the `nginx:1.27-alpine` base image.
   - Copy a custom `index.html` file to `/usr/share/nginx/html/index.html`.
   - Expose port `80`.
   - Use `CMD ["nginx", "-g", "daemon off;"]` to ensure Nginx runs in the foreground.
2. 📜 **Create the index.html File**:
   - Create an `index.html` file in the `~/scenario` directory.
   - Include an `<h1>` tag with the text "Welcome to My Custom Nginx Server".
3. 🛠 **Build the Docker Image**:
   - Build a Docker image named `custom-nginx` with the tag `latest` (use `docker build -t custom-nginx:latest .`).
   - Run the build command from the `~/scenario` directory.
4. 🚀 **Run the Container**:
   - Run a container from the `custom-nginx:latest` image.
   - Name the container `my-nginx`.
   - Map port `8080` on the host to port `80` in the container.
   - Run in detached mode.
5. ✅ **Verify the Setup**:
   - Confirm the container is running.
   - Verify the custom `index.html` is served at `http://localhost:8080` using `curl`.

### ℹ️ Instructions
- 📂 Work in the `~/scenario` directory (`cd ~/scenario`).
- 🐳 Use `docker` commands to build and run the container.
- 🚫 No hints or files are provided, simulating exam conditions.
- 🌐 Use `curl http://localhost:8080` to verify the web server output.
- 📛 Ensure the container is named exactly `my-nginx`.
- 📝 The `index.html` must contain "<h1>Welcome to My Custom Nginx Server</h1>".
- 🖼 The image must be named `custom-nginx:latest` (use `-t custom-nginx:latest` in the build command).

### 💡 Troubleshooting Tips
- 📍 Run `pwd` to confirm you’re in `~/scenario` before building.
- 🔎 Use `docker images` to verify the `custom-nginx:latest` image exists.
- 📜 Use `docker logs my-nginx` to troubleshoot container issues.
- 🛠 If the build fails, check `Dockerfile` syntax and file presence with `ls`.
- ⚠️ If you see "imageId unknown," ensure you used `docker build -t custom-nginx:latest .` and check `docker images`.
- 🌟 Use a text editor like `vim` or `cat > file` to create files accurately.

Good luck! 🚀
