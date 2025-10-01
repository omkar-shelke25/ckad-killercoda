#!/bin/bash
set -euo pipefail

echo "Preparing One Piece lab environment..."

# Create the one-piece directory
mkdir -p /one-piece

# Create the index.html file with One Piece terminal theme content
cat > /one-piece/index.html << 'HTMLEOF'



    
    
    One Piece Terminal - Straw Hat Pirates Database
    
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
    


    
        
            
            
            
            terminal@straw-hat-pirates
        
        
        
            
    ____  _   _ _____   ____  ___ _____ ____ _____ 
   / __ \| \ | | ____| |  _ \|_ _| ____/ ___| ____|
  | |  | |  \| |  _|   | |_) || ||  _|| |   |  _|  
  | |__| | |\  | |___  |  __/ | || |__| |___| |___ 
   \____/|_| \_|_____| |_|   |___|_____\____|_____|
            

            cat straw_hat_crew.db
            
            
                Loading Straw Hat Pirates Database...
                Access Granted: Marine Intelligence Level 5
                ========================================
            

            >> CREW OVERVIEW
            
                Ship: Thousand Sunny
                Total Members: 10
                Total Bounty: 8,816,001,000 Berries
                Status: Active - Yonko Crew
            

            >> CREW MEMBERS DATA

            
                [ 01 ] MONKEY D. LUFFY
                Position: Captain
                Age: 19
                Bounty: 3,000,000,000 Berries
                Devil Fruit: Gomu Gomu no Mi (Hito Hito no Mi, Model: Nika)
                Abilities: Gear 5, Advanced Haki (All Three Types), Rubber Body
                Dream: Become King of the Pirates
            

            
                [ 02 ] RORONOA ZORO
                Position: Swordsman / First Mate
                Age: 21
                Bounty: 1,111,000,000 Berries
                Fighting Style: Three-Sword Style (Santoryu)
                Abilities: Advanced Conqueror's Haki, Enma Mastery
                Dream: Become the World's Greatest Swordsman
            

            
                [ 03 ] NAMI
                Position: Navigator
                Age: 20
                Bounty: 366,000,000 Berries
                Weapon: Clima-Tact (Weather Manipulation)
                Abilities: Master Navigator, Weather Prediction, Zeus Control
                Dream: Draw a Complete Map of the World
            

            
                [ 04 ] USOPP
                Position: Sniper
                Age: 19
                Bounty: 500,000,000 Berries
                Weapon: Kabuto (Slingshot)
                Abilities: Observation Haki, Expert Marksman, Inventor
                Dream: Become a Brave Warrior of the Sea
            

            
                [ 05 ] SANJI
                Position: Cook
                Age: 21
                Bounty: 1,032,000,000 Berries
                Fighting Style: Black Leg Style (Kicks)
                Abilities: Ifrit Jambe, Germa Exoskeleton, Observation Haki
                Dream: Find the All Blue
            

            
                [ 06 ] TONY TONY CHOPPER
                Position: Doctor
                Age: 17
                Bounty: 1,000 Berries
                Devil Fruit: Hito Hito no Mi (Human-Human Fruit)
                Abilities: Monster Point, Rumble Ball, Medical Expertise
                Dream: Cure All Diseases
            

            
                [ 07 ] NICO ROBIN
                Position: Archaeologist
                Age: 30
                Bounty: 930,000,000 Berries
                Devil Fruit: Hana Hana no Mi (Flower-Flower Fruit)
                Abilities: Demonio Fleur, Poneglyph Reading, Armament Haki
                Dream: Uncover the True History
            

            
                [ 08 ] FRANKY
                Position: Shipwright
                Age: 36
                Bounty: 394,000,000 Berries
                Type: Cyborg
                Abilities: Franky Shogun, Radical Beam, Vegapunk Technology
                Dream: Build a Dream Ship and Sail it to the End
            

            
                [ 09 ] BROOK
                Position: Musician
                Age: 90
                Bounty: 383,000,000 Berries
                Devil Fruit: Yomi Yomi no Mi (Revive-Revive Fruit)
                Abilities: Soul Manipulation, Ice Powers, Master Swordsman
                Dream: Reunite with Laboon
            

            
                [ 10 ] JINBE
                Position: Helmsman
                Age: 46
                Bounty: 1,100,000,000 Berries
                Species: Fish-Man (Whale Shark)
                Abilities: Fish-Man Karate, Advanced Armament Haki, Water Manipulation
                Dream: Achieve Equality Between Races
            

            
                ========================================
                End of Database Query
                Note: These Pirates are extremely dangerous!
            

            
                
            
        
    


HTMLEOF
