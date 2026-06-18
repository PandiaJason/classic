extends Node

var current_score: int = 0
var has_box: bool = true
var box_health: float = 100.0
var current_level: int = 1
var is_gameplay_started: bool = false

signal health_changed(new_health)

func take_jump_damage() -> void:
	if has_box:
		box_health -= 3.0
		box_health = max(0.0, box_health)
		health_changed.emit(box_health)

func repair_box(amount: float) -> void:
	if has_box:
		box_health = min(100.0, box_health + amount)
		health_changed.emit(box_health)

func take_damage(amount: float, reason: String) -> void:
	if has_box:
		box_health -= amount
		box_health = max(0.0, box_health)
		health_changed.emit(box_health)
		if box_health <= 0.0:
			game_over(reason)

func game_over(reason: String) -> void:
	await get_tree().process_frame

	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		player.is_game_over = true
		player.hide()

	var ui_scene = ResourceManager.get_scene("res://scenes/game_over_ui.tscn")
	if ui_scene:
		var ui = ui_scene.instantiate()
		ui.game_over_reason = reason
		get_tree().root.add_child(ui)

func level_complete() -> void:
	await get_tree().process_frame
	var ui_scene = ResourceManager.get_scene("res://scenes/level_complete_ui.tscn")
	if ui_scene:
		var ui = ui_scene.instantiate()
		get_tree().root.add_child(ui)

var level_rubies: int = 0
var level_score_earned: int = 0

func add_score(points: int) -> void:
	current_score += points
	level_score_earned += points
	if points == 10:
		level_rubies += 1
	SaveSystem.global_score += points
	SaveSystem.save_data()

func reset_score() -> void:
	current_score = 0
	level_rubies = 0
	level_score_earned = 0
	has_box = true
	box_health = 100.0
	is_gameplay_started = false
	health_changed.emit(box_health)

func load_next_level() -> void:
	# current_score is kept for the session, but we also saved it globally
	level_rubies = 0
	level_score_earned = 0
	has_box = true
	box_health = 100.0
	current_level += 1
	is_gameplay_started = false
	health_changed.emit(box_health)
	
	if current_level > 90:
		SceneTransition.transition_to("res://scenes/level_select.tscn")
	else:
		SceneTransition.transition_to("res://scenes/level_" + str(current_level) + ".tscn")
