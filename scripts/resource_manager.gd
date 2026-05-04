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
	get_scene("res://scenes/level_complete_ui.tscn")
	get_scene("res://scenes/explosion.tscn")
