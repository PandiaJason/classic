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
* **90 epic and challenging levels**: test your skills across six tier difficulties (master, legend, nightmare, insane, cosmic, and ultimate) with tougher jumps, moving hazards, and tricky gravity puzzles.
* **star gates**: collect stars on completed levels to unlock the higher difficulty tiers as you progress.
* **visual variety**: experience beautiful visual shifts as you advance tiers, featuring unique background cosmic nebula colors and matching colored gravity well shields.
* **smooth cinematic camera**: the camera follows your scooter smoothly while keeping the action easy to see.
* **colorful cartoon space worlds**: explore vibrant planets with shiny bubble shields and cool sci-fi visuals.
* **awesome space music**: enjoy an original soundtrack packed with energetic cosmic vibes.

can you become the ultimate space courier? deliver every package safely, collect every ruby, and earn perfect ratings on every level!

---

## 🚀 Quick Commands

### Compile for All Platforms (macOS + Windows + Linux)

```bash
cd "/Users/admin/jas games/ranotot" && \
rm -rf exports && mkdir -p exports && \
/Users/admin/Downloads/Godot.app/Contents/MacOS/Godot --path "/Users/admin/jas games/ranotot" --export-release "macOS" "/Users/admin/jas games/ranotot/exports/ranotot.zip" --headless && \
unzip -qo exports/ranotot.zip -d exports/ && rm exports/ranotot.zip && \
/Users/admin/Downloads/Godot.app/Contents/MacOS/Godot --path "/Users/admin/jas games/ranotot" --export-release "Windows Desktop" "/Users/admin/jas games/ranotot/exports/ranotot.exe" --headless && \
/Users/admin/Downloads/Godot.app/Contents/MacOS/Godot --path "/Users/admin/jas games/ranotot" --export-release "Linux" "/Users/admin/jas games/ranotot/exports/ranotot_linux.x86_64" --headless && \
echo "✅ ALL BUILDS DONE" && ls -lh exports/
```

### Compile macOS Only

```bash
cd "/Users/admin/jas games/ranotot" && \
rm -rf exports && mkdir -p exports && \
/Users/admin/Downloads/Godot.app/Contents/MacOS/Godot --path "/Users/admin/jas games/ranotot" --export-release "macOS" "/Users/admin/jas games/ranotot/exports/ranotot.zip" --headless && \
unzip -qo exports/ranotot.zip -d exports/ && rm exports/ranotot.zip && \
echo "✅ macOS BUILD DONE"
```

### Compile Windows Only

```bash
cd "/Users/admin/jas games/ranotot" && \
mkdir -p exports && \
/Users/admin/Downloads/Godot.app/Contents/MacOS/Godot --path "/Users/admin/jas games/ranotot" --export-release "Windows Desktop" "/Users/admin/jas games/ranotot/exports/ranotot.exe" --headless && \
echo "✅ Windows BUILD DONE"
```

### Compile Linux Only

```bash
cd "/Users/admin/jas games/ranotot" && \
mkdir -p exports && \
/Users/admin/Downloads/Godot.app/Contents/MacOS/Godot --path "/Users/admin/jas games/ranotot" --export-release "Linux" "/Users/admin/jas games/ranotot/exports/ranotot_linux.x86_64" --headless && \
echo "✅ Linux BUILD DONE"
```

---

## 📦 Git Commands

### Commit & Push All Changes

```bash
cd "/Users/admin/jas games/ranotot" && \
git add . && \
git commit -m "Your commit message here" && \
git push origin main
```

### Commit, Compile All, and Push (Full Pipeline)

```bash
cd "/Users/admin/jas games/ranotot" && \
git add . && \
git commit -m "Your commit message here" && \
rm -rf exports && mkdir -p exports && \
/Users/admin/Downloads/Godot.app/Contents/MacOS/Godot --path "/Users/admin/jas games/ranotot" --export-release "macOS" "/Users/admin/jas games/ranotot/exports/ranotot.zip" --headless && \
unzip -qo exports/ranotot.zip -d exports/ && rm exports/ranotot.zip && \
/Users/admin/Downloads/Godot.app/Contents/MacOS/Godot --path "/Users/admin/jas games/ranotot" --export-release "Windows Desktop" "/Users/admin/jas games/ranotot/exports/ranotot.exe" --headless && \
/Users/admin/Downloads/Godot.app/Contents/MacOS/Godot --path "/Users/admin/jas games/ranotot" --export-release "Linux" "/Users/admin/jas games/ranotot/exports/ranotot_linux.x86_64" --headless && \
git push origin main && \
echo "✅ COMMIT + COMPILE + PUSH DONE"
```

### Check Git Status

```bash
cd "/Users/admin/jas games/ranotot" && git status
```

### View Recent Commits

```bash
cd "/Users/admin/jas games/ranotot" && git log --oneline -10
```

---

## 🔧 Level Generation

Levels are generated using the Python script. Run this if you change level layouts:

```bash
cd "/Users/admin/godot connector" && \
python3 generate_levels.py && \
echo "✅ LEVELS REGENERATED"
```

> ⚠️ After regenerating levels, you must recompile the game!

---

## 🗂️ Project Structure

```
ranotot/
├── assets/          # Textures, fonts, icons
├── scenes/          # .tscn scene files (levels, UI, entities)
├── scripts/         # .gd GDScript files
│   ├── player_2d.gd       # Player physics, gravity, jump
│   ├── in_game_ui.gd      # Camera system, HUD, map/hint buttons
│   ├── planet.gd           # Planet gravity, types, visuals
│   ├── asteroid.gd         # Asteroid behavior
│   ├── asteroid_manager.gd # Asteroid spawning
│   ├── game_manager.gd     # Game flow, scoring
│   ├── save_system.gd      # Save/load progress
│   ├── ui_factory.gd       # Reusable UI components
│   └── resource_manager.gd # Texture caching
├── shaders/         # Visual shaders (blur, bubble)
├── exports/         # Compiled builds (not in git)
├── export_presets.cfg  # Build configurations
└── project.godot    # Godot project settings
```

---

## 🎮 Game Mechanics

- **Gravity**: Each planet has its own gravity field. Player orbits on the surface.
- **Jump**: Space/Up arrow to jump off a planet into zero gravity.
- **Camera**: Fixed zoom (0.5) for all levels. Stays still on planets, scrolls with deadzone in zero-G.
- **Death**: Leaving level map bounds OR getting hit by an asteroid.
- **Hint**: Tap to show trajectory (only while on a planet, one use per level).
- **Map**: Tap to see full level for 3 seconds.
- **Delivery Box**: Loses health when hit by asteroids. Reach the flag planet to complete.
- **Stars**: 1-3 stars based on remaining box health.

---

## 📋 Build Outputs

| Platform | File | Location |
|----------|------|----------|
| macOS | `ranotot.app` | `exports/ranotot.app` |
| Windows | `ranotot.exe` + `ranotot.pck` | `exports/` |
| Linux | `ranotot_linux.x86_64` | `exports/` |

---

## 🎵 Audio

- **Menu BGM**: `Slow_Clockwork_Sun.mp3`
- **In-Game BGM**: `Petal_Path_Dash.mp3`

Music toggle is saved between sessions.

---

*copyright by hikki studios*
