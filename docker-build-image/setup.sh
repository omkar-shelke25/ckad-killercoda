#!/bin/bash
set -e

# Create the course directory
mkdir -p /opt/course/docker

# Create a simple Node.js application
cat > /opt/course/docker/app.js << 'EOF'
const http = require('http');
const os = require('os');

const hostname = '0.0.0.0';
const port = 3000;

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/html');
  
  const response = `
    <html>
      <head><title>MyApp v2.1</title></head>
      <body style="font-family: Arial, sans-serif; margin: 40px; background: #f4f4f4;">
        <div style="background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
          <h1 style="color: #333;">🚀 MyApp Production Ready</h1>
          <p><strong>Version:</strong> 2.1</p>
          <p><strong>Status:</strong> Running</p>
          <p><strong>Hostname:</strong> ${os.hostname()}</p>
          <p><strong>Platform:</strong> ${os.platform()}</p>
          <p><strong>Node Version:</strong> ${process.version}</p>
          <p><strong>Uptime:</strong> ${Math.floor(process.uptime())} seconds</p>
          <hr>
          <p style="color: green;">✅ Application is healthy and running!</p>
        </div>
      </body>
    </html>
  `;
  
  res.end(response);
});

server.listen(port, hostname, () => {
  console.log(`🌐 Server running at http://${hostname}:${port}/`);
  console.log(`📦 MyApp v2.1 started successfully`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('🔄 SIGTERM received, shutting down gracefully');
  server.close(() => {
    console.log('✅ Process terminated');
  });
});
EOF

# Create package.json
cat > /opt/course/docker/package.json << 'EOF'
{
  "name": "myapp",
  "version": "2.1.0",
  "description": "Simple Node.js app for Docker export demo",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "author": "DevOps Team",
  "license": "MIT"
}
EOF

# Create Dockerfile
cat > /opt/course/docker/Dockerfile << 'EOF'
FROM node:18-alpine

# Set working directory
WORKDIR /usr/src/app

# Copy package files
COPY package.json ./

# Install dependencies (none needed for this simple app)
RUN npm install --only=production

# Copy application code
COPY app.js ./

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Change ownership
RUN chown -R nodejs:nodejs /usr/src/app
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "const http = require('http'); const req = http.request({hostname: 'localhost', port: 3000, path: '/', timeout: 2000}, (res) => { process.exit(res.statusCode === 200 ? 0 : 1); }); req.on('error', () => process.exit(1)); req.end();"

# Start the application
CMD ["npm", "start"]
EOF

# Create .dockerignore
cat > /opt/course/docker/.dockerignore << 'EOF'
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.nyc_output
coverage
.DS_Store
EOF

# Create directory for exports
mkdir -p /opt/course/docker/exports

echo "✅ Setup complete!"
echo "📁 Project files created at: /opt/course/docker/"
echo ""
echo "📝 Files created:"
echo "   - app.js (Node.js application)"
echo "   - package.json (npm configuration)"  
echo "   - Dockerfile (optimized for production)"
echo "   - .dockerignore (build optimization)"
echo ""
echo "🎯 Your task:"
echo "   1. Build Docker image with tag 'myapp:2.1'"
echo "   2. Export the image as 'myapp-v2.1.tar' in exports/ directory"
echo "   3. Test the exported image works correctly"
