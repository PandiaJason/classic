# ranotot

hop on your space scooter and become the galaxy’s craziest delivery driver!

in ranotot, you race through space, jump between planets, dodge dangerous asteroids, and deliver fragile cargo without crashing. use each planet’s gravity to ride around it, launch into space, and land safely on the next world.

one bad jump… and you’ll drift forever into the endless void!

## gameplay
* **ride around planets**: every planet has its own gravity. drive all around them in full 360° movement and use gravity to fly to the next planet.
* **master perfect jumps**: timing matters! jump too soon or too late and you could miss your landing completely.
* **glide assist**: use your collected rubies in the shop to buy glide assists to redirect your velocity in zero-gravity space when you miss a jump!
* **dodge asteroids**: watch out for fast-moving space rocks that can damage your delivery box.
* **collect space rubies**: grab glowing rubies hidden around levels to increase your score, buy powerups, and earn 3-star ratings.

## features
* **90 challenge-packed levels**: test your skills across six difficulty tiers (master, legend, nightmare, insane, cosmic, and ultimate) with tougher jumps, moving hazards, and tricky gravity puzzles.
* **star gates**: collect stars on completed levels to unlock the higher difficulty tiers as you progress.
* **daily rewards streak**: open the daily rewards calendar in the main menu to claim bonus rubies for playing consecutive days.
* **visual variety**: experience beautiful visual shifts as you advance tiers, featuring unique background cosmic nebula colors and matching colored gravity well shields.
* **smooth cinematic camera**: the camera follows your scooter smoothly while keeping the action easy to see.
* **colorful cartoon space worlds**: explore vibrant planets with shiny bubble shields and cool sci-fi visuals.
* **awesome space music**: enjoy an original soundtrack packed with energetic cosmic vibes.

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
compiles all binary builds and updates the web assets. this command preserves Vercel configuration files:
```bash
cd "/Users/admin/Jas Games/ranotot" && \
mkdir -p exports && \
/Users/admin/Downloads/Godot.app/Contents/MacOS/Godot --path "/Users/admin/Jas Games/ranotot" --export-release "macOS" "/Users/admin/Jas Games/ranotot/exports/ranotot.zip" --headless && \
unzip -qo exports/ranotot.zip -d exports/ && rm -f exports/ranotot.zip && \
/Users/admin/Downloads/Godot.app/Contents/MacOS/Godot --path "/Users/admin/Jas Games/ranotot" --export-release "Windows Desktop" "/Users/admin/Jas Games/ranotot/exports/ranotot.exe" --headless && \
/Users/admin/Downloads/Godot.app/Contents/MacOS/Godot --path "/Users/admin/Jas Games/ranotot" --export-release "Linux" "/Users/admin/Jas Games/ranotot/exports/ranotot_linux.x86_64" --headless && \
mkdir -p exports/web && \
/Users/admin/Downloads/Godot.app/Contents/MacOS/Godot --path "/Users/admin/Jas Games/ranotot" --export-release "Web" "/Users/admin/Jas Games/ranotot/exports/web/game.html" --headless && \
mkdir -p exports/ranotot_Web && \
/Users/admin/Downloads/Godot.app/Contents/MacOS/Godot --path "/Users/admin/Jas Games/ranotot" --export-release "Web" "/Users/admin/Jas Games/ranotot/exports/ranotot_Web/index.html" --headless && \
echo "✅ ALL PLATFORM BUILDS COMPILED"
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
| macOS | `ranotot.app` | `exports/ranotot.app` |
| Windows | `ranotot.exe` + `ranotot.pck` | `exports/` |
| Linux | `ranotot_Linux.x86_64` | `exports/` |
| Web (Vercel) | `game.html` + `index.html` | `exports/web/` |
| Web (Direct) | `index.html` + `index.pck` | `exports/ranotot_Web/` |

## 🎵 audio
* **menu bgm**: `Slow_Clockwork_Sun.mp3`
* **in-game bgm**: `Petal_Path_Dash.mp3`

audio setting states are automatically saved between sessions.

---
*copyright by hikki studios*
