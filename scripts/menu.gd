extends Control

func _ready():
	$VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.6)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_right = 20
	style.corner_radius_bottom_left = 20
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 0.8, 0.2, 0.8)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	
	var ruby_icon = TextureRect.new()
	ruby_icon.texture = load("res://assets/ruby.png")
	ruby_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ruby_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ruby_icon.custom_minimum_size = Vector2(40, 40)
	
	var score_label = Label.new()
	score_label.text = "score: " + str(SaveSystem.global_score)
	score_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	score_label.add_theme_font_size_override("font_size", 30)
	score_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	score_label.add_theme_color_override("font_outline_color", Color.BLACK)
	score_label.add_theme_constant_override("outline_size", 8)
	
	hbox.add_child(ruby_icon)
	hbox.add_child(score_label)
	panel.add_child(hbox)
	
	var score_margin = MarginContainer.new()
	score_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	score_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	score_margin.add_theme_constant_override("margin_top", 30)
	score_margin.add_theme_constant_override("margin_right", 30)
	score_margin.add_child(panel)
	add_child(score_margin)
	
	# Add Music Toggle Button
	var music_btn = Button.new()
	music_btn.text = "music: on"
	music_btn.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	music_btn.add_theme_font_size_override("font_size", 30)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.1, 0.4, 0.8, 0.8)
	btn_style.corner_radius_top_left = 15
	btn_style.corner_radius_top_right = 15
	btn_style.corner_radius_bottom_right = 15
	btn_style.corner_radius_bottom_left = 15
	btn_style.border_width_left = 2
	btn_style.border_width_top = 2
	btn_style.border_width_right = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.3, 0.6, 1.0, 0.8)
	btn_style.content_margin_left = 20
	btn_style.content_margin_right = 20
	btn_style.content_margin_top = 10
	btn_style.content_margin_bottom = 10
	music_btn.add_theme_stylebox_override("normal", btn_style)
	music_btn.add_theme_stylebox_override("hover", btn_style)
	music_btn.add_theme_stylebox_override("pressed", btn_style)
	
	var music_margin = MarginContainer.new()
	music_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	music_margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
	music_margin.add_theme_constant_override("margin_bottom", 30)
	music_margin.add_theme_constant_override("margin_left", 30)
	music_margin.add_child(music_btn)
	add_child(music_margin)
	
	music_btn.pressed.connect(_on_music_pressed.bind(music_btn))
	
	# Calculate and Display Delivery Rate (Top Center)
	var unlocked_count = 0
	var total_stars = 0
	for i in range(1, 31):
		if SaveSystem.is_level_unlocked(i):
			unlocked_count += 1
			total_stars += SaveSystem.get_stars(i)

	var delivery_rate = 0.0
	if unlocked_count > 0:
		delivery_rate = float(total_stars) / float(unlocked_count * 3.0)
		
	var rate_panel = PanelContainer.new()
	var rate_style = StyleBoxFlat.new()
	rate_style.bg_color = Color(0, 0, 0, 0.6)
	rate_style.corner_radius_top_left = 20
	rate_style.corner_radius_top_right = 20
	rate_style.corner_radius_bottom_right = 20
	rate_style.corner_radius_bottom_left = 20
	rate_style.border_width_left = 2
	rate_style.border_width_top = 2
	rate_style.border_width_right = 2
	rate_style.border_width_bottom = 2
	rate_style.border_color = Color(1, 0.8, 0.2, 0.8)
	rate_style.content_margin_left = 20
	rate_style.content_margin_right = 20
	rate_style.content_margin_top = 10
	rate_style.content_margin_bottom = 10
	rate_panel.add_theme_stylebox_override("panel", rate_style)
	
	var rate_hbox = HBoxContainer.new()
	rate_hbox.add_theme_constant_override("separation", 10)
	rate_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var delivery_icon = TextureRect.new()
	delivery_icon.texture = load("res://assets/delivery_box.png")
	delivery_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	delivery_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	delivery_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	delivery_icon.custom_minimum_size = Vector2(76, 40)
	
	var rate_label = Label.new()
	rate_label.text = "delivery rate: %.2f" % delivery_rate
	rate_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	rate_label.add_theme_font_size_override("font_size", 30)
	rate_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	rate_label.add_theme_color_override("font_outline_color", Color.BLACK)
	rate_label.add_theme_constant_override("outline_size", 8)
	
	rate_hbox.add_child(delivery_icon)
	rate_hbox.add_child(rate_label)
	rate_panel.add_child(rate_hbox)
	
	var rate_margin = MarginContainer.new()
	rate_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	rate_margin.grow_horizontal = Control.GROW_DIRECTION_END
	rate_margin.add_theme_constant_override("margin_top", 30)
	rate_margin.add_theme_constant_override("margin_left", 30)
	rate_margin.add_child(rate_panel)
	add_child(rate_margin)

	# Reset Button (Bottom Right)
	var reset_btn = Button.new()
	reset_btn.text = "reset"
	reset_btn.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	reset_btn.add_theme_font_size_override("font_size", 22)
	var reset_style = StyleBoxFlat.new()
	reset_style.bg_color = Color(0.5, 0.1, 0.1, 0.7)
	reset_style.corner_radius_top_left = 12
	reset_style.corner_radius_top_right = 12
	reset_style.corner_radius_bottom_right = 12
	reset_style.corner_radius_bottom_left = 12
	reset_style.border_width_left = 2
	reset_style.border_width_top = 2
	reset_style.border_width_right = 2
	reset_style.border_width_bottom = 2
	reset_style.border_color = Color(1, 0.3, 0.3, 0.8)
	reset_style.content_margin_left = 16
	reset_style.content_margin_right = 16
	reset_style.content_margin_top = 8
	reset_style.content_margin_bottom = 8
	reset_btn.add_theme_stylebox_override("normal", reset_style)
	reset_btn.add_theme_stylebox_override("hover", reset_style)
	reset_btn.add_theme_stylebox_override("pressed", reset_style)
	reset_btn.add_theme_color_override("font_color", Color(1, 0.5, 0.5))

	var reset_margin = MarginContainer.new()
	reset_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	reset_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	reset_margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
	reset_margin.add_theme_constant_override("margin_bottom", 30)
	reset_margin.add_theme_constant_override("margin_right", 30)
	reset_margin.add_child(reset_btn)
	add_child(reset_margin)

	reset_btn.pressed.connect(_on_reset_pressed)

