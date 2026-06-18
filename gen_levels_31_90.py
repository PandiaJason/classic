#!/usr/bin/env python3
"""
Generate levels 31-90 for Ranotot.
Each level has a unique geometric layout with progressive difficulty.
Output: /Users/admin/Jas Games/ranotot/scenes/level_{N}.tscn
"""

import math
import os

OUTPUT_DIR = "/Users/admin/Jas Games/ranotot/scenes"

# ─── Planet type constants ───
BASIC = 0      # large, strong gravity
MEDIUM = 1     # medium
SMALL = 2      # small, weak gravity
CHALLENGE = 3  # finish portal


def make_uid(lvl: int) -> int:
    return 5000 + lvl * 73


def build_planet_node(index: int, x: int, y: int, ptype: int, scale: float | None = None) -> str:
    """Build a single planet node string."""
    lines = []
    lines.append(f'[node name="Planet{index}" parent="Planets" groups=["planets"] instance=ExtResource("1_planet")]')
    lines.append(f"position = Vector2({x}, {y})")
    if scale is not None and abs(scale - 1.0) > 0.01:
        sc = round(scale, 2)
        lines.append(f"scale = Vector2({sc}, {sc})")
    lines.append(f"type = {ptype}")
    return "\n".join(lines)


def build_scene(lvl: int, planets: list[dict], zoom: float) -> str:
    """
    Build a complete .tscn scene string.
    planets: list of dicts with keys x, y, ptype, and optional scale.
    The last planet MUST be type 3 (CHALLENGE).
    """
    uid = make_uid(lvl)

    # Player starts above the first planet
    start_x = planets[0]["x"]
    start_y = planets[0]["y"] - 220

    # Camera = center of all planets
    cx = sum(p["x"] for p in planets) // len(planets)
    cy = sum(p["y"] for p in planets) // len(planets)

    # Build planet nodes
    planet_strs = []
    for i, p in enumerate(planets, start=1):
        planet_strs.append(build_planet_node(i, p["x"], p["y"], p["ptype"], p.get("scale")))

    planet_block = "\n\n".join(planet_strs)

    zoom_r = round(zoom, 2)

    # Determine background modulation based on level tier
    if lvl >= 81:
        mod_color = "Color(0.4, 0.15, 0.3, 1)" # Ultimate: Magenta/Pink
    elif lvl >= 71:
        mod_color = "Color(0.15, 0.35, 0.4, 1)" # Cosmic: Cyan/Teal
    elif lvl >= 61:
        mod_color = "Color(0.4, 0.25, 0.1, 1)" # Insane: Orange/Gold
    elif lvl >= 51:
        mod_color = "Color(0.15, 0.35, 0.2, 1)" # Nightmare: Green
    elif lvl >= 41:
        mod_color = "Color(0.3, 0.15, 0.4, 1)" # Legend: Purple
    else:
        mod_color = "Color(0.4, 0.4, 0.4, 1)" # Master: Default/Blue

    scene = f'''[gd_scene load_steps=3 format=3 uid="uid://level_{lvl}_uid_{uid}"]

[ext_resource type="PackedScene" path="res://scenes/planet.tscn" id="1_planet"]
[ext_resource type="PackedScene" path="res://scenes/player_2d.tscn" id="2_player"]
[ext_resource type="Texture2D" path="res://assets/bg_ref.jpg" id="3_bg"]
[ext_resource type="AudioStream" path="res://Slow_Clockwork_Sun.mp3" id="5_bgm"]
[ext_resource type="Script" path="res://scripts/in_game_ui.gd" id="6_ui"]

[node name="Main" type="Node2D"]

[node name="Background" type="CanvasLayer" parent="."]
layer = -1

[node name="TextureRect" type="TextureRect" parent="Background"]
modulate = {mod_color}
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
texture = ExtResource("3_bg")
expand_mode = 1
stretch_mode = 6

[node name="Planets" type="Node2D" parent="."]

{planet_block}


[node name="Player2D" parent="." instance=ExtResource("2_player")]
position = Vector2({start_x}, {start_y})

[node name="Camera2D" type="Camera2D" parent="."]
position = Vector2({cx}, {cy})
zoom = Vector2({zoom_r}, {zoom_r})

[node name="BGM" type="AudioStreamPlayer" parent="."]
stream = ExtResource("5_bgm")

[node name="InGameUI" type="CanvasLayer" parent="."]
layer = 5
script = ExtResource("6_ui")

'''
    return scene


# ═══════════════════════════════════════════════════════════════════
# LEVEL DESIGN FUNCTIONS
# Each returns a list of planet dicts: {x, y, ptype, scale (optional)}
# Last planet is ALWAYS type=3 (CHALLENGE/finish)
# ═══════════════════════════════════════════════════════════════════

def p(x, y, ptype, scale=None):
    """Shorthand planet dict builder."""
    d = {"x": int(x), "y": int(y), "ptype": ptype}
    if scale is not None:
        d["scale"] = scale
    return d


# ──────────────────────────────────────────────────────────
# MASTER TIER (31-40): 8-9 planets, zoom 0.24-0.28
# ──────────────────────────────────────────────────────────

def level_31():
    """Helix — planets spiral upward in a helix pattern"""
    planets = []
    cx, cy = 500, 2000
    for i in range(8):
        angle = i * math.pi * 0.55
        r = 400 + i * 120
        x = cx + int(r * math.cos(angle))
        y = cy - i * 350
        types = [BASIC, MEDIUM, SMALL, MEDIUM, BASIC, SMALL, MEDIUM, SMALL]
        planets.append(p(x, y, types[i]))
    # Replace last with finish
    planets.append(p(cx + 200, cy - 8 * 350 - 200, CHALLENGE))
    return planets, 0.26


def level_32():
    """Hourglass — pinch in the middle, wide at top and bottom"""
    planets = [
        p(0, 0, BASIC),
        p(800, 200, MEDIUM),
        p(400, 600, SMALL, 0.8),
        p(350, 1100, SMALL, 0.7),
        p(0, 1600, MEDIUM),
        p(800, 1800, BASIC),
        p(400, 2200, MEDIUM),
        p(1000, 2600, SMALL),
        p(500, 3000, CHALLENGE),
    ]
    return planets, 0.25


