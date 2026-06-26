# ranotot

Hop on your scooter and become the galaxy’s craziest delivery driver!

Race across dangerous worlds, launch between planets, dodge deadly asteroids, and deliver fragile cargo without crashing. Use each world’s gravity to build momentum, soar through space, and land safely on your next destination.

One bad jump… and you’ll drift forever into the endless void. play online: https://ranotot.vercel.app/

## Gameplay

### Ride Around Entire Planets
Every world has its own gravity field. Drive in full 360° around planets, build speed, and launch yourself toward the next destination.

### Master Perfect Jumps
Timing is everything. Jump too early or too late and your delivery could be lost in deep space.

### Glide & Speed Assists
Collect rubies and spend them in the shop on Glide Assists to correct your trajectory or Speed Assists to blast through zero-gravity sections.

### Dodge Dangerous Asteroids
Watch for incoming space rocks that can damage your cargo and ruin a perfect run.

### Collect Valuable Rubies
Find hidden rubies to buy upgrades, unlock progression gates, and achieve perfect 3-star ratings.

## Features
* **90 handcrafted levels**
* **6 escalating difficulty tiers**
* **9 unique cosmic visual themes**
* **Star Gates that unlock new challenges**
* **Daily rewards and streak bonuses**
* **Smooth cinematic camera system**
* **Fast arcade-style level starts**
* **Colorful cartoon sci-fi visuals**
* **Original energetic soundtrack**
* **Movie-style end credits**
* **Windows, Linux, and macOS support** (with web app play online!)

### Can You Become the Ultimate Space Courier?
Deliver every package safely. Collect every ruby. Earn every star.

Master gravity. Conquer the galaxy. Become the ultimate courier.


---

## controls & mappings

### keyboard & mouse
* **jump/glide**: Space or Up Arrow
* **speed boost**: Shift Key
* **toggle hint**: H Key
* **view full map**: M Key (shows map for 3 seconds)
* **pause menu**: Esc / Escape Key

### gamepad (xbox/playstation)
* **jump/glide**: A Button (Cross on PlayStation)
* **speed boost**: X Button (Square on PlayStation)
* **toggle hint**: L Button (Left Shoulder / L1)
* **view full map**: R Button (Right Shoulder / R1)
* **pause menu**: Start Button (Options / Menu)
* **ui navigation**: D-pad or Left Joystick to navigate menus; A Button to select
* **level select scrolling**: Right Joystick (lever) to scroll vertically/horizontally through the level select grid smoothly (focus automatically snaps to the center button)

## haptic feedback (controller rumble)
the game features premium, lightweight vibration haptics that play on your gamepad for the following events:
* **planet landing**: a light, good vibration on impact
* **jumping**: a brief, subtle launch pulse
* **glide start**: a quick initial glide trigger vibration (no continuous wear-and-tear rumble)
* **collecting rubies**: a very light, satisfying collection pulse
* **asteroid collision**: a solid, defensive package damage rumble
* **taking jump damage**: a quick impact warning pulse

> [!NOTE]
> **web browser haptics**: web exports support haptic feedback over HTTPS via a custom JavaScript bridge actuator fallback. if vibration is missing in Chrome/Edge on macOS, check the browser console. macOS Bluetooth controller drivers often block vibration signals to the Web Gamepad API. connect your controller via USB or play on Windows/Android to experience full web haptics.

## 🚀 quick commands

### compile for all platforms
compiles all binary builds, packages installers/setups, and updates the web assets. this command preserves Vercel configuration files:
```bash
cd "/Users/admin/Jas Games/ranotot" && \
mkdir -p exports && \
/Users/admin/Downloads/Godot.app/Contents/MacOS/Godot --path "/Users/admin/Jas Games/ranotot" --export-release "macOS" "/Users/admin/Jas Games/ranotot/exports/ranotot.dmg" --headless && \
/Users/admin/Downloads/Godot.app/Contents/MacOS/Godot --path "/Users/admin/Jas Games/ranotot" --export-release "Windows Desktop" "/Users/admin/Jas Games/ranotot/exports/ranotot.exe" --headless && \
makensis setup.nsi && \
/Users/admin/Downloads/Godot.app/Contents/MacOS/Godot --path "/Users/admin/Jas Games/ranotot" --export-release "Linux" "/Users/admin/Jas Games/ranotot/exports/ranotot_linux.x86_64" --headless && \
python3 create_linux_installer.py && \
mkdir -p exports/web && \
/Users/admin/Downloads/Godot.app/Contents/MacOS/Godot --path "/Users/admin/Jas Games/ranotot" --export-release "Web" "/Users/admin/Jas Games/ranotot/exports/web/game.html" --headless && \
mkdir -p exports/ranotot_Web && \
/Users/admin/Downloads/Godot.app/Contents/MacOS/Godot --path "/Users/admin/Jas Games/ranotot" --export-release "Web" "/Users/admin/Jas Games/ranotot/exports/ranotot_Web/index.html" --headless && \
echo "✅ ALL PLATFORM BUILDS & INSTALLERS COMPILED"
```

### deploy to vercel (web app)
promotes the local compiled web target directly to the live production server:
```bash
cd "/Users/admin/Jas Games/ranotot/exports/web" && npx vercel --prod --yes
```

## 📦 git commands

### commit & push changes
```bash
cd "/Users/admin/Jas Games/ranotot" && \
git add . && \
git commit -m "Your commit message here" && \
git push origin main
```

## 🔧 level generation
levels are generated using a Python layout script:
```bash
cd "/Users/admin/godot connector" && python3 generate_levels.py
```
> ⚠️ After regenerating levels, you must recompile the game exports!

## 📋 build outputs (final kept versions)

| Platform | Output File | Path |
|----------|-------------|------|
| macOS | `ranotot.dmg` | `exports/ranotot.dmg` |
| Windows | `ranotot_setup.exe` (Installer) | `exports/ranotot_setup.exe` |
| Linux | `ranotot_linux_setup.sh` (Self-extracting setup) | `exports/ranotot_linux_setup.sh` |
| Web (Vercel) | `game.html` + `index.html` | `exports/web/` |
| Web (Direct) | `index.html` + `index.pck` | `exports/ranotot_Web/` |

## 🎵 audio
* **menu bgm**: `Slow_Clockwork_Sun.mp3`
* **in-game bgm**: `Petal_Path_Dash.mp3`

audio setting states are automatically saved between sessions.

---
*copyright by hikki studios*
