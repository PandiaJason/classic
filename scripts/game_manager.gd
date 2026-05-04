extends Node

var current_score: int = 0
var has_box: bool = true
var box_health: float = 100.0
var current_level: int = 1
var last_game_over_reason: String = ""

signal health_changed(new_health)

func take_jump_damage() -> void:
	if has_box:
		box_health -= 10.0
		box_health = max(0.0, box_health)
		health_changed.emit(box_health)

func game_over(reason: String) -> void:
	print("!!! GAME OVER TRIGGERED: ", reason, " !!!")
	last_game_over_reason = reason
	var ui_scene = ResourceManager.get_scene("res://scenes/game_over_ui.tscn")
	if ui_scene:
		var ui = ui_scene.instantiate()
		# Add to the root to ensure it stays on top and survives scene changes
		get_tree().root.add_child(ui)

func level_complete() -> void:
	print("LEVEL COMPLETE!")
	var ui_scene = load("res://scenes/level_complete_ui.tscn")
	if ui_scene:
		var ui = ui_scene.instantiate()
		get_tree().current_scene.call_deferred("add_child", ui)

func add_score(points: int) -> void:
	current_score += points
	SaveSystem.global_score += points
	SaveSystem.save_data()

func reset_score() -> void:
	current_score = 0
	has_box = true
	box_health = 100.0
	health_changed.emit(box_health)

func load_next_level() -> void:
	# current_score is kept for the session, but we also saved it globally
	has_box = true
	box_health = 100.0
	current_level += 1
	health_changed.emit(box_health)
	
	if current_level > 30:
		get_tree().change_scene_to_file("res://scenes/level_select.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/level_" + str(current_level) + ".tscn")
