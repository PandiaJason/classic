extends CanvasLayer


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	
	var health = GameManager.box_health
	var star_count = 0
	if health >= 80.0:
		star_count = 3
	elif health >= 70.0:
		star_count = 2
	elif health >= 20.0:
		star_count = 1
		
	SaveSystem.complete_level(GameManager.current_level, star_count)
	AchievementManager.on_level_complete(GameManager.current_level, star_count, health)
	
	# Delete original simple UI
	if has_node("VBoxContainer"): $VBoxContainer.queue_free()
	if has_node("Overlay"): $Overlay.queue_free()
	
	# Create Background Overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	# Create Center Panel
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.1, 0.0, 0.8)
	style.corner_radius_top_left = 30
	style.corner_radius_top_right = 30
	style.corner_radius_bottom_right = 30
	style.corner_radius_bottom_left = 30
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.2, 1.0, 0.2, 1.0)
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	style.shadow_color = Color(0.0, 1.0, 0.0, 0.4)
	style.shadow_size = 20
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var title = Label.new()
	title.text = "successful delivery"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	title.add_theme_font_size_override("font_size", 50)
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 10)
	vbox.add_child(title)
	
	var stars_hbox = HBoxContainer.new()
	stars_hbox.add_theme_constant_override("separation", 20)
	stars_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	for i in range(3):
		var star = TextureRect.new()
		star.texture = load("res://assets/star.png")
		star.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.custom_minimum_size = Vector2(60, 60)
		if i >= star_count:
			star.modulate = Color(0.3, 0.3, 0.3, 1.0) # Darken missing stars
		stars_hbox.add_child(star)
		
	vbox.add_child(stars_hbox)
	
	# Stats breakdown
	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 5)
	stats_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var rubies_lbl = Label.new()
	rubies_lbl.text = "rubies collected: %d" % GameManager.level_rubies
	rubies_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rubies_lbl.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	rubies_lbl.add_theme_font_size_override("font_size", 24)
	rubies_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2)) # Premium Gold
	stats_vbox.add_child(rubies_lbl)
	
	var ruby_earned_lbl = Label.new()
	ruby_earned_lbl.text = "ruby earned: +%d" % GameManager.level_rubies_earned
	ruby_earned_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ruby_earned_lbl.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	ruby_earned_lbl.add_theme_font_size_override("font_size", 24)
	ruby_earned_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	stats_vbox.add_child(ruby_earned_lbl)
	
	var health_lbl = Label.new()
	health_lbl.text = "box health: %d%%" % int(GameManager.box_health)
	health_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_lbl.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	health_lbl.add_theme_font_size_override("font_size", 24)
	health_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	stats_vbox.add_child(health_lbl)
	
	vbox.add_child(stats_vbox)
	
	var box_icon = TextureRect.new()
	box_icon.texture = load(SaveSystem.get_level_complete_texture_path())
	box_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	box_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	box_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box_icon.custom_minimum_size = Vector2(200, 170)
	vbox.add_child(box_icon)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var menu_btn = UIFactory.create_glass_button("menu", Color(0.5, 0.5, 0.5))
	menu_btn.pressed.connect(_on_menu_pressed)
	hbox.add_child(menu_btn)
	
	var next_level_id = GameManager.current_level + 1
	var next_level_unlocked = SaveSystem.is_level_unlocked(next_level_id)
	
	var btn_text = "finish" if GameManager.current_level >= 90 else ("next level" if next_level_unlocked else "level select")
	var btn_color = Color(0.2, 1.0, 0.2) if (GameManager.current_level >= 90 or next_level_unlocked) else Color(0.2, 0.6, 1.0)
	var next_btn = UIFactory.create_glass_button(btn_text, btn_color)
	next_btn.pressed.connect(_on_next_pressed)
	hbox.add_child(next_btn)
	
	vbox.add_child(hbox)
	
	menu_btn.focus_neighbor_right = next_btn.get_path()
	next_btn.focus_neighbor_left = menu_btn.get_path()
	panel.add_child(vbox)
	
	var center = CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.add_child(panel)
	add_child(center)
	
	next_btn.grab_focus()

func _on_next_pressed():
	get_tree().paused = false
	queue_free()
	GameManager.load_next_level()

func _on_menu_pressed():
	get_tree().paused = false
	queue_free()
	SceneTransition.transition_to("res://scenes/menu.tscn")
