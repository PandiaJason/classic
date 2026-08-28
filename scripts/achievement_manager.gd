extends Node

# Achievement Manager — Autoload singleton that tracks, unlocks, and displays 75 achievements
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

# ─── 75 Achievement Definitions ──────────────────────────────────────────

func _register_achievements():
	# =========================================================================
	# CATEGORY 1: ENDLESS MODE (15 Achievements)
	# =========================================================================
	_def("endless_100m", "space rookie", "reach 100m in endless mode", "res://assets/custom_player.png", 20, 100, "endless")
	_def("endless_250m", "scooter scout", "reach 250m in endless mode", "res://assets/custom_player.png", 25, 250, "endless")
	_def("endless_500m", "500m milestone", "reach 500m in endless mode", "res://assets/planet_1.png", 35, 500, "endless")
	_def("endless_750m", "orbit strider", "reach 750m in endless mode", "res://assets/planet_1.png", 45, 750, "endless")
	_def("endless_1000m", "1k runner", "reach 1,000m in endless mode", "res://assets/planet_2.png", 60, 1000, "endless")
	_def("endless_1500m", "orbit hopper", "reach 1,500m in endless mode", "res://assets/planet_2.png", 80, 1500, "endless")
	_def("endless_2000m", "2k champion", "reach 2,000m in endless mode", "res://assets/planet_3.png", 100, 2000, "endless")
	_def("endless_2500m", "deep drift", "reach 2,500m in endless mode", "res://assets/planet_3.png", 120, 2500, "endless")
	_def("endless_3000m", "3k marathon", "reach 3,000m in endless mode", "res://assets/planet_4.png", 150, 3000, "endless")
	_def("endless_4000m", "stellar cruiser", "reach 4,000m in endless mode", "res://assets/planet_4.png", 200, 4000, "endless")
	_def("endless_5000m", "5k legend", "reach 5,000m in endless mode", "res://assets/planet_5.png", 250, 5000, "endless")
	_def("endless_7500m", "cosmic voyager", "reach 7,500m in endless mode", "res://assets/planet_5.png", 350, 7500, "endless")
	_def("endless_10000m", "10k space god", "reach 10,000m in endless mode", "res://assets/star.png", 500, 10000, "endless")
	_def("endless_rubies_100", "endless miner", "collect 100 rubies in endless mode", "res://assets/ruby.png", 50, 100, "endless")
	_def("endless_rubies_500", "endless tycoon", "collect 500 rubies in endless mode", "res://assets/ruby.png", 150, 500, "endless")

	# =========================================================================
	# CATEGORY 2: CAMPAIGN PROGRESSION (15 Achievements)
	# =========================================================================
	_def("first_delivery", "first delivery", "complete your first level", "res://assets/flag.png", 20, 1, "campaign")
	_def("tier_1_complete", "tier 1 pioneer", "complete all 10 levels in tier 1", "res://assets/planet_1.png", 40, 10, "campaign")
	_def("tier_2_complete", "tier 2 explorer", "complete 20 levels", "res://assets/planet_2.png", 50, 20, "campaign")
	_def("tier_3_complete", "tier 3 voyager", "complete 30 levels", "res://assets/planet_2.png", 60, 30, "campaign")
	_def("tier_4_complete", "tier 4 pathfinder", "complete 40 levels", "res://assets/planet_3.png", 70, 40, "campaign")
	_def("halfway", "halfway hero", "complete 45 levels", "res://assets/planet_3.png", 80, 45, "campaign")
	_def("tier_5_complete", "tier 5 navigator", "complete 50 levels", "res://assets/planet_4.png", 90, 50, "campaign")
	_def("tier_6_complete", "tier 6 captain", "complete 60 levels", "res://assets/planet_4.png", 100, 60, "campaign")
	_def("tier_7_complete", "tier 7 astronaut", "complete 70 levels", "res://assets/planet_5.png", 120, 70, "campaign")
	_def("tier_8_complete", "tier 8 cosmologist", "complete 80 levels", "res://assets/planet_5.png", 150, 80, "campaign")
	_def("final_frontier", "final frontier", "complete all 90 campaign levels", "res://assets/planet_5.png", 300, 90, "campaign")
	_def("speedy_courier", "speedy courier", "complete 10 levels in under 30s each", "res://assets/custom_player.png", 50, 10, "campaign")
	_def("stellar_veteran", "stellar veteran", "complete 50 total level deliveries", "res://assets/delivery_box.png", 75, 50, "campaign")
	_def("master_courier", "master courier", "complete 75 total level deliveries", "res://assets/delivery_box.png", 125, 75, "campaign")
	_def("grand_deliverer", "grand deliverer", "complete 100 total level deliveries", "res://assets/delivery_box.png", 200, 100, "campaign")

	# =========================================================================
	# CATEGORY 3: STARS & MASTERY (12 Achievements)
	# =========================================================================
	_def("rising_star", "rising star", "earn your first 3-star rating", "res://assets/star.png", 25, 1, "stars")
	_def("star_10", "star novice", "earn 10 total stars", "res://assets/star.png", 30, 10, "stars")
	_def("star_25", "star apprentice", "earn 25 total stars", "res://assets/star.png", 40, 25, "stars")
	_def("star_50", "star collector", "earn 50 total stars", "res://assets/star.png", 60, 50, "stars")
	_def("star_75", "star enthusiast", "earn 75 total stars", "res://assets/star.png", 80, 75, "stars")
	_def("star_100", "centurion of stars", "earn 100 total stars", "res://assets/star.png", 100, 100, "stars")
	_def("star_150", "star master", "earn 150 total stars", "res://assets/star.png", 150, 150, "stars")
	_def("star_200", "constellation master", "earn 200 total stars", "res://assets/star.png", 200, 200, "stars")
	_def("star_250", "galaxy of stars", "earn 250 total stars", "res://assets/star.png", 300, 250, "stars")
	_def("completionist", "completionist", "earn all 270 stars", "res://assets/star.png", 500, 270, "stars")
	_def("perfect_streak_3", "triple perfection", "earn 3 stars on 3 consecutive levels", "res://assets/star.png", 50, 3, "stars")
	_def("perfect_streak_5", "flawless five", "earn 3 stars on 5 consecutive levels", "res://assets/star.png", 100, 5, "stars")

	# =========================================================================
	# CATEGORY 4: RUBIES & ECONOMY (10 Achievements)
	# =========================================================================
	_def("ruby_rookie", "ruby rookie", "collect 100 total rubies", "res://assets/ruby.png", 25, 100, "rubies")
	_def("ruby_seeker", "ruby seeker", "collect 250 total rubies", "res://assets/ruby.png", 35, 250, "rubies")
	_def("ruby_hunter", "ruby hunter", "collect 500 total rubies", "res://assets/ruby.png", 50, 500, "rubies")
	_def("ruby_collector", "ruby collector", "collect 750 total rubies", "res://assets/ruby.png", 75, 750, "rubies")
	_def("ruby_master", "ruby master", "collect 1,000 total rubies", "res://assets/ruby.png", 100, 1000, "rubies")
	_def("ruby_baron", "ruby baron", "collect 2,500 total rubies", "res://assets/ruby.png", 150, 2500, "rubies")
	_def("ruby_king", "ruby king", "collect 5,000 total rubies", "res://assets/ruby.png", 250, 5000, "rubies")
	_def("ruby_emperor", "ruby emperor", "collect 10,000 total rubies", "res://assets/ruby.png", 500, 10000, "rubies")
	_def("smart_shopper", "smart shopper", "spend 100 rubies in the shop", "res://assets/ruby.png", 30, 100, "rubies")
	_def("big_spender", "big spender", "spend 500 rubies in the shop", "res://assets/ruby.png", 75, 500, "rubies")

	# =========================================================================
	# CATEGORY 5: SKILLS & PILOTING (12 Achievements)
	# =========================================================================
	_def("first_jump", "first jump", "make your very first jump", "res://assets/custom_player.png", 10, 1, "skills")
	_def("jump_cadet", "jump cadet", "jump 50 times total", "res://assets/custom_player.png", 25, 50, "skills")
	_def("jump_pro", "jump pro", "jump 150 times total", "res://assets/custom_player.png", 50, 150, "skills")
	_def("bounce_king", "bounce king", "jump 500 times total", "res://assets/custom_player.png", 100, 500, "skills")
	_def("jump_legend", "jump legend", "jump 1,000 times total", "res://assets/custom_player.png", 200, 1000, "skills")
	_def("glide_rookie", "glide rookie", "use glide assist 5 times", "res://assets/custom_player.png", 25, 5, "skills")
	_def("glide_master", "glide master", "use glide assist 20 times", "res://assets/custom_player.png", 50, 20, "skills")
	_def("glide_expert", "glide expert", "use glide assist 50 times", "res://assets/custom_player.png", 100, 50, "skills")
	_def("speed_starter", "speed starter", "use speed boost 5 times", "res://assets/custom_player.png", 25, 5, "skills")
	_def("speed_demon", "speed demon", "use speed boost 20 times", "res://assets/custom_player.png", 50, 20, "skills")
	_def("speed_overdrive", "speed overdrive", "use speed boost 50 times", "res://assets/custom_player.png", 100, 50, "skills")
	_def("aerial_ace", "aerial ace", "perform 10 jumps in a single run", "res://assets/custom_player.png", 40, 10, "skills")

	# =========================================================================
	# CATEGORY 6: SURVIVAL & BOX HEALTH (11 Achievements)
	# =========================================================================
	_def("space_wanderer", "space wanderer", "get lost in space 5 times", "res://assets/game_over_skeleton.png", 30, 5, "survival")
	_def("cosmic_ghost", "cosmic ghost", "get lost in space 20 times", "res://assets/game_over_skeleton.png", 60, 20, "survival")
	_def("asteroid_magnet", "asteroid magnet", "get hit by 10 asteroids", "res://assets/asteroid.png", 30, 10, "survival")
	_def("asteroid_survivor", "asteroid survivor", "get hit by 25 asteroids", "res://assets/asteroid.png", 60, 25, "survival")
	_def("tough_delivery", "tough delivery", "complete a level with under 25% box health", "res://assets/delivery_box.png", 40, 1, "survival")
	_def("critical_cargo", "hanging by thread", "complete a level with under 10% box health", "res://assets/delivery_box.png", 60, 1, "survival")
	_def("perfect_delivery", "perfect delivery", "complete a level with 100% box health", "res://assets/delivery_box.png", 50, 1, "survival")
	_def("iron_frog", "iron frog", "complete 5 levels with 100% box health", "res://assets/delivery_box.png", 100, 5, "survival")
	_def("invincible_carrier", "invincible carrier", "complete 15 levels with 100% box health", "res://assets/delivery_box.png", 200, 15, "survival")
	_def("daily_devotee", "daily devotee", "claim daily reward 7 days in a row", "res://assets/star.png", 100, 7, "survival")
	_def("supreme_ranotot", "supreme ranotot", "unlock 50 achievements", "res://assets/star.png", 500, 50, "survival")

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
	_stats["endless_rubies_collected"] = config.get_value("AchievementStats", "endless_rubies_collected", 0)
	_stats["endless_best_distance"] = config.get_value("AchievementStats", "endless_best_distance", SaveSystem.endless_high_score)
	_stats["lost_in_space"] = config.get_value("AchievementStats", "lost_in_space", 0)
	_stats["asteroid_hits"] = config.get_value("AchievementStats", "asteroid_hits", 0)
	_stats["perfect_deliveries"] = config.get_value("AchievementStats", "perfect_deliveries", 0)
	_stats["total_jumps"] = config.get_value("AchievementStats", "total_jumps", 0)
	_stats["glide_uses"] = config.get_value("AchievementStats", "glide_uses", 0)
	_stats["speed_uses"] = config.get_value("AchievementStats", "speed_uses", 0)
	_stats["rubies_spent"] = config.get_value("AchievementStats", "rubies_spent", 0)
	_stats["levels_completed"] = config.get_value("AchievementStats", "levels_completed", 0)
	_stats["fast_levels"] = config.get_value("AchievementStats", "fast_levels", 0)
	_stats["consecutive_three_stars"] = config.get_value("AchievementStats", "consecutive_three_stars", 0)
	_stats["max_consecutive_three_stars"] = config.get_value("AchievementStats", "max_consecutive_three_stars", 0)

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

