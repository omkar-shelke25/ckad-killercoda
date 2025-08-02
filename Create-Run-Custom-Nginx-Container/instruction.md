# 🐳 Create and Run a Custom Nginx Container (Mock Exam Question)

## 🎯 Scenario Goal
As a DevOps engineer, you must create a custom Nginx web server using Docker. Your task is to build a Docker image from scratch and run a container that serves a provided web page. This lab simulates a Docker certification exam question, requiring you to create the `Dockerfile` from scratch.

### 📋 Tasks
1. ✍️ **Create the Dockerfile**:
   - Create a `Dockerfile` in the `~/scenario` directory.
   - Use the `nginx:1.27-alpine` base image.
   - Copy the provided `index.html` from `~/scenario` to `/usr/share/nginx/html/index.html`.
   - Expose port `80`.
   - Use `CMD ["nginx", "-g", "daemon off;"]` to ensure Nginx runs in the foreground.
2. 🛠 **Build the Docker Image**:
   - Build a Docker image named `custom-nginx` with the tag `latest` (use `docker build -t custom-nginx:latest .`).
   - Run the build command from the `~/scenario` directory.
3. 🚀 **Run the Container**:
   - Run a container from the `custom-nginx:latest` image.
   - Name the container `my-nginx`.
   - Map port `8080` on the host to port `80` in the container.
   - Run in detached mode.
4. ✅ **Verify the Setup**:
   - Confirm the container is running.
   - Verify the provided `index.html` is served at `http://localhost:8080` using `curl`.

### ℹ️ Instructions
- 📂 Work in the `~/scenario` directory (`cd ~/scenario`), which is pre-created with `index.html`.
- 🐳 Use `docker` commands to build and run the container.
- 🚫 No hints are provided, simulating exam conditions.
- 🌐 Use `curl http://localhost:8080` to verify the web server output.
- 📛 Ensure the container is named exactly `my-nginx`.
- 🖼 The image must be named `custom-nginx:latest` (use `-t custom-nginx:latest` in the build command).
- 🆘 If you cannot complete the task, check `~/scenario/solution.md` for the solution.

### 💡 Troubleshooting Tips
- 📍 Run `pwd` to confirm you’re in `~/scenario` (should show `/home/user/scenario`).
- 🔎 Use `docker images` to verify `custom-nginx:latest` exists.
- 📜 Use `docker logs my-nginx` to troubleshoot container issues.
- 🛠 If the build fails, check `Dockerfile` syntax and ensure `index.html` exists with `ls`.
- ⚠️ If you see "imageId unknown," ensure you ran `docker build -t custom-nginx:latest .` and check `docker images`. Verify the base image with `docker pull nginx:1.27-alpine`.
- 🌐 If the image pull fails, check network connectivity with `ping docker.io` or run `docker pull nginx:1.27-alpine`.
- 🌟 Use a text editor like `vim` or `cat > Dockerfile` to create the `Dockerfile`.

Good luck! 🚀