def level_33():
    """Cross — planets form a + shape, player navigates the arms"""
    cx, cy = 2000, 2000
    planets = [
        p(cx - 1200, cy, BASIC),       # left arm start
        p(cx - 600, cy, MEDIUM),
        p(cx, cy, SMALL, 0.8),         # center
        p(cx + 600, cy, MEDIUM),
        p(cx, cy - 800, SMALL),        # top arm
        p(cx, cy + 800, BASIC),        # bottom arm
        p(cx + 600, cy - 600, MEDIUM),
        p(cx + 1200, cy - 400, SMALL),
        p(cx + 1800, cy, CHALLENGE),
    ]
    return planets, 0.24


def level_34():
    """Reverse spiral — spiral inward from outside to center"""
    planets = []
    cx, cy = 2000, 2000
    for i in range(8):
        angle = i * math.pi * 0.6
        r = 1600 - i * 180
        x = cx + int(r * math.cos(angle))
        y = cy + int(r * math.sin(angle))
        types = [BASIC, SMALL, MEDIUM, SMALL, BASIC, MEDIUM, SMALL, MEDIUM]
        planets.append(p(x, y, types[i]))
    planets.append(p(cx, cy, CHALLENGE, 0.9))
    return planets, 0.24


def level_35():
    """Funnel — wide at top, narrows to a tight bottom exit"""
    planets = [
        p(0, 0, BASIC),
        p(1600, 0, MEDIUM),
        p(200, 600, SMALL, 0.8),
        p(1400, 600, SMALL, 0.8),
        p(400, 1200, MEDIUM),
        p(1200, 1200, BASIC),
        p(700, 1800, SMALL, 0.7),
        p(900, 2400, SMALL, 0.6),
        p(800, 3000, CHALLENGE),
    ]
    return planets, 0.25


def level_36():
    """Staircase — ascending steps with alternating direction"""
    planets = [
        p(0, 2400, BASIC),
        p(500, 2000, MEDIUM),
        p(0, 1600, SMALL),
        p(600, 1200, MEDIUM),
        p(100, 800, SMALL, 0.8),
        p(700, 400, BASIC),
        p(200, 0, MEDIUM),
        p(800, -400, SMALL),
        p(400, -800, CHALLENGE),
    ]
    return planets, 0.26


def level_37():
    """Bowtie — two triangles meeting at a point"""
    planets = [
        p(0, 0, BASIC),
        p(500, 500, MEDIUM),
        p(0, 1000, SMALL),
        p(500, 500, MEDIUM),       # pivot — shared center
        # second triangle, going right
        p(1000, 0, SMALL, 0.8),
        p(1500, 500, BASIC),
        p(1000, 1000, MEDIUM),
        p(1800, 800, SMALL),
        p(2200, 500, CHALLENGE),
    ]
    # Fix: remove duplicate center, adjust
    planets = [
        p(0, 0, BASIC),
        p(400, 600, MEDIUM),
        p(0, 1200, SMALL),
        p(500, 600, SMALL, 0.7),   # narrow center
        p(1000, 0, MEDIUM),
        p(1000, 1200, BASIC),
        p(1500, 600, SMALL, 0.8),
        p(2000, 200, MEDIUM),
        p(2500, 600, CHALLENGE),
    ]
    return planets, 0.27


def level_38():
    """Zigzag vertical — sharp up-down path"""
    planets = [
        p(200, 3000, BASIC),
        p(800, 2400, MEDIUM),
        p(200, 1800, SMALL),
        p(900, 1200, MEDIUM),
        p(200, 600, SMALL, 0.8),
        p(800, 0, BASIC),
        p(200, -600, SMALL),
        p(900, -1200, MEDIUM),
        p(500, -1800, CHALLENGE),
    ]
    return planets, 0.24


def level_39():
    """Diamond — four corners connected through center"""
    cx, cy = 1500, 1500
    planets = [
        p(cx, cy - 1200, BASIC),        # top
        p(cx + 600, cy - 600, MEDIUM),
        p(cx + 1200, cy, SMALL),         # right
        p(cx + 600, cy + 600, MEDIUM),
        p(cx, cy + 1200, BASIC),         # bottom
        p(cx - 600, cy + 600, SMALL, 0.8),
        p(cx - 1200, cy, MEDIUM),        # left
        p(cx - 600, cy - 600, SMALL),
        p(cx, cy, CHALLENGE, 0.9),       # center finish
    ]
    return planets, 0.25


def level_40():
    """Arc bridge — semicircular bridge with planet gaps"""
    planets = []
    cx, cy = 2000, 2000
    n = 8
    for i in range(n):
        angle = math.pi + i * (math.pi / (n - 1))
        r = 1400
        x = cx + int(r * math.cos(angle))
        y = cy + int(r * math.sin(angle))
        types = [BASIC, SMALL, MEDIUM, SMALL, MEDIUM, SMALL, BASIC, SMALL]
        sc = [None, 0.8, None, 0.7, None, 0.6, None, 0.7]
        planets.append(p(x, y, types[i], sc[i]))
    planets.append(p(cx + 1600, cy - 400, CHALLENGE))
    return planets, 0.24


# ──────────────────────────────────────────────────────────
# LEGEND TIER (41-50): 9-10 planets, zoom 0.22-0.26
# ──────────────────────────────────────────────────────────

def level_41():
    """Double diamond — two diamonds connected by a bridge"""
    planets = [
        p(0, 800, BASIC),
        p(500, 0, MEDIUM),
        p(1000, 800, SMALL, 0.8),
        p(500, 1600, MEDIUM),
        # bridge
        p(1500, 800, SMALL, 0.6),
        # second diamond
        p(2000, 0, MEDIUM),
        p(2500, 800, BASIC),
        p(2000, 1600, SMALL),
        p(2700, 1200, MEDIUM),
        p(3200, 800, CHALLENGE),
    ]
    return planets, 0.24


def level_42():
    """Zigzag canyon — tight horizontal zigzag through a canyon"""
    planets = [
        p(0, 0, BASIC),
        p(500, 400, SMALL, 0.8),
        p(1000, -200, MEDIUM),
        p(1500, 400, SMALL, 0.7),
        p(2000, -300, MEDIUM),
        p(2500, 500, SMALL, 0.6),
        p(3000, -100, BASIC),
        p(3500, 600, SMALL, 0.7),
        p(4000, 0, MEDIUM),
        p(4500, 400, CHALLENGE),
    ]
    return planets, 0.22


