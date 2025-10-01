#!/bin/bash
set -euo pipefail

echo "Preparing One Piece lab environment..."

# Create the one-piece directory
mkdir -p /one-piece

# Write the exact HTML (verbatim) using a single-quoted heredoc
cat > /one-piece/index.html <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>One Piece Terminal - Straw Hat Pirates Database</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            background: #0a0e27;
            color: #00ff00;
            font-family: 'Courier New', monospace;
            padding: 20px;
            line-height: 1.6;
        }

        .terminal {
            max-width: 1000px;
            margin: 0 auto;
            background: #000;
            border: 2px solid #00ff00;
            border-radius: 8px;
            box-shadow: 0 0 30px rgba(0, 255, 0, 0.3);
            overflow: hidden;
        }

        .terminal-header {
            background: #1a1a1a;
            padding: 10px 15px;
            border-bottom: 2px solid #00ff00;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .terminal-button {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            display: inline-block;
        }

        .btn-red { background: #ff5f56; }
        .btn-yellow { background: #ffbd2e; }
        .btn-green { background: #27c93f; }

        .terminal-title {
            margin-left: 10px;
            color: #00ff00;
            font-size: 14px;
        }

        .terminal-body {
            padding: 20px;
            min-height: 500px;
        }

        .prompt {
            color: #00ff00;
            margin-bottom: 15px;
        }

        .prompt::before {
            content: "root@onepiece:~$ ";
            color: #00ffff;
        }

        .output {
            margin-bottom: 20px;
            animation: typewriter 0.5s steps(40);
        }

        @keyframes typewriter {
            from { opacity: 0; }
            to { opacity: 1; }
        }

        .ascii-art {
            color: #ffa500;
            font-size: 10px;
            line-height: 1.2;
            margin: 20px 0;
            white-space: pre;
        }

        .character-card {
            border: 1px solid #00ff00;
            padding: 15px;
            margin: 15px 0;
            background: #0a0a0a;
            transition: all 0.3s;
        }

        .character-card:hover {
            box-shadow: 0 0 20px rgba(0, 255, 0, 0.5);
            transform: translateX(10px);
        }

        .character-name {
            color: #ffff00;
            font-size: 18px;
            font-weight: bold;
            margin-bottom: 10px;
            text-decoration: underline;
        }

        .label {
            color: #00ffff;
            font-weight: bold;
        }

        .value {
            color: #00ff00;
        }

        .bounty {
            color: #ff6b6b;
            font-weight: bold;
        }

        .command-input {
            display: flex;
            align-items: center;
            margin-top: 20px;
        }

        .command-input::before {
            content: "root@onepiece:~$ ";
            color: #00ffff;
            margin-right: 5px;
        }

        .cursor {
            display: inline-block;
            width: 8px;
            height: 16px;
            background: #00ff00;
            animation: blink 1s infinite;
        }

        @keyframes blink {
            0%, 50% { opacity: 1; }
            51%, 100% { opacity: 0; }
        }

        .section-title {
            color: #ff00ff;
            font-size: 20px;
            margin: 20px 0 10px 0;
            border-bottom: 1px solid #ff00ff;
            padding-bottom: 5px;
        }

        .info-line {
            margin: 5px 0;
        }

        .devil-fruit {
            color: #ff1493;
        }
    </style>
</head>
<body>
    <div class="terminal">
        <div class="terminal-header">
            <span class="terminal-button btn-red"></span>
            <span class="terminal-button btn-yellow"></span>
            <span class="terminal-button btn-green"></span>
            <span class="terminal-title">terminal@straw-hat-pirates</span>
        </div>
        
        <div class="terminal-body">
            <div class="ascii-art">
    ____  _   _ _____   ____  ___ _____ ____ _____ 
   / __ \| \ | | ____| |  _ \|_ _| ____/ ___| ____|
  | |  | |  \| |  _|   | |_) || ||  _|| |   |  _|  
  | |__| | |\  | |___  |  __/ | || |__| |___| |___ 
   \____/|_| \_|_____| |_|   |___|_____\____|_____|
            </div>

            <div class="prompt">cat straw_hat_crew.db</div>
            
            <div class="output">
                <p class="value">Loading Straw Hat Pirates Database...</p>
                <p class="value">Access Granted: Marine Intelligence Level 5</p>
                <p class="value">========================================</p>
            </div>

            <div class="section-title">&gt;&gt; CREW OVERVIEW</div>
            <div class="output">
                <p class="info-line"><span class="label">Ship:</span> <span class="value">Thousand Sunny</span></p>
                <p class="info-line"><span class="label">Total Members:</span> <span class="value">10</span></p>
                <p class="info-line"><span class="label">Total Bounty:</span> <span class="bounty">8,816,001,000 Berries</span></p>
                <p class="info-line"><span class="label">Status:</span> <span class="value">Active - Yonko Crew</span></p>
            </div>

            <div class="section-title">&gt;&gt; CREW MEMBERS DATA</div>

            <div class="character-card">
                <div class="character-name">[ 01 ] MONKEY D. LUFFY</div>
                <p class="info-line"><span class="label">Position:</span> <span class="value">Captain</span></p>
                <p class="info-line"><span class="label">Age:</span> <span class="value">19</span></p>
                <p class="info-line"><span class="label">Bounty:</span> <span class="bounty">3,000,000,000 Berries</span></p>
                <p class="info-line"><span class="label">Devil Fruit:</span> <span class="devil-fruit">Gomu Gomu no Mi (Hito Hito no Mi, Model: Nika)</span></p>
                <p class="info-line"><span class="label">Abilities:</span> <span class="value">Gear 5, Advanced Haki (All Three Types), Rubber Body</span></p>
                <p class="info-line"><span class="label">Dream:</span> <span class="value">Become King of the Pirates</span></p>
            </div>

            <div class="character-card">
                <div class="character-name">[ 02 ] RORONOA ZORO</div>
                <p class="info-line"><span class="label">Position:</span> <span class="value">Swordsman / First Mate</span></p>
                <p class="info-line"><span class="label">Age:</span> <span class="value">21</span></p>
                <p class="info-line"><span class="label">Bounty:</span> <span class="bounty">1,111,000,000 Berries</span></p>
                <p class="info-line"><span class="label">Fighting Style:</span> <span class="value">Three-Sword Style (Santoryu)</span></p>
                <p class="info-line"><span class="label">Abilities:</span> <span class="value">Advanced Conqueror's Haki, Enma Mastery</span></p>
                <p class="info-line"><span class="label">Dream:</span> <span class="value">Become the World's Greatest Swordsman</span></p>
            </div>

            <div class="character-card">
                <div class="character-name">[ 03 ] NAMI</div>
                <p class="info-line"><span class="label">Position:</span> <span class="value">Navigator</span></p>
                <p class="info-line"><span class="label">Age:</span> <span class="value">20</span></p>
                <p class="info-line"><span class="label">Bounty:</span> <span class="bounty">366,000,000 Berries</span></p>
                <p class="info-line"><span class="label">Weapon:</span> <span class="value">Clima-Tact (Weather Manipulation)</span></p>
                <p class="info-line"><span class="label">Abilities:</span> <span class="value">Master Navigator, Weather Prediction, Zeus Control</span></p>
                <p class="info-line"><span class="label">Dream:</span> <span class="value">Draw a Complete Map of the World</span></p>
            </div>

            <div class="character-card">
                <div class="character-name">[ 04 ] USOPP</div>
                <p class="info-line"><span class="label">Position:</span> <span class="value">Sniper</span></p>
                <p class="info-line"><span class="label">Age:</span> <span class="value">19</span></p>
                <p class="info-line"><span class="label">Bounty:</span> <span class="bounty">500,000,000 Berries</span></p>
                <p class="info-line"><span class="label">Weapon:</span> <span class="value">Kabuto (Slingshot)</span></p>
                <p class="info-line"><span class="label">Abilities:</span> <span class="value">Observation Haki, Expert Marksman, Inventor</span></p>
                <p class="info-line"><span class="label">Dream:</span> <span class="value">Become a Brave Warrior of the Sea</span></p>
            </div>

            <div class="character-card">
                <div class="character-name">[ 05 ] SANJI</div>
                <p class="info-line"><span class="label">Position:</span> <span class="value">Cook</span></p>
                <p class="info-line"><span class="label">Age:</span> <span class="value">21</span></p>
                <p class="info-line"><span class="label">Bounty:</span> <span class="bounty">1,032,000,000 Berries</span></p>
                <p class="info-line"><span class="label">Fighting Style:</span> <span class="value">Black Leg Style (Kicks)</span></p>
                <p class="info-line"><span class="label">Abilities:</span> <span class="value">Ifrit Jambe, Germa Exoskeleton, Observation Haki</span></p>
                <p class="info-line"><span class="label">Dream:</span> <span class="value">Find the All Blue</span></p>
            </div>

            <div class="character-card">
                <div class="character-name">[ 06 ] TONY TONY CHOPPER</div>
                <p class="info-line"><span class="label">Position:</span> <span class="value">Doctor</span></p>
                <p class="info-line"><span class="label">Age:</span> <span class="value">17</span></p>
                <p class="info-line"><span class="label">Bounty:</span> <span class="bounty">1,000 Berries</span></p>
                <p class="info-line"><span class="label">Devil Fruit:</span> <span class="devil-fruit">Hito Hito no Mi (Human-Human Fruit)</span></p>
                <p class="info-line"><span class="label">Abilities:</span> <span class="value">Monster Point, Rumble Ball, Medical Expertise</span></p>
                <p class="info-line"><span class="label">Dream:</span> <span class="value">Cure All Diseases</span></p>
            </div>

            <div class="character-card">
                <div class="character-name">[ 07 ] NICO ROBIN</div>
                <p class="info-line"><span class="label">Position:</span> <span class="value">Archaeologist</span></p>
                <p class="info-line"><span class="label">Age:</span> <span class="value">30</span></p>
                <p class="info-line"><span class="label">Bounty:</span> <span class="bounty">930,000,000 Berries</span></p>
                <p class="info-line"><span class="label">Devil Fruit:</span> <span class="devil-fruit">Hana Hana no Mi (Flower-Flower Fruit)</span></p>
                <p class="info-line"><span class="label">Abilities:</span> <span class="value">Demonio Fleur, Poneglyph Reading, Armament Haki</span></p>
                <p class="info-line"><span class="label">Dream:</span> <span class="value">Uncover the True History</span></p>
            </div>

            <div class="character-card">
                <div class="character-name">[ 08 ] FRANKY</div>
                <p class="info-line"><span class="label">Position:</span> <span class="value">Shipwright</span></p>
                <p class="info-line"><span class="label">Age:</span> <span class="value">36</span></p>
                <p class="info-line"><span class="label">Bounty:</span> <span class="bounty">394,000,000 Berries</span></p>
                <p class="info-line"><span class="label">Type:</span> <span class="value">Cyborg</span></p>
                <p class="info-line"><span class="label">Abilities:</span> <span class="value">Franky Shogun, Radical Beam, Vegapunk Technology</span></p>
                <p class="info-line"><span class="label">Dream:</span> <span class="value">Build a Dream Ship and Sail it to the End</span></p>
            </div>

            <div class="character-card">
                <div class="character-name">[ 09 ] BROOK</div>
                <p class="info-line"><span class="label">Position:</span> <span class="value">Musician</span></p>
                <p class="info-line"><span class="label">Age:</span> <span class="value">90</span></p>
                <p class="info-line"><span class="label">Bounty:</span> <span class="bounty">383,000,000 Berries</span></p>
                <p class="info-line"><span class="label">Devil Fruit:</span> <span class="devil-fruit">Yomi Yomi no Mi (Revive-Revive Fruit)</span></p>
                <p class="info-line"><span class="label">Abilities:</span> <span class="value">Soul Manipulation, Ice Powers, Master Swordsman</span></p>
                <p class="info-line"><span class="label">Dream:</span> <span class="value">Reunite with Laboon</span></p>
            </div>

            <div class="character-card">
                <div class="character-name">[ 10 ] JINBE</div>
                <p class="info-line"><span class="label">Position:</span> <span class="value">Helmsman</span></p>
                <p class="info-line"><span class="label">Age:</span> <span class="value">46</span></p>
                <p class="info-line"><span class="label">Bounty:</span> <span class="bounty">1,100,000,000 Berries</span></p>
                <p class="info-line"><span class="label">Species:</span> <span class="value">Fish-Man (Whale Shark)</span></p>
                <p class="info-line"><span class="label">Abilities:</span> <span class="value">Fish-Man Karate, Advanced Armament Haki, Water Manipulation</span></p>
                <p class="info-line"><span class="label">Dream:</span> <span class="value">Achieve Equality Between Races</span></p>
            </div>

            <div class="output" style="margin-top: 30px;">
                <p class="value">========================================</p>
                <p class="value">End of Database Query</p>
                <p class="label">Note: These Pirates are extremely dangerous!</p>
            </div>

            <div class="command-input">
                <span class="cursor"></span>
            </div>
        </div>
    </div>
</body>
</html>
HTMLEOF

# Permissions (optional but nice)
chmod 644 /one-piece/index.html

# Create the namespace if it doesn't exist
kubectl create namespace one-piece 2>/dev/null || true

# Quick sanity check
echo "Setup complete."
echo "Saved: /one-piece/index.html"
echo "Title check:" && grep -m1 -o 'One Piece Terminal - Straw Hat Pirates Database' /one-piece/index.html || true
echo "Namespace 'one-piece' ensured."
ls -lh /one-piece/index.html
