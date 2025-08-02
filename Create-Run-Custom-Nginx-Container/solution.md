## ✅ Reference Solution

### Dockerfile
```dockerfile
FROM nginx:1.20.2-alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### Build the Docker Image
```bash
docker build -t custom-nginx:latest .
```

### Run the Container
```bash
docker run -d --name my-nginx -p 8080:80 custom-nginx:latest
```

### Verify the Web Page
```bash
curl http://localhost:8080
```

Expected output:
```
Welcome to Custom Nginx Container!
```