def level_43():
    """Orbital ring — planets in an elliptical ring"""
    planets = []
    cx, cy = 2000, 1500
    n = 9
    for i in range(n):
        angle = i * 2 * math.pi / n
        rx, ry = 1600, 1000
        x = cx + int(rx * math.cos(angle))
        y = cy + int(ry * math.sin(angle))
        types = [BASIC, MEDIUM, SMALL, MEDIUM, SMALL, BASIC, SMALL, MEDIUM, SMALL]
        scales = [None, None, 0.8, None, 0.7, None, 0.6, None, 0.7]
        planets.append(p(x, y, types[i], scales[i]))
    planets.append(p(cx, cy, CHALLENGE, 0.8))  # center finish
    return planets, 0.22


def level_44():
    """Galaxy arm — curved arm sweeping outward"""
    planets = []
    cx, cy = 1000, 2000
    for i in range(9):
        angle = i * 0.7
        r = 400 + i * 250
        x = cx + int(r * math.cos(angle))
        y = cy - int(r * math.sin(angle))
        types = [BASIC, MEDIUM, SMALL, MEDIUM, SMALL, SMALL, MEDIUM, SMALL, BASIC]
        scales = [None, None, 0.8, None, 0.7, 0.6, None, 0.7, None]
        planets.append(p(x, y, types[i], scales[i]))
    planets.append(p(planets[-1]["x"] + 500, planets[-1]["y"] - 300, CHALLENGE))
    return planets, 0.23


def level_45():
    """Arrow — planets form an arrow pointing right"""
    planets = [
        p(0, 1000, BASIC),
        p(600, 1000, MEDIUM),
        p(1200, 1000, SMALL, 0.8),
        p(1800, 1000, MEDIUM),      # shaft
        p(2400, 600, SMALL, 0.7),   # upper barb
        p(2400, 1400, SMALL, 0.7),  # lower barb
        p(2800, 400, MEDIUM),
        p(2800, 1600, BASIC),
        p(3200, 1000, SMALL, 0.6),  # tip
        p(3600, 1000, CHALLENGE),
    ]
    return planets, 0.24


def level_46():
    """W pattern — sharp W shape across the level"""
    planets = [
        p(0, 0, BASIC),
        p(500, 1200, MEDIUM),
        p(1000, 400, SMALL, 0.8),
        p(1500, 1400, MEDIUM),
        p(2000, 200, SMALL, 0.7),
        p(2500, 1300, BASIC),
        p(3000, 300, SMALL, 0.6),
        p(3500, 1100, MEDIUM),
        p(4000, 0, SMALL, 0.7),
        p(4500, 500, CHALLENGE),
    ]
    return planets, 0.22


def level_47():
    """Concentric circles — two concentric rings, navigate between them"""
    cx, cy = 2000, 2000
    planets = []
    # Outer ring (4 planets)
    for i in range(4):
        angle = i * math.pi / 2
        x = cx + int(1400 * math.cos(angle))
        y = cy + int(1400 * math.sin(angle))
        types = [BASIC, MEDIUM, SMALL, MEDIUM]
        planets.append(p(x, y, types[i]))
    # Inner ring (5 planets)
    for i in range(5):
        angle = i * 2 * math.pi / 5 + 0.3
        x = cx + int(700 * math.cos(angle))
        y = cy + int(700 * math.sin(angle))
        types = [SMALL, MEDIUM, SMALL, BASIC, SMALL]
        scales = [0.8, None, 0.7, None, 0.6]
        planets.append(p(x, y, types[i], scales[i]))
    planets.append(p(cx, cy, CHALLENGE))
    return planets, 0.23


def level_48():
    """Lightning bolt — jagged diagonal path"""
    planets = [
        p(0, 0, BASIC),
        p(600, 300, MEDIUM),
        p(200, 800, SMALL, 0.8),
        p(800, 1100, MEDIUM),
        p(300, 1600, SMALL, 0.7),
        p(900, 1900, BASIC),
        p(400, 2400, SMALL, 0.6),
        p(1000, 2700, MEDIUM),
        p(500, 3200, SMALL),
        p(1100, 3500, CHALLENGE),
    ]
    return planets, 0.22


def level_49():
    """Horseshoe — U shape with tight turns at the bottom"""
    planets = [
        p(0, 0, BASIC),
        p(0, 600, MEDIUM),
        p(0, 1200, SMALL, 0.8),
        p(300, 1800, SMALL, 0.6),
        p(800, 2000, MEDIUM),
        p(1300, 1800, SMALL, 0.7),
        p(1600, 1200, MEDIUM),
        p(1600, 600, BASIC),
        p(1600, 0, SMALL),
        p(2000, -400, CHALLENGE),
    ]
    return planets, 0.23


def level_50():
    """Star shape — five-pointed star traversal"""
    cx, cy = 2000, 2000
    planets = []
    # Star points and inner vertices interleaved
    for i in range(10):
        angle = i * math.pi / 5 - math.pi / 2
        r = 1400 if i % 2 == 0 else 600
        x = cx + int(r * math.cos(angle))
        y = cy + int(r * math.sin(angle))
        types = [BASIC, SMALL, MEDIUM, SMALL, BASIC, SMALL, MEDIUM, SMALL, MEDIUM, SMALL]
        scales = [None, 0.7, None, 0.6, None, 0.7, None, 0.6, None, 0.7]
        planets.append(p(x, y, types[i], scales[i]))
    # Replace last with CHALLENGE
    planets[-1]["ptype"] = CHALLENGE
    return planets, 0.22


# ──────────────────────────────────────────────────────────
# NIGHTMARE TIER (51-60): 10-11 planets, zoom 0.20-0.24
# ──────────────────────────────────────────────────────────

def level_51():
    """Chain of islands — three clusters connected by single-planet bridges"""
    planets = [
        # Cluster 1
        p(0, 0, BASIC),
        p(400, -400, MEDIUM),
        p(400, 400, SMALL),
        # Bridge
        p(1100, 0, SMALL, 0.6),
        # Cluster 2
        p(1800, -300, MEDIUM),
        p(1800, 300, BASIC),
        p(2200, 0, SMALL, 0.7),
        # Bridge
        p(2900, 200, SMALL, 0.5),
        # Cluster 3
        p(3600, -200, MEDIUM),
        p(3600, 400, SMALL),
        p(4000, 0, CHALLENGE),
    ]
    return planets, 0.22


