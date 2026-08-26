extends CanvasLayer

var game_over_reason: String = "you were destroyed!"


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	
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
	style.bg_color = Color(0.1, 0.0, 0.0, 0.8)
	style.corner_radius_top_left = 30
	style.corner_radius_top_right = 30
	style.corner_radius_bottom_right = 30
	style.corner_radius_bottom_left = 30
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(1.0, 0.2, 0.2, 1.0)
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	style.shadow_color = Color(1.0, 0.0, 0.0, 0.4)
	style.shadow_size = 20
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var title = Label.new()
	title.text = "game over"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	title.add_theme_font_size_override("font_size", 60)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 10)
	vbox.add_child(title)
	
	var skeleton_icon = TextureRect.new()
	skeleton_icon.texture = load("res://assets/game_over_skeleton.png")
	skeleton_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skeleton_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	skeleton_icon.custom_minimum_size = Vector2(250, 220)
	skeleton_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	vbox.add_child(skeleton_icon)
	
	var subtitle = Label.new()
	if GameManager.is_endless_mode:
		var is_new_record = SaveSystem.save_endless_score(GameManager.endless_score)
		if is_new_record:
			subtitle.text = "NEW DISTANCE RECORD: %dm!" % GameManager.endless_score
			subtitle.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
		else:
			subtitle.text = "DISTANCE: %dm\n(BEST RECORD: %dm)" % [GameManager.endless_score, SaveSystem.endless_high_score]
			subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	else:
		subtitle.text = game_over_reason
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	subtitle.add_theme_font_size_override("font_size", 24)
	vbox.add_child(subtitle)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var menu_btn = UIFactory.create_glass_button("menu", Color(0.5, 0.5, 0.5))
	menu_btn.pressed.connect(_on_menu_pressed)
	hbox.add_child(menu_btn)
	
	var retry_btn = UIFactory.create_glass_button("retry", Color(1.0, 0.2, 0.2))
	retry_btn.pressed.connect(_on_retry_pressed)
	hbox.add_child(retry_btn)
	
	vbox.add_child(hbox)
	
	panel.add_child(vbox)
	
	var center = CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.add_child(panel)
	add_child(center)
	
	menu_btn.focus_neighbor_right = retry_btn.get_path()
	retry_btn.focus_neighbor_left = menu_btn.get_path()
	retry_btn.grab_focus()

func _on_retry_pressed():
	get_tree().paused = false
	GameManager._game_ended = false
	GameManager.reset_rubies()
	queue_free()
	if GameManager.is_endless_mode:
		GameManager.is_gameplay_started = true
		SceneTransition.transition_to("res://scenes/level_endless.tscn")
	else:
		SceneTransition.reload_current()

func _on_menu_pressed():
	get_tree().paused = false
	GameManager._game_ended = false
	GameManager.is_endless_mode = false
	queue_free()
	SceneTransition.transition_to("res://scenes/menu.tscn")