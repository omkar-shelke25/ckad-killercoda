#!/bin/bash
set -euo pipefail

# Create namespace
kubectl create namespace interstellar >/dev/null 2>&1 || true

# Ensure /blackhole exists
mkdir -p /blackhole

# If the user-provided file exists, use it; otherwise create a default HTML
if [[ -f /mnt/data/gargantua-scifi.html ]]; then
  cp /mnt/data/gargantua-scifi.html /blackhole/gargantua-scifi.html
else
  cat > /blackhole/gargantua-scifi.html <<'EOT'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gargantua - Black Hole</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            overflow: hidden;
            background: #000;
            font-family: 'Courier New', monospace;
        }

        canvas {
            display: block;
            background: #000;
        }

        .info {
            position: absolute;
            top: 30px;
            left: 30px;
            color: #fff;
            text-shadow: 0 0 10px rgba(255, 255, 255, 0.5);
            z-index: 10;
            font-size: 14px;
            letter-spacing: 2px;
            background: rgba(0, 0, 0, 0.85);
            padding: 20px;
            border: 1px solid rgba(100, 180, 255, 0.4);
            border-radius: 5px;
            backdrop-filter: blur(10px);
            box-shadow: 0 0 30px rgba(100, 180, 255, 0.2);
        }

        .info h1 {
            font-size: 32px;
            margin-bottom: 10px;
            color: #64b4ff;
            text-shadow: 0 0 20px rgba(100, 180, 255, 0.8), 0 0 40px rgba(100, 180, 255, 0.4);
            animation: titlePulse 3s ease-in-out infinite;
        }

        @keyframes titlePulse {
            0%, 100% { text-shadow: 0 0 20px rgba(100, 180, 255, 0.8), 0 0 40px rgba(100, 180, 255, 0.4); }
            50% { text-shadow: 0 0 30px rgba(100, 180, 255, 1), 0 0 60px rgba(100, 180, 255, 0.6); }
        }

        .stat {
            font-size: 11px;
            margin: 5px 0;
            color: #ccc;
        }

        .controls {
            position: absolute;
            bottom: 30px;
            left: 50%;
            transform: translateX(-50%);
            color: #fff;
            text-shadow: 0 0 5px rgba(255, 255, 255, 0.5);
            text-align: center;
            z-index: 10;
            background: rgba(0, 0, 0, 0.85);
            padding: 10px 20px;
            border: 1px solid rgba(100, 180, 255, 0.4);
            border-radius: 5px;
            backdrop-filter: blur(10px);
        }

        @keyframes scanline {
            0% { transform: translateY(-100%); }
            100% { transform: translateY(100vh); }
        }

        .scanline {
            position: absolute;
            width: 100%;
            height: 2px;
            background: linear-gradient(transparent, rgba(100, 180, 255, 0.1), transparent);
            animation: scanline 8s linear infinite;
            pointer-events: none;
            z-index: 5;
        }

        .vignette {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            pointer-events: none;
            background: radial-gradient(ellipse at center, transparent 0%, rgba(0,0,0,0.3) 70%, rgba(0,0,0,0.7) 100%);
            z-index: 1;
        }
    </style>