func set_stat_max(stat_name: String, value: int) -> void:
	if not _stats.has(stat_name):
		_stats[stat_name] = 0
	if value > _stats[stat_name]:
		_stats[stat_name] = value

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
	var def = _defs.get(id, {})
	if def.is_empty():
		return {"current": 0, "target": 1, "percent": 0.0}
	var target = def.target
	var current = 0
	
	match id:
		# Endless distance
		"endless_100m", "endless_250m", "endless_500m", "endless_750m", "endless_1000m", \
		"endless_1500m", "endless_2000m", "endless_2500m", "endless_3000m", "endless_4000m", \
		"endless_5000m", "endless_7500m", "endless_10000m":
			current = max(get_stat("endless_best_distance"), SaveSystem.endless_high_score)
		"endless_rubies_100", "endless_rubies_500":
			current = get_stat("endless_rubies_collected")
			
		# Campaign levels
		"first_delivery":
			current = 1 if is_unlocked(id) or SaveSystem.unlocked_levels > 1 else 0
		"tier_1_complete", "tier_2_complete", "tier_3_complete", "tier_4_complete", \
		"halfway", "tier_5_complete", "tier_6_complete", "tier_7_complete", \
		"tier_8_complete", "final_frontier":
			current = max(SaveSystem.unlocked_levels - 1, get_stat("levels_completed"))
		"speedy_courier":
			current = get_stat("fast_levels")
		"stellar_veteran", "master_courier", "grand_deliverer":
			current = get_stat("levels_completed")
			
		# Stars
		"rising_star":
			current = 1 if is_unlocked(id) else 0
		"star_10", "star_25", "star_50", "star_75", "star_100", \
		"star_150", "star_200", "star_250", "completionist":
			current = SaveSystem.get_total_stars()
		"perfect_streak_3", "perfect_streak_5":
			current = get_stat("max_consecutive_three_stars")
			
		# Rubies
		"ruby_rookie", "ruby_seeker", "ruby_hunter", "ruby_collector", \
		"ruby_master", "ruby_baron", "ruby_king", "ruby_emperor":
			current = get_stat("total_rubies_collected")
		"smart_shopper", "big_spender":
			current = get_stat("rubies_spent")
			
		# Skills
		"first_jump", "jump_cadet", "jump_pro", "bounce_king", "jump_legend":
			current = get_stat("total_jumps")
		"glide_rookie", "glide_master", "glide_expert":
			current = get_stat("glide_uses")
		"speed_starter", "speed_demon", "speed_overdrive":
			current = get_stat("speed_uses")
		"aerial_ace":
			current = 1 if is_unlocked(id) else 0
			
		# Survival
		"space_wanderer", "cosmic_ghost":
			current = get_stat("lost_in_space")
		"asteroid_magnet", "asteroid_survivor":
			current = get_stat("asteroid_hits")
		"tough_delivery", "critical_cargo", "perfect_delivery":
			current = 1 if is_unlocked(id) else 0
		"iron_frog", "invincible_carrier":
			current = get_stat("perfect_deliveries")
		"daily_devotee":
			current = SaveSystem.streak_count
		"supreme_ranotot":
			current = get_unlocked_count()
			
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
		
		# Check supreme achievement
		if id != "supreme_ranotot":
			try_unlock("supreme_ranotot")
			
		return true
	return false