def level_52():
    """Crescent — half-moon arc with tight spacing"""
    planets = []
    cx, cy = 2000, 2000
    n = 10
    for i in range(n):
        angle = -math.pi * 0.7 + i * (math.pi * 1.4 / (n - 1))
        r = 1500
        x = cx + int(r * math.cos(angle))
        y = cy + int(r * math.sin(angle))
        types = [BASIC, SMALL, MEDIUM, SMALL, SMALL, MEDIUM, SMALL, MEDIUM, SMALL, BASIC]
        scales = [None, 0.7, None, 0.6, 0.5, None, 0.6, None, 0.7, None]
        planets.append(p(x, y, types[i], scales[i]))
    planets.append(p(cx + 600, cy, CHALLENGE, 0.8))
    return planets, 0.20


def level_53():
    """Infinity loop — figure-eight pattern"""
    cx, cy = 2000, 1500
    planets = []
    n = 10
    for i in range(n):
        t = i * 2 * math.pi / n
        # Lemniscate of Bernoulli (figure eight)
        denom = 1 + math.sin(t) ** 2
        x = cx + int(1500 * math.cos(t) / denom)
        y = cy + int(1200 * math.sin(t) * math.cos(t) / denom)
        types = [BASIC, SMALL, MEDIUM, SMALL, MEDIUM, SMALL, BASIC, SMALL, MEDIUM, SMALL]
        scales = [None, 0.7, None, 0.6, None, 0.5, None, 0.6, None, 0.7]
        planets.append(p(x, y, types[i], scales[i]))
    planets.append(p(cx + 800, cy + 200, CHALLENGE))
    return planets, 0.21


def level_54():
    """Cross-hatch — grid-like pattern with diagonal connections"""
    planets = [
        p(0, 0, BASIC),
        p(700, 0, SMALL, 0.7),
        p(350, 500, MEDIUM),
        p(1050, 500, SMALL, 0.6),
        p(0, 1000, MEDIUM),
        p(700, 1000, SMALL, 0.7),
        p(1400, 1000, BASIC),
        p(350, 1500, SMALL, 0.5),
        p(1050, 1500, MEDIUM),
        p(700, 2000, SMALL, 0.6),
        p(1400, 2000, CHALLENGE),
    ]
    return planets, 0.23


def level_55():
    """Serpentine river — S-curves flowing horizontally"""
    planets = [
        p(0, 1000, BASIC),
        p(500, 500, SMALL, 0.7),
        p(1000, 1200, MEDIUM),
        p(1500, 400, SMALL, 0.6),
        p(2000, 1100, MEDIUM),
        p(2500, 300, SMALL, 0.5),
        p(3000, 1000, BASIC),
        p(3500, 200, SMALL, 0.6),
        p(4000, 900, MEDIUM),
        p(4500, 100, SMALL, 0.7),
        p(5000, 700, CHALLENGE),
    ]
    return planets, 0.20


def level_56():
    """Spiderweb radial — spokes radiating from center"""
    cx, cy = 2000, 2000
    planets = [p(cx, cy, BASIC)]  # center start
    spokes = 5
    for i in range(spokes):
        angle = i * 2 * math.pi / spokes
        r = 800 + (i % 2) * 400
        x = cx + int(r * math.cos(angle))
        y = cy + int(r * math.sin(angle))
        types = [SMALL, MEDIUM, SMALL, MEDIUM, SMALL]
        scales = [0.6, None, 0.7, None, 0.5]
        planets.append(p(x, y, types[i], scales[i]))
    # Outer ring connectors
    for i in range(4):
        angle = i * math.pi / 2 + math.pi / 4
        x = cx + int(1500 * math.cos(angle))
        y = cy + int(1500 * math.sin(angle))
        planets.append(p(x, y, SMALL, 0.6))
    planets.append(p(cx + 2000, cy, CHALLENGE))
    return planets, 0.20


def level_57():
    """Descending staircase — massive drops between platforms"""
    planets = [
        p(0, 0, BASIC),
        p(500, 0, SMALL, 0.7),
        p(300, 700, MEDIUM),
        p(800, 700, SMALL, 0.6),
        p(600, 1400, MEDIUM),
        p(1100, 1400, SMALL, 0.5),
        p(900, 2100, BASIC),
        p(1400, 2100, SMALL, 0.6),
        p(1200, 2800, MEDIUM),
        p(1700, 2800, SMALL, 0.7),
        p(1500, 3500, CHALLENGE),
    ]
    return planets, 0.22


def level_58():
    """Twin towers — two vertical columns with cross-jumps"""
    planets = [
        p(0, 2000, BASIC),
        p(0, 1400, MEDIUM),
        p(800, 1700, SMALL, 0.6),
        p(800, 1100, MEDIUM),
        p(0, 800, SMALL, 0.7),
        p(800, 500, SMALL, 0.5),
        p(0, 200, MEDIUM),
        p(800, -100, BASIC),
        p(400, -500, SMALL, 0.6),
        p(400, -1000, MEDIUM),
        p(400, -1500, CHALLENGE),
    ]
    return planets, 0.21


def level_59():
    """Corkscrew — tight spiral with decreasing radius"""
    planets = []
    cx, cy = 1500, 3000
    for i in range(10):
        angle = i * math.pi * 0.65
        r = 1200 - i * 100
        x = cx + int(r * math.cos(angle))
        y = cy - i * 350
        types = [BASIC, SMALL, MEDIUM, SMALL, SMALL, MEDIUM, SMALL, MEDIUM, SMALL, BASIC]
        scales = [None, 0.7, None, 0.6, 0.5, None, 0.6, None, 0.7, None]
        planets.append(p(x, y, types[i], scales[i]))
    planets.append(p(cx, cy - 10 * 350, CHALLENGE))
    return planets, 0.20


def level_60():
    """Pinball — scattered bounce-path with bumpers everywhere"""
    planets = [
        p(0, 2500, BASIC),
        p(600, 2000, SMALL, 0.6),
        p(200, 1500, MEDIUM),
        p(800, 1000, SMALL, 0.5),
        p(300, 500, SMALL, 0.6),
        p(900, 0, MEDIUM),
        p(400, -500, SMALL, 0.7),
        p(1000, -800, BASIC),
        p(500, -1300, SMALL, 0.5),
        p(1100, -1600, MEDIUM),
        p(700, -2100, CHALLENGE),
    ]
    return planets, 0.20


# ──────────────────────────────────────────────────────────
# INSANE TIER (61-70): 11-12 planets, zoom 0.18-0.22
# ──────────────────────────────────────────────────────────