func _on_music_pressed(btn: Button):
	var bus_idx = AudioServer.get_bus_index("Master")
	var is_muted = AudioServer.is_bus_mute(bus_idx)
	AudioServer.set_bus_mute(bus_idx, not is_muted)
	btn.text = "music: off" if not is_muted else "music: on"

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func _on_reset_pressed():
	# Build confirmation dialog
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var dialog = PanelContainer.new()
	var dialog_style = StyleBoxFlat.new()
	dialog_style.bg_color = Color(0.1, 0.05, 0.05, 0.98)
	dialog_style.corner_radius_top_left = 20
	dialog_style.corner_radius_top_right = 20
	dialog_style.corner_radius_bottom_right = 20
	dialog_style.corner_radius_bottom_left = 20
	dialog_style.border_width_left = 3
	dialog_style.border_width_top = 3
	dialog_style.border_width_right = 3
	dialog_style.border_width_bottom = 3
	dialog_style.border_color = Color(1, 0.3, 0.3)
	dialog_style.content_margin_left = 40
	dialog_style.content_margin_right = 40
	dialog_style.content_margin_top = 30
	dialog_style.content_margin_bottom = 30
	dialog.add_theme_stylebox_override("panel", dialog_style)
	dialog.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	dialog.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dialog.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(dialog)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var warn_title = Label.new()
	warn_title.text = "⚠ reset game?"
	warn_title.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	warn_title.add_theme_font_size_override("font_size", 44)
	warn_title.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	warn_title.add_theme_color_override("font_outline_color", Color.BLACK)
	warn_title.add_theme_constant_override("outline_size", 6)
	warn_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(warn_title)

	var warn_msg = Label.new()
	warn_msg.text = "all progress, stars and score\nwill be permanently deleted!"
	warn_msg.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	warn_msg.add_theme_font_size_override("font_size", 28)
	warn_msg.add_theme_color_override("font_color", Color(1, 0.8, 0.8))
	warn_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(warn_msg)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 20)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER

	var cancel_btn = Button.new()
	cancel_btn.text = "cancel"
	cancel_btn.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	cancel_btn.add_theme_font_size_override("font_size", 30)
	var cancel_style = StyleBoxFlat.new()
	cancel_style.bg_color = Color(0.2, 0.4, 0.8, 0.8)
	cancel_style.corner_radius_top_left = 15
	cancel_style.corner_radius_top_right = 15
	cancel_style.corner_radius_bottom_right = 15
	cancel_style.corner_radius_bottom_left = 15
	cancel_style.border_width_left = 2
	cancel_style.border_width_top = 2
	cancel_style.border_width_right = 2
	cancel_style.border_width_bottom = 2
	cancel_style.border_color = Color(0.4, 0.6, 1.0)
	cancel_style.content_margin_left = 24
	cancel_style.content_margin_right = 24
	cancel_style.content_margin_top = 10
	cancel_style.content_margin_bottom = 10
	cancel_btn.add_theme_stylebox_override("normal", cancel_style)
	cancel_btn.add_theme_stylebox_override("hover", cancel_style)
	cancel_btn.add_theme_stylebox_override("pressed", cancel_style)
	cancel_btn.pressed.connect(func():
		overlay.queue_free()
		dialog.queue_free()
	)

	var confirm_btn = Button.new()
	confirm_btn.text = "yes, reset!"
	confirm_btn.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	confirm_btn.add_theme_font_size_override("font_size", 30)
	var confirm_style = StyleBoxFlat.new()
	confirm_style.bg_color = Color(0.7, 0.1, 0.1, 0.9)
	confirm_style.corner_radius_top_left = 15
	confirm_style.corner_radius_top_right = 15
	confirm_style.corner_radius_bottom_right = 15
	confirm_style.corner_radius_bottom_left = 15
	confirm_style.border_width_left = 2
	confirm_style.border_width_top = 2
	confirm_style.border_width_right = 2
	confirm_style.border_width_bottom = 2
	confirm_style.border_color = Color(1, 0.3, 0.3)
	confirm_style.content_margin_left = 24
	confirm_style.content_margin_right = 24
	confirm_style.content_margin_top = 10
	confirm_style.content_margin_bottom = 10
	confirm_btn.add_theme_stylebox_override("normal", confirm_style)
	confirm_btn.add_theme_stylebox_override("hover", confirm_style)
	confirm_btn.add_theme_stylebox_override("pressed", confirm_style)
	confirm_btn.add_theme_color_override("font_color", Color(1, 0.6, 0.6))
	confirm_btn.pressed.connect(func():
		SaveSystem.unlocked_levels = 1
		SaveSystem.global_score = 0
		for i in range(1, 31):
			SaveSystem.level_stars[i] = 0
		SaveSystem.save_data()
		get_tree().reload_current_scene()
	)

	btn_row.add_child(cancel_btn)
	btn_row.add_child(confirm_btn)
	vbox.add_child(btn_row)
	dialog.add_child(vbox)