# ─── Event Hooks ───────────────────────────────────────────────────────

func on_endless_distance(dist: int) -> void:
	set_stat_max("endless_best_distance", dist)
	try_unlock("endless_100m")
	try_unlock("endless_250m")
	try_unlock("endless_500m")
	try_unlock("endless_750m")
	try_unlock("endless_1000m")
	try_unlock("endless_1500m")
	try_unlock("endless_2000m")
	try_unlock("endless_2500m")
	try_unlock("endless_3000m")
	try_unlock("endless_4000m")
	try_unlock("endless_5000m")
	try_unlock("endless_7500m")
	try_unlock("endless_10000m")

func on_endless_ruby_collected(amount: int = 1) -> void:
	increment_stat("endless_rubies_collected", amount)
	increment_stat("total_rubies_collected", amount)
	try_unlock("endless_rubies_100")
	try_unlock("endless_rubies_500")
	_check_ruby_milestones()

func on_ruby_collected(amount: int) -> void:
	increment_stat("total_rubies_collected", amount)
	if GameManager.is_endless_mode:
		increment_stat("endless_rubies_collected", amount)
		try_unlock("endless_rubies_100")
		try_unlock("endless_rubies_500")
	_check_ruby_milestones()

func _check_ruby_milestones() -> void:
	try_unlock("ruby_rookie")
	try_unlock("ruby_seeker")
	try_unlock("ruby_hunter")
	try_unlock("ruby_collector")
	try_unlock("ruby_master")
	try_unlock("ruby_baron")
	try_unlock("ruby_king")
	try_unlock("ruby_emperor")