def level_61():
    """DNA helix — double helix with crossing paths"""
    planets = []
    for i in range(12):
        x = i * 500
        y1 = int(600 * math.sin(i * 0.8))
        strand = i % 2
        y = y1 if strand == 0 else -y1
        types = [BASIC, SMALL, MEDIUM, SMALL, SMALL, MEDIUM, SMALL, MEDIUM, SMALL, SMALL, MEDIUM, SMALL]
        scales = [None, 0.6, None, 0.5, 0.6, None, 0.5, None, 0.6, 0.5, None, 0.6]
        planets.append(p(x, y, types[i], scales[i]))
    planets.append(p(6200, 0, CHALLENGE))
    return planets, 0.18


def level_62():
    """Pinwheel — four curved arms radiating from center"""
    cx, cy = 2500, 2500
    planets = [p(cx, cy, BASIC)]
    arms = 4
    per_arm = 3
    for arm in range(arms):
        base_angle = arm * math.pi / 2
        for j in range(per_arm):
            r = 500 + j * 500
            angle = base_angle + j * 0.3
            x = cx + int(r * math.cos(angle))
            y = cy + int(r * math.sin(angle))
            types = [SMALL, MEDIUM, SMALL]
            scales = [0.6, None, 0.5]
            planets.append(p(x, y, types[j], scales[j]))
    planets.append(p(cx + 2000, cy - 1000, CHALLENGE))
    return planets, 0.19


def level_63():
    """Asteroid field — irregular scattered field requiring careful navigation"""
    planets = [
        p(0, 0, BASIC),
        p(600, -500, SMALL, 0.5),
        p(400, 500, SMALL, 0.6),
        p(1200, 200, MEDIUM),
        p(1000, -600, SMALL, 0.5),
        p(1800, -300, SMALL, 0.6),
        p(1600, 600, MEDIUM),
        p(2400, 0, SMALL, 0.5),
        p(2200, -700, SMALL, 0.6),
        p(3000, -400, MEDIUM),
        p(2800, 500, SMALL, 0.5),
        p(3600, 0, CHALLENGE),
    ]
    return planets, 0.20


def level_64():
    """Serpentine — long winding snake path"""
    planets = [
        p(0, 0, BASIC),
        p(700, 500, SMALL, 0.6),
        p(1400, 0, MEDIUM),
        p(2100, 600, SMALL, 0.5),
        p(2800, 0, SMALL, 0.6),
        p(3500, 700, MEDIUM),
        p(4200, 100, SMALL, 0.5),
        p(4900, 600, SMALL, 0.6),
        p(5600, 0, MEDIUM),
        p(6300, 500, SMALL, 0.5),
        p(7000, -100, SMALL, 0.6),
        p(7700, 300, CHALLENGE),
    ]
    return planets, 0.18


def level_65():
    """Maze corridors — right-angle turns through narrow passages"""
    planets = [
        p(0, 0, BASIC),
        p(0, 700, SMALL, 0.6),
        p(700, 700, MEDIUM),
        p(700, 0, SMALL, 0.5),
        p(700, -700, SMALL, 0.6),
        p(1400, -700, MEDIUM),
        p(1400, 0, SMALL, 0.5),
        p(1400, 700, SMALL, 0.6),
        p(2100, 700, MEDIUM),
        p(2100, 0, SMALL, 0.5),
        p(2100, -700, SMALL, 0.6),
        p(2800, -700, CHALLENGE),
    ]
    return planets, 0.20


def level_66():
    """Sawtooth wave — sharp peaks and valleys"""
    planets = [
        p(0, 500, BASIC),
        p(400, 0, SMALL, 0.6),
        p(800, 800, MEDIUM),
        p(1200, 0, SMALL, 0.5),
        p(1600, 900, SMALL, 0.6),
        p(2000, 0, MEDIUM),
        p(2400, 1000, SMALL, 0.5),
        p(2800, 0, SMALL, 0.6),
        p(3200, 1100, MEDIUM),
        p(3600, 0, SMALL, 0.5),
        p(4000, 800, SMALL, 0.6),
        p(4400, 400, CHALLENGE),
    ]
    return planets, 0.19


def level_67():
    """Vortex — tightening spiral with alternating sizes"""
    cx, cy = 2500, 2500
    planets = []
    for i in range(11):
        angle = i * math.pi * 0.55
        r = 2000 - i * 160
        x = cx + int(r * math.cos(angle))
        y = cy + int(r * math.sin(angle))
        if i % 2 == 0:
            planets.append(p(x, y, SMALL, 0.5 + (i % 3) * 0.1))
        else:
            planets.append(p(x, y, MEDIUM))
    planets[0]["ptype"] = BASIC
    planets[0].pop("scale", None)
    planets.append(p(cx, cy, CHALLENGE))
    return planets, 0.18


def level_68():
    """Trident — three prongs with a shared handle"""
    planets = [
        # Handle
        p(0, 1000, BASIC),
        p(600, 1000, SMALL, 0.6),
        p(1200, 1000, MEDIUM),
        # Fork
        p(1800, 400, SMALL, 0.5),
        p(1800, 1000, SMALL, 0.6),
        p(1800, 1600, SMALL, 0.5),
        # Tips
        p(2400, 200, MEDIUM),
        p(2400, 1000, SMALL, 0.5),
        p(2400, 1800, MEDIUM),
        # Converge to finish
        p(3000, 600, SMALL, 0.6),
        p(3000, 1400, SMALL, 0.6),
        p(3500, 1000, CHALLENGE),
    ]
    return planets, 0.20


def level_69():
    """Pendulum — swinging arcs getting wider"""
    planets = [
        p(1000, 0, BASIC),
        p(600, 400, SMALL, 0.6),
        p(1400, 400, MEDIUM),
        p(400, 900, SMALL, 0.5),
        p(1600, 900, SMALL, 0.6),
        p(200, 1400, MEDIUM),
        p(1800, 1400, SMALL, 0.5),
        p(0, 1900, SMALL, 0.6),
        p(2000, 1900, MEDIUM),
        p(-200, 2400, SMALL, 0.5),
        p(2200, 2400, SMALL, 0.6),
        p(1000, 2800, CHALLENGE),
    ]
    return planets, 0.19


def level_70():
    """Gauntlet run — long straight with obstacles above and below"""
    planets = [
        p(0, 0, BASIC),
        p(600, -400, SMALL, 0.5),
        p(600, 400, SMALL, 0.6),
        p(1200, 0, MEDIUM),
        p(1800, -500, SMALL, 0.5),
        p(1800, 500, SMALL, 0.5),
        p(2400, 0, SMALL, 0.6),
        p(3000, -400, SMALL, 0.5),
        p(3000, 400, MEDIUM),
        p(3600, 0, SMALL, 0.5),
        p(4200, -300, SMALL, 0.6),
        p(4800, 0, CHALLENGE),
    ]
    return planets, 0.18


