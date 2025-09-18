#!/bin/bash
set -euo pipefail

echo "🌌 Initializing Quantum Space Observatory Environment..."

# Create project directory
mkdir -p /root/blackhole-project
cd /root/blackhole-project

echo "📝 Creating BlackHole Wave Monitoring Dockerfile..."

# Create the Dockerfile with the provided content
cat > Dockerfile << 'EOF'
# Simple Dockerfile with long-running processes for container practice
# MAINTAINER: Omkar Shelke
# COMPANY: Killer Coda CKDA Practice
# DESCRIPTION: Dockerfile with simple processes that keep container running and display logs
FROM ubuntu:20.04

# Maintainer information
LABEL maintainer="Omkar Shelke"
LABEL company="Killer Coda CKDA Practice"
LABEL description="Simple container with long-running processes for practice"

# Create working directory
WORKDIR /app

# Create a simple script that runs continuously and generates logs
RUN echo '#!/bin/bash' > /app/monitor.sh && \
    echo 'echo "Container started at $(date)"' >> /app/monitor.sh && \
    echo 'echo "Maintainer: Omkar Shelke - Killer Coda CKDA Practice"' >> /app/monitor.sh && \
    echo 'counter=1' >> /app/monitor.sh && \
    echo 'while true; do' >> /app/monitor.sh && \
    echo '  echo "[$(date)] Process running... Count: $counter"' >> /app/monitor.sh && \
    echo '  echo "----------------------------------------"' >> /app/monitor.sh && \
    echo '  counter=$((counter + 1))' >> /app/monitor.sh && \
    echo '  sleep 10' >> /app/monitor.sh && \
    echo 'done' >> /app/monitor.sh

# Make script executable
RUN chmod +x /app/monitor.sh

# Set environment variables
ENV CONTAINER_NAME="ckda-practice"
ENV MAINTAINER="Omkar Shelke"
ENV COMPANY="Killer Coda"

# Expose a port
EXPOSE 8080

# Default command - runs the monitoring script that keeps container alive
CMD ["/bin/bash", "/app/monitor.sh"]
EOF



echo "✅ Environment setup complete!"
echo ""
echo "📂 Project directory: /root/blackhole-project"
echo "📋 Available files:"
ls -la /root/blackhole-project/

echo ""
echo "🎯 Your mission:"
echo "1. Build the BlackHole Wave monitoring container"
echo "2. Save it in OCI format as blackhole-monitoring.tar"  
echo "3. Transfer and run it on node01"
echo "4. Verify the monitoring system is operational"

echo ""
echo "🚀 Ready to begin! Change to project directory: cd /root/blackhole-project"