func on_jump() -> void:
	increment_stat("total_jumps")
	try_unlock("first_jump")
	try_unlock("jump_cadet")
	try_unlock("jump_pro")
	try_unlock("bounce_king")
	try_unlock("jump_legend")

func on_lost_in_space() -> void:
	increment_stat("lost_in_space")
	try_unlock("space_wanderer")
	try_unlock("cosmic_ghost")

func on_asteroid_hit() -> void:
	increment_stat("asteroid_hits")
	try_unlock("asteroid_magnet")
	try_unlock("asteroid_survivor")

func on_level_complete(level: int, stars: int, health: float, time_spent: float = 0.0) -> void:
	increment_stat("levels_completed")
	try_unlock("first_delivery")
	
	if stars == 3:
		try_unlock("rising_star")
		increment_stat("consecutive_three_stars")
		var streak = get_stat("consecutive_three_stars")
		set_stat_max("max_consecutive_three_stars", streak)
		try_unlock("perfect_streak_3")
		try_unlock("perfect_streak_5")
	else:
		_stats["consecutive_three_stars"] = 0
		
	if time_spent > 0.0 and time_spent < 30.0:
		increment_stat("fast_levels")
		try_unlock("speedy_courier")
	
	if health >= 100.0:
		increment_stat("perfect_deliveries")
		try_unlock("perfect_delivery")
		try_unlock("iron_frog")
		try_unlock("invincible_carrier")
	
	if health < 25.0 and health > 0.0:
		try_unlock("tough_delivery")
	if health < 10.0 and health > 0.0:
		try_unlock("critical_cargo")
	
	# Star milestones
	try_unlock("star_10")
	try_unlock("star_25")
	try_unlock("star_50")
	try_unlock("star_75")
	try_unlock("star_100")
	try_unlock("star_150")
	try_unlock("star_200")
	try_unlock("star_250")
	try_unlock("completionist")
	
	# Tier milestones
	if level >= 10: try_unlock("tier_1_complete")
	if level >= 20: try_unlock("tier_2_complete")
	if level >= 30: try_unlock("tier_3_complete")
	if level >= 40: try_unlock("tier_4_complete")
	if level >= 45: try_unlock("halfway")
	if level >= 50: try_unlock("tier_5_complete")
	if level >= 60: try_unlock("tier_6_complete")
	if level >= 70: try_unlock("tier_7_complete")
	if level >= 80: try_unlock("tier_8_complete")
	if level >= 90: try_unlock("final_frontier")
	
	try_unlock("stellar_veteran")
	try_unlock("master_courier")
	try_unlock("grand_deliverer")
	
	_save_data()