# ──────────────────────────────────────────────────────────
# GODLIKE TIER (71-80): 12-13 planets, zoom 0.16-0.20
# ──────────────────────────────────────────────────────────

def level_71():
    """Web — interconnected web-like structure"""
    cx, cy = 3000, 3000
    planets = []
    # Inner ring
    for i in range(4):
        angle = i * math.pi / 2 + math.pi / 4
        x = cx + int(600 * math.cos(angle))
        y = cy + int(600 * math.sin(angle))
        planets.append(p(x, y, SMALL, 0.5))
    # Outer ring
    for i in range(8):
        angle = i * math.pi / 4
        x = cx + int(1500 * math.cos(angle))
        y = cy + int(1500 * math.sin(angle))
        types = [BASIC, SMALL, MEDIUM, SMALL, SMALL, MEDIUM, SMALL, SMALL]
        scales = [None, 0.5, None, 0.5, 0.6, None, 0.5, 0.6]
        planets.append(p(x, y, types[i], scales[i]))
    planets.append(p(cx + 2200, cy, CHALLENGE))
    return planets, 0.17


def level_72():
    """Maze — right-angle maze with dead-end distractors"""
    planets = [
        p(0, 0, BASIC),
        p(0, 700, SMALL, 0.5),
        p(700, 700, SMALL, 0.6),
        p(700, 0, MEDIUM),
        p(1400, 0, SMALL, 0.5),
        p(1400, 700, SMALL, 0.5),
        p(1400, 1400, MEDIUM),
        p(700, 1400, SMALL, 0.6),
        p(0, 1400, SMALL, 0.5),
        p(0, 2100, MEDIUM),
        p(700, 2100, SMALL, 0.5),
        p(1400, 2100, SMALL, 0.6),
        p(2100, 2100, CHALLENGE),
    ]
    return planets, 0.19


def level_73():
    """Constellation Orion — planets placed in Orion belt + shoulders pattern"""
    planets = [
        p(1000, 0, BASIC),           # left shoulder
        p(3000, 0, MEDIUM),           # right shoulder
        # Belt
        p(1500, 1000, SMALL, 0.5),
        p(2000, 1100, SMALL, 0.5),
        p(2500, 1000, SMALL, 0.6),
        # Sword
        p(2000, 1600, SMALL, 0.5),
        p(2000, 2100, MEDIUM),
        # Legs
        p(800, 2500, SMALL, 0.6),
        p(3200, 2500, SMALL, 0.5),
        # Feet
        p(500, 3200, MEDIUM),
        p(3500, 3200, SMALL, 0.5),
        p(2000, 3500, SMALL, 0.6),
        p(2000, 4000, CHALLENGE),
    ]
    return planets, 0.17


def level_74():
    """Fractal tree — branching tree structure"""
    planets = [
        # Trunk
        p(1500, 3000, BASIC),
        p(1500, 2400, SMALL, 0.6),
        p(1500, 1800, MEDIUM),
        # First branch
        p(900, 1300, SMALL, 0.5),
        p(2100, 1300, SMALL, 0.5),
        # Second branch
        p(500, 800, SMALL, 0.5),
        p(1300, 800, MEDIUM),
        p(1700, 800, SMALL, 0.6),
        p(2500, 800, SMALL, 0.5),
        # Leaves
        p(300, 300, SMALL, 0.5),
        p(800, 200, SMALL, 0.5),
        p(2200, 300, SMALL, 0.5),
        p(2700, 200, CHALLENGE),
    ]
    return planets, 0.18


def level_75():
    """Zigzag ascent — extreme vertical zigzag"""
    planets = []
    for i in range(12):
        x = 0 if i % 2 == 0 else 900
        y = 3600 - i * 350
        if i == 0:
            planets.append(p(x, y, BASIC))
        elif i % 3 == 0:
            planets.append(p(x, y, MEDIUM))
        else:
            planets.append(p(x, y, SMALL, 0.5))
    planets.append(p(450, -700, CHALLENGE))
    return planets, 0.16


def level_76():
    """Hexagonal grid — honeycomb pattern"""
    planets = []
    hex_positions = [
        (0, 0), (400, 230), (400, -230),
        (800, 0), (800, 460), (800, -460),
        (1200, 230), (1200, -230),
        (1600, 0), (1600, 460), (1600, -460),
        (2000, 230), (2000, -230),
    ]
    types_list = [BASIC, SMALL, MEDIUM, SMALL, SMALL, SMALL, MEDIUM, SMALL, SMALL, SMALL, MEDIUM, SMALL, SMALL]
    scales_list = [None, 0.5, None, 0.5, 0.5, 0.6, None, 0.5, 0.5, 0.6, None, 0.5, 0.5]
    for i, (hx, hy) in enumerate(hex_positions):
        planets.append(p(hx, hy, types_list[i], scales_list[i]))
    # Replace last with challenge
    planets[-1]["ptype"] = CHALLENGE
    return planets, 0.20


def level_77():
    """Double loop — two circles connected, figure 8 style"""
    cx1, cy = 1200, 1500
    cx2 = 3200
    planets = []
    # Loop 1
    for i in range(6):
        angle = i * math.pi / 3
        x = cx1 + int(800 * math.cos(angle))
        y = cy + int(800 * math.sin(angle))
        types = [BASIC, SMALL, MEDIUM, SMALL, SMALL, MEDIUM]
        scales = [None, 0.5, None, 0.5, 0.6, None]
        planets.append(p(x, y, types[i], scales[i]))
    # Loop 2
    for i in range(6):
        angle = i * math.pi / 3 + math.pi / 6
        x = cx2 + int(800 * math.cos(angle))
        y = cy + int(800 * math.sin(angle))
        types = [SMALL, MEDIUM, SMALL, SMALL, MEDIUM, SMALL]
        scales = [0.5, None, 0.6, 0.5, None, 0.5]
        planets.append(p(x, y, types[i], scales[i]))
    planets.append(p(cx2 + 1200, cy, CHALLENGE))
    return planets, 0.16


