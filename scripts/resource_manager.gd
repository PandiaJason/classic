extends Node

# Cache for frequently used resources to optimize memory and performance
var textures = {}
var scenes = {}

func get_texture(path: String) -> Texture2D:
	if not textures.has(path):
		if ResourceLoader.exists(path):
			textures[path] = load(path)
		else:
			push_warning("ResourceManager: texture not found: " + path)
			return null
	return textures[path]

func get_scene(path: String) -> PackedScene:
	if not scenes.has(path):
		if ResourceLoader.exists(path):
			scenes[path] = load(path)
		else:
			push_warning("ResourceManager: scene not found: " + path)
			return null
	return scenes[path]

func pre_cache():
	# Pre-load essential assets at game start to avoid frame drops
	get_texture("res://assets/planet_1.png")
	get_texture("res://assets/planet_2.png")
	get_texture("res://assets/planet_3.png")
	get_texture("res://assets/planet_4.png")
	get_texture("res://assets/ruby.png")
	get_texture("res://assets/delivery_box.png")
	get_texture("res://assets/flag.png")
	get_scene("res://scenes/ruby.tscn")
	get_scene("res://scenes/game_over_ui.tscn")
	get_scene("res://scenes/explosion.tscn")

var _light_texture: Texture2D = null

func get_light_texture() -> Texture2D:
	if _light_texture == null:
		var size = 128
		var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
		var center = size / 2.0
		for y in range(size):
			for x in range(size):
				var dist = Vector2(x - center, y - center).length()
				var pct = clamp(1.0 - (dist / center), 0.0, 1.0)
				var alpha = pct * pct
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
		_light_texture = ImageTexture.create_from_image(img)
	return _light_texture