func on_glide_used() -> void:
	increment_stat("glide_uses")
	try_unlock("glide_rookie")
	try_unlock("glide_master")
	try_unlock("glide_expert")

func on_speed_used() -> void:
	increment_stat("speed_uses")
	try_unlock("speed_starter")
	try_unlock("speed_demon")
	try_unlock("speed_overdrive")

func on_rubies_spent(amount: int) -> void:
	increment_stat("rubies_spent", amount)
	try_unlock("smart_shopper")
	try_unlock("big_spender")

func on_daily_streak(streak: int) -> void:
	if streak >= 7 or streak == 0:
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

func get_all_achievements(category_filter: String = "all") -> Array:
	var result = []
	var cat_weights = {"endless": 1, "campaign": 2, "stars": 3, "rubies": 4, "skills": 5, "survival": 6}
	for id in _defs:
		var entry = _defs[id].duplicate()
		if category_filter != "all" and entry["category"] != category_filter:
			continue
		entry["id"] = id
		entry["unlocked"] = is_unlocked(id)
		entry["progress"] = get_progress(id)
		entry["sort_rank"] = (0 if entry["unlocked"] else 100) + cat_weights.get(entry["category"], 9)
		result.append(entry)
		
	return QiApex.sort_objects_by_key(result, "sort_rank", true)

func write_to_config(config: ConfigFile) -> void:
	for id in _unlocked:
		config.set_value("Achievements", id, _unlocked[id])
	for stat in _stats:
		config.set_value("AchievementStats", stat, _stats[stat])
