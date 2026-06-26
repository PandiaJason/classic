# ranotot

hop on your scooter and become the galaxy’s craziest delivery driver!

race across dangerous worlds, launch between planets, dodge deadly asteroids, and deliver fragile cargo without crashing. use each world’s gravity to build momentum, soar through space, and land safely on your next destination.

one bad jump… and you’ll drift forever into the endless void.

## gameplay

### ride around entire planets
every world has its own gravity field. drive in full 360° around planets, build speed, and launch yourself toward the next destination.

### master perfect jumps
timing is everything. jump too early or too late and your delivery could be lost in deep space.

### glide & speed assists
collect rubies and spend them in the shop on glide assists to correct your trajectory or speed assists to blast through zero-gravity sections.

### dodge dangerous asteroids
watch for incoming space rocks that can damage your cargo and ruin a perfect run.

### collect valuable rubies
find hidden rubies to buy upgrades, unlock progression gates, and achieve perfect 3-star ratings.

## features
* **90 handcrafted levels**: progress through escalations of speed, orbit sizes, and tricky jump layouts.
* **6 escalating difficulty tiers**: unlock master, legend, nightmare, insane, cosmic, and ultimate stages.
* **9 unique cosmic visual themes**: experience different background nebula visual variations as you change tiers.
* **star gates**: collect stars to unlock higher tiers and test your mastery.
* **daily rewards & streak bonuses**: log in consecutively to claim rubies from your calendar on the menu.
* **smooth cinematic camera**: camera follows your scooter automatically with a comfortable follow focus.
* **fast arcade-style level starts**: jump right back into the action instantly after crashing.
* **colorful cartoon sci-fi visuals**: enjoy gorgeous, bright planetary systems and sci-fi aesthetic.
* **original energetic soundtrack**: custom soundtrack designed to keep the momentum going.
* **movie-style end credits**: skip or watch the full scrolling credits list after beat level 90.
* **windows, linux, macos, and web support**: play natively or in a browser.

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
