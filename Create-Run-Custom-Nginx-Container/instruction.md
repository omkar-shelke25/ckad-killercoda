# 🐳 Docker Mock Exam: Create and Run a Custom Nginx Container

## 🎯 Objective
Build and run a Docker container that serves a custom HTML page using Nginx.

---

## ✅ Task

1. **Create a Dockerfile** in the current working directory:
    - Use the base image: `nginx:1.20.2-alpine`
    - Copy the provided `index.html` into the container at:  
      `/usr/share/nginx/html/index.html`
    - Expose port `80`
    - Set the default command to run Nginx in the foreground:
      ```dockerfile
      CMD ["nginx", "-g", "daemon off;"]
      ```

2. **Build the Docker Image**:
    - Build the Docker image from the Dockerfile in the current directory.
    - Use the tag: `custom-nginx:latest`
    - Run the build command exactly like:
      ```bash
      docker build -t custom-nginx:latest .
      ```

3. **Run the Container**:
    - Start a container from your image.
    - Requirements:
      - Name the container: `my-nginx`
      - Map port `8080` on the host to port `80` inside the container
      - Run the container in **detached** mode
    - Example:
      ```bash
      docker run -d --name my-nginx -p 8080:80 custom-nginx:latest
      ```

4. **Verify Output**:
    - Confirm the container is running:
      ```bash
      docker ps
      ```
    - Verify that the web page is served:
      ```bash
      curl http://localhost:8080
      ```
    - Output must include:
      ```
      Welcome to Custom Nginx Container!
      ```

---

## 🧾 Notes
- All commands must be executed from the current directory.
- Do **not** rename or move the `index.html` file.
- Use the exact image and container names:
  - Image: `custom-nginx:latest`
  - Container: `my-nginx`
- Do not use Docker Compose or external tools.

⏱️ **Time limit**: 15 minutes