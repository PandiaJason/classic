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
	
	var health = GameManager.box_health
	var star_count = 0
	if health >= 80.0:
		star_count = 3
	elif health >= 70.0:
		star_count = 2
	elif health >= 20.0:
		star_count = 1
		
	SaveSystem.complete_level(GameManager.current_level, star_count)
	
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
	style.content_margin_left = 50
	style.content_margin_right = 50
	style.content_margin_top = 50
	style.content_margin_bottom = 50
	style.shadow_color = Color(0.0, 1.0, 0.0, 0.4)
	style.shadow_size = 30
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 30)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var title = Label.new()
	title.text = "successful delivery"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	title.add_theme_font_size_override("font_size", 60)
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
		star.custom_minimum_size = Vector2(80, 80)
		if i >= star_count:
			star.modulate = Color(0.3, 0.3, 0.3, 1.0) # Darken missing stars
		stars_hbox.add_child(star)
		
	vbox.add_child(stars_hbox)
	
	var box_icon = TextureRect.new()
	box_icon.texture = load("res://assets/level_complete_success.png")
	box_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	box_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	box_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box_icon.custom_minimum_size = Vector2(400, 350)
	vbox.add_child(box_icon)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var btn_text = "finish" if GameManager.current_level >= 30 else "next level"
	var next_btn = create_glass_button(btn_text, Color(0.2, 1.0, 0.2))
	next_btn.pressed.connect(_on_menu_pressed)
	hbox.add_child(next_btn)
	
	vbox.add_child(hbox)
	panel.add_child(vbox)
	
	var center = CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.add_child(panel)
	add_child(center)
	
	get_tree().get_root().size_changed.connect(_on_size_changed)
	call_deferred("_on_size_changed")

func _on_size_changed():
	var vp_size = get_viewport().get_visible_rect().size
	var center = get_node_or_null("CenterContainer")
	if center:
		# Base resolution is roughly 1280x720. We scale down if smaller, or up if larger.
		var scale_factor = min(vp_size.x / 1280.0, vp_size.y / 720.0)
		center.pivot_offset = vp_size / 2.0
		center.scale = Vector2(scale_factor, scale_factor)

func _on_menu_pressed():
	get_tree().paused = false
	queue_free()
	GameManager.load_next_level()
