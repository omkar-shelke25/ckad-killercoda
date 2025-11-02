#!/bin/bash
set -e

# Ensure Podman is installed
if ! command -v podman &> /dev/null; then
    echo "Installing Podman..."
    apt-get update -qq
    apt-get install -y podman > /dev/null 2>&1
fi

# Create the course directory
mkdir -p /root/ckad

# Change to the directory
cd /root/ckad

# Create the Flask application
cat > app.py << 'EOF'
from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return 'Welcome to CKAD!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF

# Create requirements.txt
cat > requirements.txt << 'EOF'
Flask==3.0.0
Werkzeug==3.0.1
EOF

# Create Containerfile (Podman's Dockerfile)
cat > Containerfile << 'EOF'
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Expose port 8080
EXPOSE 8080

# Run the application
CMD ["python", "app.py"]
EOF

echo "✅ Setup complete!"
echo "📁 Working directory created at: /root/ckad"
echo ""
echo "📄 Files created:"
echo "   - app.py (Flask application)"
echo "   - requirements.txt (Python dependencies)"
echo "   - Containerfile (Container definition)"
echo ""
echo "🎯 Your task:"
echo "   1. Build a container image named 'flask-web:1.0' using Podman"
echo "   2. Save the image in OCI format as '/root/flask-web-oci.tar'"
echo ""
echo "⚠️  Important: Use Podman commands, not Docker!"
echo "⚠️  Do not push the image to any registry!"
echo ""
echo "💡 Tip: Use 'podman save --format oci-archive' to export in OCI format"