</head>
<body>
    <div class="scanline"></div>
    <div class="vignette"></div>
    
    <div class="info">
        <h1>GARGANTUA</h1>
        <p>SUPERMASSIVE BLACK HOLE</p>
        <div class="stat">MASS: 100 Million M☉</div>
        <div class="stat">SCHWARZSCHILD RADIUS: 295M km</div>
        <div class="stat">TEMPERATURE: ~10,000K</div>
    </div>
    
    <div class="controls">
        <p>DRAG TO ROTATE | SCROLL TO ZOOM</p>
    </div>

    <canvas id="blackhole"></canvas>

    <script>
        const canvas = document.getElementById('blackhole');
        const ctx = canvas.getContext('2d');
        
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;

        let mouseX = 0;
        let mouseY = 0;
        let isDragging = false;
        let rotationX = Math.PI * 0.15;
        let rotationY = 0;
        let zoom = 1;
        let time = 0;
        let autoRotate = true;

        class Particle {
            constructor() {
                this.reset();
            }

            reset() {
                const angle = Math.random() * Math.PI * 2;
                const radius = 150 + Math.random() * 400;
                this.angle = angle;
                this.radius = radius;
                this.x = Math.cos(angle) * radius;
                this.y = 0;
                this.z = Math.sin(angle) * radius;
                
                this.diskHeight = (Math.random() - 0.5) * 25;
                this.baseSpeed = 0.25 + Math.random() * 0.4;
                this.baseOrbitSpeed = 0.006 + Math.random() * 0.012;
                this.size = 1.5 + Math.random() * 2.5;
                this.brightness = 0.8 + Math.random() * 0.2;
            }

            update() {
                const r = this.radius;
                const gravityFactor = Math.pow(65 / r, 3);
                const speedMult = 1 + gravityFactor * 6;
                
                this.angle += this.baseOrbitSpeed * speedMult;
                this.radius -= this.baseSpeed * speedMult;

                if (this.radius < 55) {
                    this.reset();
                    return;
                }

                this.x = Math.cos(this.angle) * this.radius;
                this.z = Math.sin(this.angle) * this.radius;
                
                const turbulence = Math.pow(85 / this.radius, 2);
                const wave = Math.sin(this.angle * 10 + time * 5) * turbulence * 4;
                const wave2 = Math.cos(this.angle * 6 - time * 3) * turbulence * 2;
                this.y = this.diskHeight * (1 - turbulence * 0.6) + wave + wave2;
            }

            getColor() {
                const heat = Math.max(0, 1 - this.radius / 550);
                const temp = heat * heat;
                
                if (temp > 0.9) {
                    return { r: 255, g: 255, b: 255 };
                } else if (temp > 0.75) {
                    return { r: 200, g: 220, b: 255 };
                } else if (temp > 0.6) {
                    return { r: 255, g: 240, b: 200 };
                } else if (temp > 0.4) {
                    return { r: 255, g: 200, b: 100 };
                } else if (temp > 0.2) {
                    return { r: 255, g: 140, b: 50 };
                } else {
                    return { r: 200, g: 80, b: 30 };
                }
            }

            project() {
                const cosY = Math.cos(rotationY);
                const sinY = Math.sin(rotationY);
                const cosX = Math.cos(rotationX);
                const sinX = Math.sin(rotationX);

                const x1 = this.x * cosY - this.z * sinY;
                const z1 = this.x * sinY + this.z * cosY;
                
                const y2 = this.y * cosX - z1 * sinX;
                const z2 = this.y * sinX + z1 * cosX;

                const distance = 600;
                const scale = distance / (distance + z2) * zoom;
                
                return {
                    x: canvas.width / 2 + x1 * scale,
                    y: canvas.height / 2 + y2 * scale,
                    z: z2,
                    scale: scale
                };
            }

            draw() {
                const pos = this.project();
                
                if (pos.z < -500) return;

                const intensity = Math.max(0, 1 - this.radius / 550);
                const depthFade = Math.max(0, Math.min(1, (pos.z + 450) / 900));
                const alpha = intensity * this.brightness * depthFade * 0.95;
                
                const color = this.getColor();
                const baseSize = Math.max(0.8, this.size * pos.scale);
                const glowSize = baseSize * (4 + intensity * 10);
                
                const gradient = ctx.createRadialGradient(pos.x, pos.y, 0, pos.x, pos.y, glowSize);
                gradient.addColorStop(0, `rgba(${color.r}, ${color.g}, ${color.b}, ${alpha * 1.2})`);
                gradient.addColorStop(0.1, `rgba(${color.r}, ${color.g}, ${color.b}, ${alpha})`);
                gradient.addColorStop(0.3, `rgba(${Math.max(0, color.r - 20)}, ${Math.max(0, color.g - 40)}, ${Math.max(0, color.b - 60)}, ${alpha * 0.7})`);
                gradient.addColorStop(0.6, `rgba(${Math.max(0, color.r - 60)}, ${Math.max(0, color.g - 100)}, ${Math.max(0, color.b - 120)}, ${alpha * 0.4})`);
                gradient.addColorStop(1, 'rgba(0, 0, 0, 0)');

                ctx.fillStyle = gradient;
                ctx.beginPath();
                ctx.arc(pos.x, pos.y, glowSize, 0, Math.PI * 2);
                ctx.fill();

                if (intensity > 0.85) {
                    ctx.fillStyle = `rgba(255, 255, 255, ${alpha * 1.5})`;
                    ctx.shadowColor = `rgba(${color.r}, ${color.g}, ${color.b}, 0.9)`;
                    ctx.shadowBlur = 15;
                    ctx.beginPath();
                    ctx.arc(pos.x, pos.y, baseSize * 0.8, 0, Math.PI * 2);
                    ctx.fill();
                    ctx.shadowBlur = 0;
                }
            }
        }

        const particles = [];
        for (let i = 0; i < 5000; i++) {
            particles.push(new Particle());
        }

        class Star {
            constructor() {
                this.x = Math.random() * canvas.width;
                this.y = Math.random() * canvas.height;
                this.size = Math.random() * 1.5 + 0.3;
                this.brightness = Math.random() * 0.8 + 0.2;
                this.twinkleSpeed = 0.8 + Math.random() * 1.5;
                this.phase = Math.random() * Math.PI * 2;
                this.color = Math.random() > 0.7 ? { r: 200, g: 220, b: 255 } : { r: 255, g: 255, b: 255 };
            }

            draw() {
                const twinkle = (Math.sin(time * this.twinkleSpeed + this.phase) + 1) / 2;
                const alpha = this.brightness * twinkle * 0.95;
                
                ctx.fillStyle = `rgba(${this.color.r}, ${this.color.g}, ${this.color.b}, ${alpha})`;
                ctx.beginPath();
                ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);
                ctx.fill();
                
                if (this.size > 1 && twinkle > 0.75) {
                    ctx.fillStyle = `rgba(${this.color.r}, ${this.color.g}, ${this.color.b}, ${alpha * 0.3})`;
                    ctx.beginPath();
                    ctx.arc(this.x, this.y, this.size * 2.5, 0, Math.PI * 2);
                    ctx.fill();
                }
            }
        }

        const stars = [];
        for (let i = 0; i < 400; i++) {
            stars.push(new Star());
        }

        class SpaceNebula {
            constructor() {
                this.x = Math.random() * canvas.width;
                this.y = Math.random() * canvas.height;
                this.size = 100 + Math.random() * 200;
                this.alpha = 0.03 + Math.random() * 0.05;
                this.hue = Math.random() * 60 + 180;
            }

            draw() {
                const gradient = ctx.createRadialGradient(this.x, this.y, 0, this.x, this.y, this.size);
                gradient.addColorStop(0, `hsla(${this.hue}, 60%, 50%, ${this.alpha})`);
                gradient.addColorStop(0.5, `hsla(${this.hue + 20}, 50%, 40%, ${this.alpha * 0.5})`);
                gradient.addColorStop(1, 'rgba(0, 0, 0, 0)');
                
                ctx.fillStyle = gradient;
                ctx.beginPath();
                ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);
                ctx.fill();
            }
        }

        const nebulae = [];
        for (let i = 0; i < 8; i++) {
            nebulae.push(new SpaceNebula());
        }

        function drawBlackHole() {
            const centerX = canvas.width / 2;
            const centerY = canvas.height / 2;
            const radius = 55 * zoom;

            const outerGlow = ctx.createRadialGradient(
                centerX, centerY, 0,
                centerX, centerY, radius * 4
            );
            outerGlow.addColorStop(0, 'rgba(0, 0, 0, 1)');
            outerGlow.addColorStop(0.25, 'rgba(0, 0, 0, 1)');
            outerGlow.addColorStop(0.45, 'rgba(40, 20, 10, 0.95)');
            outerGlow.addColorStop(0.6, 'rgba(80, 40, 20, 0.7)');
            outerGlow.addColorStop(0.75, 'rgba(120, 60, 30, 0.4)');
            outerGlow.addColorStop(0.9, 'rgba(100, 50, 25, 0.15)');
            outerGlow.addColorStop(1, 'rgba(0, 0, 0, 0)');

            ctx.fillStyle = outerGlow;
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius * 4, 0, Math.PI * 2);
            ctx.fill();

            ctx.fillStyle = '#000000';
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
            ctx.fill();

            const pulse = Math.sin(time * 1.5) * 0.2 + 0.8;
            const pulse2 = Math.cos(time * 2.3) * 0.15 + 0.85;
            
            for (let i = 0; i < 3; i++) {
                const ringPulse = i === 0 ? pulse : (i === 1 ? pulse2 : (pulse + pulse2) / 2);
                ctx.strokeStyle = `rgba(${255 - i * 30}, ${180 - i * 40}, ${120 - i * 30}, ${(0.5 - i * 0.12) * ringPulse})`;
                ctx.lineWidth = 3 - i * 0.5;
                ctx.shadowColor = `rgba(255, ${180 - i * 40}, ${120 - i * 30}, 0.8)`;
                ctx.shadowBlur = 30 - i * 5;
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius + 4 + i * 3, 0, Math.PI * 2);
                ctx.stroke();
            }
            ctx.shadowBlur = 0;
        }

        function drawGravitationalLensing() {
            const centerX = canvas.width / 2;
            const centerY = canvas.height / 2;
            const baseRadius = 55 * zoom;

            for (let ring = 0; ring < 5; ring++) {
                const ringRadius = baseRadius * (2.1 + ring * 0.7);
                const distortion = Math.sin(time * 0.8 + ring * 0.5) * 5;
                const intensity = 0.12 - ring * 0.018;
                
                const gradient = ctx.createRadialGradient(
                    centerX, centerY, ringRadius - 20 + distortion,
                    centerX, centerY, ringRadius + 20 + distortion
                );
                gradient.addColorStop(0, 'rgba(0, 0, 0, 0)');
                gradient.addColorStop(0.25, `rgba(100, 150, 255, ${intensity * 0.6})`);
                gradient.addColorStop(0.5, `rgba(200, 180, 120, ${intensity * 1.2})`);
                gradient.addColorStop(0.75, `rgba(255, 160, 80, ${intensity * 0.8})`);
                gradient.addColorStop(1, 'rgba(0, 0, 0, 0)');
                
                ctx.fillStyle = gradient;
                ctx.beginPath();
                ctx.arc(centerX, centerY, ringRadius, 0, Math.PI * 2);
                ctx.fill();
            }
        }

        function drawPhotonSphere() {
            const centerX = canvas.width / 2;
            const centerY = canvas.height / 2;
            const radius = 55 * zoom * 2.5;
            const pulse = Math.sin(time * 2) * 0.3 + 0.7;

            for (let i = 0; i < 30; i++) {
                const angle = (i / 30) * Math.PI * 2 + time * 0.5;
                const x = centerX + Math.cos(angle) * radius;
                const y = centerY + Math.sin(angle) * radius * 0.3;
                
                const gradient = ctx.createRadialGradient(x, y, 0, x, y, 8);
                gradient.addColorStop(0, `rgba(255, 255, 255, ${0.4 * pulse})`);
                gradient.addColorStop(0.5, `rgba(150, 200, 255, ${0.2 * pulse})`);
                gradient.addColorStop(1, 'rgba(0, 0, 0, 0)');
                
                ctx.fillStyle = gradient;
                ctx.beginPath();
                ctx.arc(x, y, 8, 0, Math.PI * 2);
                ctx.fill();
            }
        }

        function animate() {
            time += 0.016;
            
            ctx.fillStyle = 'rgba(0, 0, 0, 0.25)';
            ctx.fillRect(0, 0, canvas.width, canvas.height);

            nebulae.forEach(nebula => nebula.draw());
            stars.forEach(star => star.draw());
            
            drawGravitationalLensing();
            drawPhotonSphere();

            particles.sort((a, b) => {
                const aProj = a.project();
                const bProj = b.project();
                return aProj.z - bProj.z;
            });

            particles.forEach(p => {
                p.update();
                p.draw();
            });

            drawBlackHole();

            if (autoRotate && !isDragging) {
                rotationY += 0.003;
            }

            requestAnimationFrame(animate);
        }

        canvas.addEventListener('mousedown', (e) => {
            isDragging = true;
            autoRotate = false;
            mouseX = e.clientX;
            mouseY = e.clientY;
        });

        canvas.addEventListener('mousemove', (e) => {
            if (isDragging) {
                const dx = e.clientX - mouseX;
                const dy = e.clientY - mouseY;
                rotationY += dx * 0.01;
                rotationX += dy * 0.01;
                rotationX = Math.max(-Math.PI / 2.5, Math.min(Math.PI / 2.5, rotationX));
                mouseX = e.clientX;
                mouseY = e.clientY;
            }
        });

        canvas.addEventListener('mouseup', () => {
            isDragging = false;
            setTimeout(() => { autoRotate = true; }, 2000);
        });

        canvas.addEventListener('mouseleave', () => {
            isDragging = false;
        });

        canvas.addEventListener('wheel', (e) => {
            e.preventDefault();
            zoom += e.deltaY * -0.0015;
            zoom = Math.max(0.5, Math.min(3, zoom));
        });

        window.addEventListener('resize', () => {
            canvas.width = window.innerWidth;
            canvas.height = window.innerHeight;
            stars.length = 0;
            for (let i = 0; i < 400; i++) {
                stars.push(new Star());
            }
            nebulae.length = 0;
            for (let i = 0; i < 8; i++) {
                nebulae.push(new SpaceNebula());
            }
        });

        animate();
    </script>
</body>
</html>
EOT
fi

# Create a ConfigMap from the file (prerequisite) in the interstellar namespace
kubectl -n interstellar create configmap gargantua-cm --from-file=gargantua-scifi.html=/blackhole/gargantua-scifi.html --dry-run=client -o yaml | kubectl apply -f -

# Drop a deprecated Deployment manifest (uses a deprecated API and intentionally omits selector)
cat > /blackhole/gargantuan-deprecated.yaml <<'EOF'
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: gargantuan
  namespace: interstellar
spec:
  replicas: 2
  # NOTE: selector intentionally missing (the learner must add it after conversion)
  template:
    metadata:
      labels:
        app: gargantuan
    spec:
      containers:
      - name: nginx
        image: public.ecr.aws/nginx/nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html/gargantua-scifi.html
          subPath: gargantua-scifi.html
      volumes:
      - name: html
        configMap:
          name: gargantua-cm
EOF

echo "Setup complete. Files placed under /blackhole (gargantua-scifi.html and gargantuan-deprecated.yaml)."
