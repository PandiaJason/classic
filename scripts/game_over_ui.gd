extends CanvasLayer

func create_glass_button(text: String, color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	btn.add_theme_font_size_override("font_size", 32)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.5)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_right = 15
	style.corner_radius_bottom_left = 15
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = color
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	
	var hover_style = style.duplicate()
	hover_style.bg_color = Color(color.r, color.g, color.b, 0.8)
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", style)
	return btn

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
	style.content_margin_left = 50
	style.content_margin_right = 50
	style.content_margin_top = 50
	style.content_margin_bottom = 50
	style.shadow_color = Color(1.0, 0.0, 0.0, 0.4)
	style.shadow_size = 30
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 40)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var title = Label.new()
	title.text = "game over"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 10)
	vbox.add_child(title)
	
	var skeleton_icon = TextureRect.new()
	skeleton_icon.texture = load("res://assets/game_over_skeleton.png")
	skeleton_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skeleton_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	skeleton_icon.custom_minimum_size = Vector2(400, 350)
	skeleton_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	vbox.add_child(skeleton_icon)
	
	var subtitle = Label.new()
	subtitle.text = GameManager.last_game_over_reason if GameManager.last_game_over_reason != "" else "you were destroyed!"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.custom_minimum_size = Vector2(500, 0)
	vbox.add_child(subtitle)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var menu_btn = create_glass_button("menu", Color(0.5, 0.5, 0.5))
	menu_btn.pressed.connect(_on_menu_pressed)
	hbox.add_child(menu_btn)
	
	var retry_btn = create_glass_button("retry", Color(1.0, 0.2, 0.2))
	retry_btn.pressed.connect(_on_retry_pressed)
	hbox.add_child(retry_btn)
	
	vbox.add_child(hbox)
	panel.add_child(vbox)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.add_child(panel)
	add_child(center)

func _on_retry_pressed():
	get_tree().paused = false
	GameManager.reset_score()
	get_tree().reload_current_scene()

func _on_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