def level_78():
    """Dagger — long narrow blade with a crossguard"""
    planets = [
        # Pommel
        p(0, 1000, BASIC),
        p(400, 1000, SMALL, 0.5),
        # Grip
        p(800, 1000, MEDIUM),
        p(1200, 1000, SMALL, 0.5),
        # Crossguard
        p(1600, 500, SMALL, 0.6),
        p(1600, 1000, MEDIUM),
        p(1600, 1500, SMALL, 0.6),
        # Blade
        p(2100, 1000, SMALL, 0.5),
        p(2600, 1000, SMALL, 0.5),
        p(3100, 1000, MEDIUM),
        p(3600, 1000, SMALL, 0.5),
        p(4100, 1000, SMALL, 0.5),
        p(4600, 1000, CHALLENGE),
    ]
    return planets, 0.17


def level_79():
    """Broken bridge — gaps in a path that require precision arcing"""
    planets = [
        p(0, 0, BASIC),
        p(500, 0, SMALL, 0.5),
        # gap
        p(1300, 200, SMALL, 0.5),
        p(1800, 0, MEDIUM),
        # gap
        p(2800, 300, SMALL, 0.5),
        p(3300, 0, SMALL, 0.5),
        # gap
        p(4300, 200, MEDIUM),
        p(4800, 0, SMALL, 0.5),
        # gap
        p(5800, 300, SMALL, 0.5),
        p(6300, 0, SMALL, 0.5),
        p(6800, 200, MEDIUM),
        p(7300, 0, SMALL, 0.5),
        p(7800, 100, CHALLENGE),
    ]
    return planets, 0.16


def level_80():
    """Labyrinth — complex interconnected paths"""
    planets = [
        p(0, 0, BASIC),
        p(500, 500, SMALL, 0.5),
        p(1000, 0, MEDIUM),
        p(1000, 1000, SMALL, 0.5),
        p(500, 1500, SMALL, 0.5),
        p(0, 1000, MEDIUM),
        p(-500, 1500, SMALL, 0.5),
        p(-500, 2200, MEDIUM),
        p(0, 2700, SMALL, 0.5),
        p(500, 2200, SMALL, 0.5),
        p(1000, 2700, MEDIUM),
        p(1500, 2200, SMALL, 0.5),
        p(2000, 2700, CHALLENGE),
    ]
    return planets, 0.17


# ──────────────────────────────────────────────────────────
# ULTIMATE TIER (81-90): 13-14 planets, zoom 0.14-0.18
# ──────────────────────────────────────────────────────────

def level_81():
    """Grand spiral — massive outward spiral"""
    planets = []
    cx, cy = 3000, 3000
    for i in range(13):
        angle = i * math.pi * 0.48
        r = 300 + i * 250
        x = cx + int(r * math.cos(angle))
        y = cy + int(r * math.sin(angle))
        if i == 0:
            planets.append(p(x, y, BASIC))
        elif i % 3 == 0:
            planets.append(p(x, y, MEDIUM))
        else:
            planets.append(p(x, y, SMALL, 0.4 + (i % 3) * 0.1))
    planets.append(p(cx + 3500, cy - 1000, CHALLENGE))
    return planets, 0.15


def level_82():
    """Labyrinth chambers — multiple rooms connected by narrow passages"""
    planets = [
        # Room 1
        p(0, 0, BASIC),
        p(500, -400, SMALL, 0.5),
        p(500, 400, SMALL, 0.5),
        # Passage
        p(1200, 0, SMALL, 0.4),
        # Room 2
        p(1900, -300, MEDIUM),
        p(1900, 300, SMALL, 0.5),
        p(2400, 0, SMALL, 0.5),
        # Passage
        p(3100, 200, SMALL, 0.4),
        # Room 3
        p(3800, -200, SMALL, 0.5),
        p(3800, 400, MEDIUM),
        p(4300, 0, SMALL, 0.5),
        # Passage
        p(5000, -100, SMALL, 0.4),
        # Finish room
        p(5700, 0, SMALL, 0.5),
        p(6200, 0, CHALLENGE),
    ]
    return planets, 0.14


def level_83():
    """Double helix — two intertwined spirals"""
    planets = []
    for i in range(13):
        x = i * 500
        y_off = int(600 * math.sin(i * 0.7))
        # Alternate between strands
        y = y_off if i % 2 == 0 else -y_off
        if i == 0:
            planets.append(p(x, y, BASIC))
        elif i % 4 == 0:
            planets.append(p(x, y, MEDIUM))
        else:
            planets.append(p(x, y, SMALL, 0.4 + (i % 3) * 0.1))
    planets.append(p(6800, 0, CHALLENGE))
    return planets, 0.15


def level_84():
    """Meteor shower — dense chaotic field with a hidden path"""
    planets = [
        p(0, 0, BASIC),
        p(500, -600, SMALL, 0.4),
        p(400, 500, SMALL, 0.5),
        p(1000, -200, MEDIUM),
        p(900, 600, SMALL, 0.4),
        p(1500, 300, SMALL, 0.5),
        p(1400, -500, SMALL, 0.4),
        p(2000, 0, MEDIUM),
        p(1900, 700, SMALL, 0.4),
        p(2500, -400, SMALL, 0.5),
        p(2400, 400, SMALL, 0.4),
        p(3000, -100, MEDIUM),
        p(3000, 600, SMALL, 0.4),
        p(3500, 200, CHALLENGE),
    ]
    return planets, 0.16


def level_85():
    """Crown — royal crown shape with jewel planets"""
    planets = [
        # Base
        p(0, 1500, BASIC),
        p(600, 1500, SMALL, 0.5),
        p(1200, 1500, MEDIUM),
        p(1800, 1500, SMALL, 0.5),
        p(2400, 1500, SMALL, 0.4),
        # Peaks (jewels)
        p(300, 800, SMALL, 0.5),
        p(900, 400, SMALL, 0.4),
        p(1500, 200, MEDIUM),
        p(2100, 400, SMALL, 0.4),
        p(2700, 800, SMALL, 0.5),
        # Top jewels
        p(600, 100, SMALL, 0.4),
        p(1500, -200, SMALL, 0.4),
        p(2400, 100, SMALL, 0.4),
        p(1500, -600, CHALLENGE),
    ]
    return planets, 0.16


def level_86():
    """Caterpillar — undulating body segments"""
    planets = []
    for i in range(13):
        x = i * 450
        y = int(400 * math.sin(i * 0.9))
        if i == 0:
            planets.append(p(x, y, BASIC))
        elif i % 4 == 0:
            planets.append(p(x, y, MEDIUM))
        else:
            planets.append(p(x, y, SMALL, 0.4 + (i % 2) * 0.1))
    planets.append(p(13 * 450, 0, CHALLENGE))
    return planets, 0.14


