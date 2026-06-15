extends StaticBody2D

enum PlanetType { BASIC, MEDIUM, SMALL, CHALLENGE }

@export var type: PlanetType = PlanetType.BASIC
@export var custom_gravity: float = -1.0 # If -1, use default for type

@onready var sprite = $Visuals/Sprite2D
@onready var gravity_area = $GravityArea
@onready var collision_shape = $CollisionShape2D
@onready var gravity_shape = $GravityArea/CollisionShape2D

var planet_speed: float = 250.0
var planet_jump_force: float = -500.0

func _ready():
	setup_planet()

func setup_planet():
	var region = Rect2()
	var size_scale = 1.0
	var grav = 980.0
	var tex_path = "res://assets/planet_1.png"
	
	var mod_color = Color(1, 1, 1, 1)
	match type:
		PlanetType.BASIC:
			size_scale = 1.5
			grav = 1500.0
			planet_speed = 350.0
			planet_jump_force = -700.0
			tex_path = "res://assets/planet_1.png"
		PlanetType.MEDIUM:
			size_scale = 1.2
			grav = 980.0
			planet_speed = 280.0
			planet_jump_force = -550.0
			tex_path = "res://assets/planet_2.png"
		PlanetType.SMALL:
			size_scale = 0.9
			grav = 700.0
			planet_speed = 220.0
			planet_jump_force = -450.0
			tex_path = "res://assets/planet_3.png"
		PlanetType.CHALLENGE:
			size_scale = 0.7
			grav = 400.0
			planet_speed = 150.0
			planet_jump_force = -350.0
			tex_path = "res://assets/planet_4.png"
			
	# Dynamically calculate the required gravity radius.
	# We want the player to be able to ESCAPE the gravity field if they jump,
	# so we make the gravity bubble slightly smaller than their max jump height!
	var surface_radius = 100.0 * size_scale
	var max_jump_height = 0.5 * grav * pow(abs(planet_jump_force) / grav, 2.0)
	var required_world_radius = surface_radius + (max_jump_height * 0.85) # 85% of jump height
	var grav_radius = required_world_radius / size_scale
			
	if has_node("Visuals/Sprite2D"):
		var tex = ResourceManager.get_texture(tex_path)
		if tex:
			var sprite_node = $Visuals/Sprite2D
			sprite_node.texture = tex
			sprite_node.modulate = mod_color
			var tex_size = tex.get_size()
			if tex_size.x > 0 and tex_size.y > 0:
				sprite_node.scale = Vector2(200.0 / tex_size.x, 200.0 / tex_size.y)
				
	# Add the flag to the finish planet
	if type == PlanetType.CHALLENGE:
		var flag_tex = ResourceManager.get_texture("res://assets/flag.png")
		if flag_tex:
			var flag_sprite = Sprite2D.new()
			flag_sprite.texture = flag_tex
			# Anchor the flag at its bottom so it sits on the surface
			flag_sprite.offset = Vector2(0, -flag_tex.get_size().y / 2.0)
			# Position it on the surface of the planet (radius = 100)
			flag_sprite.position = Vector2(0, -85.0)
			flag_sprite.scale = Vector2(0.12, 0.12)
			if has_node("Visuals"):
				$Visuals.add_child(flag_sprite)
			
	scale = Vector2(size_scale, size_scale)
	
	if custom_gravity > 0:
		grav = custom_gravity
		
	gravity_area.gravity = grav
	# Adjust gravity radius physically and mathematically
	if gravity_shape.shape is CircleShape2D:
		gravity_shape.shape = gravity_shape.shape.duplicate()
		gravity_shape.shape.radius = grav_radius
		
	# Create high-quality glossy bubble using shader
	var bubble = ColorRect.new()
	bubble.name = "GlossyBubble"
	var diameter = grav_radius * 2.0
	bubble.size = Vector2(diameter, diameter)
	bubble.position = Vector2(-grav_radius, -grav_radius)
	
	var mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/bubble.gdshader")
	
	# Tier-specific gravity bubble colors
	var bubble_color = Color(0.2, 0.6, 1.0, 0.05)
	var rim_color = Color(0.8, 0.95, 1.0)
	var lvl = GameManager.current_level
	if lvl >= 81:
		bubble_color = Color(0.8, 0.2, 0.6, 0.05)
		rim_color = Color(1.0, 0.7, 0.9)
	elif lvl >= 71:
		bubble_color = Color(0.1, 0.7, 0.8, 0.05)
		rim_color = Color(0.6, 0.95, 1.0)
	elif lvl >= 61:
		bubble_color = Color(0.9, 0.5, 0.1, 0.05)
		rim_color = Color(1.0, 0.8, 0.5)
	elif lvl >= 51:
		bubble_color = Color(0.2, 0.8, 0.3, 0.05)
		rim_color = Color(0.7, 1.0, 0.8)
	elif lvl >= 41:
		bubble_color = Color(0.6, 0.2, 0.9, 0.05)
		rim_color = Color(0.9, 0.7, 1.0)
	elif lvl >= 31:
		bubble_color = Color(0.1, 0.7, 0.6, 0.05)
		rim_color = Color(0.6, 1.0, 0.9)
		
	mat.set_shader_parameter("bubble_color", bubble_color)
	mat.set_shader_parameter("rim_color", rim_color)
	bubble.material = mat
	
	# Ensure the bubble is behind the planet sprite but visible
	add_child(bubble)
	move_child(bubble, 0)

	# Spawn Rubies (Deterministic based on planet position)
	if type != PlanetType.CHALLENGE:
		var rng = RandomNumberGenerator.new()
		# Use global_position to generate a unique but consistent seed for this specific planet
		rng.seed = int(global_position.x * 1000 + global_position.y)
		
		if rng.randf() < 0.4:
			var ruby_scene = ResourceManager.get_scene("res://scenes/ruby.tscn")
			if ruby_scene:
				var num_rubies = rng.randi_range(1, 3)
				for i in range(num_rubies):
					var ruby = ruby_scene.instantiate()
					var angle = rng.randf() * PI * 2
					# surface_radius is already scaled, so we just add a small fixed amount
					var world_dist = surface_radius + rng.randf_range(30.0, 60.0)
					ruby.global_position = global_position + Vector2(cos(angle), sin(angle)) * world_dist
					call_deferred("add_sibling", ruby)
