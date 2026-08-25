extends Node

# Achievement Manager — Autoload singleton that tracks, unlocks, and displays achievements
# Persists achievement state through SaveSystem's ConfigFile

signal achievement_unlocked(id: String, data: Dictionary)

# Achievement definitions: id -> {name, desc, icon, reward, target, category}
var _defs: Dictionary = {}
# Unlocked achievements: id -> true
var _unlocked: Dictionary = {}
# Progress counters: stat_name -> int
var _stats: Dictionary = {}
# Toast queue for sequential display
var _toast_queue: Array = []
var _showing_toast: bool = false
var _canvas_layer: CanvasLayer = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 120
	add_child(_canvas_layer)
	_register_achievements()
	_load_data()

# ─── Achievement Definitions ───────────────────────────────────────────

func _register_achievements():
	# Ruby Achievements
	_def("ruby_rookie", "ruby rookie", "collect 100 total rubies", "res://assets/ruby.png", 25, 100, "rubies")
	_def("ruby_hunter", "ruby hunter", "collect 500 total rubies", "res://assets/ruby.png", 50, 500, "rubies")
	_def("ruby_master", "ruby master", "collect 1000 total rubies", "res://assets/ruby.png", 100, 1000, "rubies")
	_def("ruby_king", "ruby king", "collect 5000 total rubies", "res://assets/ruby.png", 250, 5000, "rubies")

	# Survival Achievements
	_def("space_wanderer", "space wanderer", "get lost in space 5 times", "res://assets/game_over_skeleton.png", 30, 5, "survival")
	_def("asteroid_magnet", "asteroid magnet", "get hit by 10 asteroids", "res://assets/asteroid.png", 30, 10, "survival")
	_def("tough_delivery", "tough delivery", "complete a level with under 25% box health", "res://assets/delivery_box.png", 40, 1, "survival")
	_def("perfect_delivery", "perfect delivery", "complete a level with 100% box health", "res://assets/delivery_box.png", 50, 1, "survival")
	_def("iron_frog", "iron frog", "complete 5 levels with 100% box health", "res://assets/delivery_box.png", 100, 5, "survival")

	# Progress Achievements
	_def("first_delivery", "first delivery", "complete your first level", "res://assets/flag.png", 20, 1, "progress")
	_def("rising_star", "rising star", "earn your first 3-star rating", "res://assets/star.png", 30, 1, "progress")
	_def("star_collector", "star collector", "earn 50 total stars", "res://assets/star.png", 50, 50, "progress")
	_def("star_master", "star master", "earn 150 total stars", "res://assets/star.png", 100, 150, "progress")
	_def("completionist", "completionist", "earn all 270 stars", "res://assets/star.png", 500, 270, "progress")
	_def("halfway", "halfway there", "complete level 45", "res://assets/planet_3.png", 50, 45, "progress")
	_def("final_frontier", "final frontier", "complete level 90", "res://assets/planet_5.png", 200, 90, "progress")

	# Skill Achievements
	_def("glide_master", "glide master", "use glide assist 20 times", "res://assets/custom_player.png", 40, 20, "skill")
	_def("speed_demon", "speed demon", "use speed boost 20 times", "res://assets/custom_player.png", 40, 20, "skill")
	_def("first_jump", "first jump", "make your very first jump", "res://assets/custom_player.png", 10, 1, "skill")
	_def("bounce_king", "bounce king", "jump 500 times total", "res://assets/custom_player.png", 100, 500, "skill")

	# Special Achievements
	_def("daily_devotee", "daily devotee", "claim daily reward 7 days in a row", "res://assets/star.png", 100, 7, "special")
	_def("big_spender", "big spender", "spend 500 rubies in the shop", "res://assets/ruby.png", 50, 500, "special")
	_def("level_10", "tier 1 complete", "complete all 10 levels in tier 1", "res://assets/planet_1.png", 40, 10, "special")
	_def("level_30", "tier 3 complete", "complete 30 levels", "res://assets/planet_2.png", 60, 30, "special")
	_def("level_60", "tier 6 complete", "complete 60 levels", "res://assets/planet_4.png", 100, 60, "special")

func _def(id: String, display_name: String, desc: String, icon: String, reward: int, target: int, category: String):
	_defs[id] = {
		"name": display_name,
		"desc": desc,
		"icon": icon,
		"reward": reward,
		"target": target,
		"category": category
	}

# ─── Persistence ───────────────────────────────────────────────────────