def level_87():
    """Cascade — waterfall of planets descending in tiers"""
    planets = [
        # Tier 1
        p(0, 0, BASIC),
        p(600, 0, SMALL, 0.5),
        p(1200, 0, SMALL, 0.4),
        # Drop
        p(1000, 700, SMALL, 0.4),
        # Tier 2
        p(600, 1200, MEDIUM),
        p(1200, 1200, SMALL, 0.5),
        p(1800, 1200, SMALL, 0.4),
        # Drop
        p(1600, 1900, SMALL, 0.4),
        # Tier 3
        p(1200, 2400, SMALL, 0.5),
        p(1800, 2400, MEDIUM),
        p(2400, 2400, SMALL, 0.4),
        # Drop
        p(2200, 3100, SMALL, 0.4),
        # Tier 4
        p(1800, 3600, SMALL, 0.5),
        p(2400, 3600, CHALLENGE),
    ]
    return planets, 0.15


def level_88():
    """Gauntlet extreme — long corridor with tight alternating obstacles"""
    planets = []
    for i in range(13):
        x = i * 500
        y = 400 if i % 2 == 0 else -400
        if i == 0:
            planets.append(p(x, y, BASIC))
        elif i % 5 == 0:
            planets.append(p(x, y, MEDIUM))
        else:
            planets.append(p(x, y, SMALL, 0.4))
    planets.append(p(13 * 500 + 200, 0, CHALLENGE))
    return planets, 0.14


def level_89():
    """Nebula rings — three concentric rings, traverse inside-out"""
    cx, cy = 3000, 3000
    planets = []
    # Inner ring (3)
    for i in range(3):
        angle = i * 2 * math.pi / 3
        x = cx + int(400 * math.cos(angle))
        y = cy + int(400 * math.sin(angle))
        planets.append(p(x, y, SMALL if i > 0 else BASIC, 0.4 if i > 0 else None))
    # Middle ring (5)
    for i in range(5):
        angle = i * 2 * math.pi / 5 + 0.3
        x = cx + int(1000 * math.cos(angle))
        y = cy + int(1000 * math.sin(angle))
        types = [SMALL, MEDIUM, SMALL, SMALL, MEDIUM]
        planets.append(p(x, y, types[i], 0.5 if types[i] == SMALL else None))
    # Outer ring (5)
    for i in range(5):
        angle = i * 2 * math.pi / 5
        x = cx + int(1800 * math.cos(angle))
        y = cy + int(1800 * math.sin(angle))
        types = [SMALL, SMALL, MEDIUM, SMALL, SMALL]
        planets.append(p(x, y, types[i], 0.4 if types[i] == SMALL else None))
    planets.append(p(cx + 2500, cy, CHALLENGE))
    return planets, 0.14


def level_90():
    """The Final Gauntlet — ultimate challenge, winding path through everything"""
    planets = [
        p(0, 0, BASIC),
        p(500, -500, SMALL, 0.4),
        p(1000, 200, MEDIUM),
        p(700, 800, SMALL, 0.4),
        p(1500, 600, SMALL, 0.5),
        p(2000, -200, SMALL, 0.4),
        p(2500, 500, MEDIUM),
        p(2200, 1200, SMALL, 0.4),
        p(3000, 1000, SMALL, 0.4),
        p(3500, 200, SMALL, 0.5),
        p(4000, 800, MEDIUM),
        p(3700, 1500, SMALL, 0.4),
        p(4500, 1300, SMALL, 0.4),
        p(5000, 700, CHALLENGE),
    ]
    return planets, 0.14


# ═══════════════════════════════════════════════════════════════════
# REGISTRY: map level number → generator function
# ═══════════════════════════════════════════════════════════════════

LEVEL_GENERATORS = {
    31: level_31, 32: level_32, 33: level_33, 34: level_34, 35: level_35,
    36: level_36, 37: level_37, 38: level_38, 39: level_39, 40: level_40,
    41: level_41, 42: level_42, 43: level_43, 44: level_44, 45: level_45,
    46: level_46, 47: level_47, 48: level_48, 49: level_49, 50: level_50,
    51: level_51, 52: level_52, 53: level_53, 54: level_54, 55: level_55,
    56: level_56, 57: level_57, 58: level_58, 59: level_59, 60: level_60,
    61: level_61, 62: level_62, 63: level_63, 64: level_64, 65: level_65,
    66: level_66, 67: level_67, 68: level_68, 69: level_69, 70: level_70,
    71: level_71, 72: level_72, 73: level_73, 74: level_74, 75: level_75,
    76: level_76, 77: level_77, 78: level_78, 79: level_79, 80: level_80,
    81: level_81, 82: level_82, 83: level_83, 84: level_84, 85: level_85,
    86: level_86, 87: level_87, 88: level_88, 89: level_89, 90: level_90,
}


# ═══════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    generated = 0
    errors = []

    for lvl in range(31, 91):
        gen_fn = LEVEL_GENERATORS.get(lvl)
        if gen_fn is None:
            errors.append(f"Level {lvl}: no generator function!")
            continue

        try:
            planets, zoom = gen_fn()

            # Validation
            if planets[-1]["ptype"] != CHALLENGE:
                errors.append(f"Level {lvl}: last planet is not CHALLENGE (type 3)!")
                continue

            challenge_count = sum(1 for pl in planets if pl["ptype"] == CHALLENGE)
            if challenge_count != 1:
                errors.append(f"Level {lvl}: has {challenge_count} CHALLENGE planets (expected 1)!")
                continue

            scene_str = build_scene(lvl, planets, zoom)
            filepath = os.path.join(OUTPUT_DIR, f"level_{lvl}.tscn")
            with open(filepath, "w", newline="\n") as f:
                f.write(scene_str)

            generated += 1
            print(f"✓ Level {lvl} — {len(planets)} planets, zoom {zoom}")

        except Exception as e:
            errors.append(f"Level {lvl}: {e}")

    print(f"\n{'='*50}")
    print(f"Generated: {generated}/60 level files")
    print(f"Output dir: {OUTPUT_DIR}")

    if errors:
        print(f"\nERRORS ({len(errors)}):")
        for err in errors:
            print(f"  ✗ {err}")
    else:
        print("All levels generated successfully! ✓")


if __name__ == "__main__":
    main()