func _load_data():
	var config = SaveSystem.config
	for id in _defs:
		_unlocked[id] = config.get_value("Achievements", id, false)
	# Load stat counters
	_stats["total_rubies_collected"] = config.get_value("AchievementStats", "total_rubies_collected", 0)
	_stats["lost_in_space"] = config.get_value("AchievementStats", "lost_in_space", 0)
	_stats["asteroid_hits"] = config.get_value("AchievementStats", "asteroid_hits", 0)
	_stats["perfect_deliveries"] = config.get_value("AchievementStats", "perfect_deliveries", 0)
	_stats["total_jumps"] = config.get_value("AchievementStats", "total_jumps", 0)
	_stats["glide_uses"] = config.get_value("AchievementStats", "glide_uses", 0)
	_stats["speed_uses"] = config.get_value("AchievementStats", "speed_uses", 0)
	_stats["rubies_spent"] = config.get_value("AchievementStats", "rubies_spent", 0)
	_stats["levels_completed"] = config.get_value("AchievementStats", "levels_completed", 0)

func _save_data():
	var config = SaveSystem.config
	for id in _unlocked:
		config.set_value("Achievements", id, _unlocked[id])
	for stat in _stats:
		config.set_value("AchievementStats", stat, _stats[stat])
	SaveSystem.save_data()

# ─── Core API ──────────────────────────────────────────────────────────

func increment_stat(stat_name: String, amount: int = 1) -> void:
	if not _stats.has(stat_name):
		_stats[stat_name] = 0
	_stats[stat_name] += amount

func get_stat(stat_name: String) -> int:
	return _stats.get(stat_name, 0)

func is_unlocked(id: String) -> bool:
	return _unlocked.get(id, false)

func get_unlocked_count() -> int:
	var count = 0
	for id in _unlocked:
		if _unlocked[id]:
			count += 1
	return count

func get_total_count() -> int:
	return _defs.size()

func get_progress(id: String) -> Dictionary:
	# Returns {current, target, percent} for a given achievement
	var def = _defs.get(id, {})
	if def.is_empty():
		return {"current": 0, "target": 1, "percent": 0.0}
	var target = def.target
	var current = 0
	match id:
		"ruby_rookie", "ruby_hunter", "ruby_master", "ruby_king":
			current = get_stat("total_rubies_collected")
		"space_wanderer":
			current = get_stat("lost_in_space")
		"asteroid_magnet":
			current = get_stat("asteroid_hits")
		"tough_delivery":
			current = 1 if is_unlocked(id) else 0
		"perfect_delivery":
			current = 1 if is_unlocked(id) else 0
		"iron_frog":
			current = get_stat("perfect_deliveries")
		"first_delivery":
			current = 1 if is_unlocked(id) else 0
		"rising_star":
			current = 1 if is_unlocked(id) else 0
		"star_collector", "star_master", "completionist":
			current = SaveSystem.get_total_stars()
		"halfway", "final_frontier":
			current = SaveSystem.unlocked_levels - 1
		"glide_master":
			current = get_stat("glide_uses")
		"speed_demon":
			current = get_stat("speed_uses")
		"first_jump":
			current = mini(get_stat("total_jumps"), 1)
		"bounce_king":
			current = get_stat("total_jumps")
		"daily_devotee":
			current = SaveSystem.streak_count
		"big_spender":
			current = get_stat("rubies_spent")
		"level_10", "level_30", "level_60":
			current = get_stat("levels_completed")
	current = mini(current, target)
	return {"current": current, "target": target, "percent": float(current) / float(target) * 100.0}

func try_unlock(id: String) -> bool:
	if is_unlocked(id):
		return false
	if not _defs.has(id):
		return false
	var progress = get_progress(id)
	if progress.current >= progress.target:
		_unlocked[id] = true
		var def = _defs[id]
		# Grant ruby reward
		SaveSystem.global_rubies += def.reward
		_save_data()
		# Queue toast notification
		_queue_toast(id, def)
		achievement_unlocked.emit(id, def)
		return true
	return false

# ─── Event Hooks (called from game scripts) ────────────────────────────

func on_ruby_collected(amount: int) -> void:
	increment_stat("total_rubies_collected", amount)
	try_unlock("ruby_rookie")
	try_unlock("ruby_hunter")
	try_unlock("ruby_master")
	try_unlock("ruby_king")

func on_jump() -> void:
	increment_stat("total_jumps")
	try_unlock("first_jump")
	try_unlock("bounce_king")

func on_lost_in_space() -> void:
	increment_stat("lost_in_space")
	try_unlock("space_wanderer")

func on_asteroid_hit() -> void:
	increment_stat("asteroid_hits")
	try_unlock("asteroid_magnet")

func on_level_complete(level: int, stars: int, health: float) -> void:
	increment_stat("levels_completed")
	try_unlock("first_delivery")
	
	if stars == 3:
		try_unlock("rising_star")
	
	if health >= 100.0:
		increment_stat("perfect_deliveries")
		try_unlock("perfect_delivery")
		try_unlock("iron_frog")
	
	if health < 25.0 and health > 0.0:
		try_unlock("tough_delivery")
	
	# Progress milestones
	try_unlock("star_collector")
	try_unlock("star_master")
	try_unlock("completionist")
	
	if level >= 45:
		try_unlock("halfway")
	if level >= 90:
		try_unlock("final_frontier")
	
	# Tier milestones
	var completed = get_stat("levels_completed")
	if completed >= 10:
		try_unlock("level_10")
	if completed >= 30:
		try_unlock("level_30")
	if completed >= 60:
		try_unlock("level_60")
	
	_save_data()

func on_glide_used() -> void:
	increment_stat("glide_uses")
	try_unlock("glide_master")

func on_speed_used() -> void:
	increment_stat("speed_uses")
	try_unlock("speed_demon")

func on_rubies_spent(amount: int) -> void:
	increment_stat("rubies_spent", amount)
	try_unlock("big_spender")

func on_daily_streak(streak: int) -> void:
	if streak >= 7 or streak == 0:  # streak resets to 0 after day 7 claim
		try_unlock("daily_devotee")

# ─── Toast Notification ────────────────────────────────────────────────

func _queue_toast(id: String, def: Dictionary) -> void:
	_toast_queue.append({"id": id, "def": def})
	if not _showing_toast:
		_show_next_toast()

func _show_next_toast() -> void:
	if _toast_queue.is_empty():
		_showing_toast = false
		return
	_showing_toast = true
	var item = _toast_queue.pop_front()
	var def = item.def
	
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.05, 0.2, 0.92)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_right = 20
	style.corner_radius_bottom_left = 20
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(1.0, 0.85, 0.2, 1.0)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.shadow_color = Color(1.0, 0.85, 0.0, 0.3)
	style.shadow_size = 15
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Achievement texture icon
	var icon_rect = TextureRect.new()
	icon_rect.texture = load(def.icon)
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(54, 54)
	hbox.add_child(icon_rect)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	
	var title_lbl = Label.new()
	title_lbl.text = "achievement unlocked!"
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	if ResourceLoader.exists("res://assets/game_font.ttf"):
		title_lbl.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	vbox.add_child(title_lbl)
	
	var name_lbl = Label.new()
	name_lbl.text = def.name
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	if ResourceLoader.exists("res://assets/game_font.ttf"):
		name_lbl.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	vbox.add_child(name_lbl)
	
	var reward_lbl = Label.new()
	reward_lbl.text = "+" + str(def.reward) + " rubies"
	reward_lbl.add_theme_font_size_override("font_size", 18)
	reward_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	if ResourceLoader.exists("res://assets/game_font.ttf"):
		reward_lbl.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	vbox.add_child(reward_lbl)
	
	hbox.add_child(vbox)
	panel.add_child(hbox)
	
	# Position at top center
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_left", 200)
	margin.add_theme_constant_override("margin_right", 200)
	margin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	center.add_theme_constant_override("margin_top", 20)
	center.add_child(panel)
	
	_canvas_layer.add_child(center)
	
	# Animate: slide down + fade in, hold, then fade out
	panel.modulate.a = 0.0
	panel.position.y = -60
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "modulate:a", 1.0, 0.4)
	tween.parallel().tween_property(panel, "position:y", 0, 0.4)
	tween.tween_interval(2.5)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		center.queue_free()
		_show_next_toast()
	)

# ─── Achievements Screen Data ──────────────────────────────────────────

func get_all_achievements() -> Array:
	# Returns array of {id, name, desc, icon, reward, target, category, unlocked, progress}
	var result = []
	var cat_weights = {"progress": 1, "rubies": 2, "survival": 3, "skill": 4, "special": 5}
	for id in _defs:
		var entry = _defs[id].duplicate()
		entry["id"] = id
		entry["unlocked"] = is_unlocked(id)
		entry["progress"] = get_progress(id)
		# Assign numerical sort rank for QiSort (unlocked status + category weight)
		entry["sort_rank"] = (100 if entry["unlocked"] else 0) + cat_weights.get(entry["category"], 9)
		result.append(entry)
		
	# Use QiSort high-throughput key sorter
	return QiSort.sort_objects_by_key(result, "sort_rank", true)

func write_to_config(config: ConfigFile) -> void:
	for id in _unlocked:
		config.set_value("Achievements", id, _unlocked[id])
	for stat in _stats:
		config.set_value("AchievementStats", stat, _stats[stat])
