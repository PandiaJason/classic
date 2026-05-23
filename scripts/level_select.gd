extends Control

@onready var grid = $ScrollContainer/MarginContainer/GridContainer

var total_levels = 30

func _ready():
	BgmManager.play_menu_music()
	# Add Blur Background
	var blur = ColorRect.new()
	blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/blur.gdshader")
	blur.material = mat
	add_child(blur)
	move_child(blur, 1) # Move it behind the scroll container
	
	# Generate buttons
	for i in range(1, total_levels + 1):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(130, 130)
		btn.add_theme_font_override("font", load("res://assets/game_font.ttf"))
		btn.add_theme_font_size_override("font_size", 60)
		
		var is_unlocked = SaveSystem.is_level_unlocked(i)
		
		if is_unlocked:
			btn.text = str(i)
			btn.add_theme_stylebox_override("normal", load_style("unlocked"))
			btn.add_theme_stylebox_override("hover", load_style("unlocked_hover"))
			btn.add_theme_stylebox_override("pressed", load_style("unlocked"))
			
			var stars_earned = SaveSystem.get_stars(i)
			if stars_earned > 0:
				add_stars(btn, stars_earned)
				
			btn.pressed.connect(_on_level_selected.bind(i))
		else:
			btn.text = ""
			var lock_tex = load("res://assets/lock_icon.png")
			if lock_tex:
				var lock_icon = TextureRect.new()
				lock_icon.texture = lock_tex
				lock_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
				lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				lock_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				lock_icon.offset_left = 30
				lock_icon.offset_top = 30
				lock_icon.offset_right = -30
				lock_icon.offset_bottom = -30
				btn.add_child(lock_icon)
				
			btn.add_theme_stylebox_override("normal", load_style("locked"))
			btn.add_theme_stylebox_override("hover", load_style("locked"))
			btn.add_theme_stylebox_override("pressed", load_style("locked"))
			# Don't connect pressed signal, so it's disabled effectively
			
		grid.add_child(btn)

	# Setup Back Button (using UIFactory to match in-game style)
	var back_button = UIFactory.create_glass_button("back", UIFactory.RED_COLOR)
	back_button.pressed.connect(_on_back_pressed)
	
	var back_margin = MarginContainer.new()
	back_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	back_margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
	back_margin.add_theme_constant_override("margin_bottom", 20)
	back_margin.add_theme_constant_override("margin_left", 40)
	back_margin.add_child(back_button)
	add_child(back_margin)

	# Setup Shop UI
	var shop_hbox = HBoxContainer.new()
	shop_hbox.add_theme_constant_override("separation", 20)
	shop_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var ruby_icon = TextureRect.new()
	ruby_icon.texture = load("res://assets/ruby.png")
	ruby_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ruby_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ruby_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ruby_icon.custom_minimum_size = Vector2(30, 30)
	
	var score_label = Label.new()
	score_label.text = str(SaveSystem.global_score)
	score_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	score_label.add_theme_font_size_override("font_size", 32)
	score_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	score_label.add_theme_constant_override("outline_size", 5)
	
	var ruby_hbox = HBoxContainer.new()
	ruby_hbox.add_theme_constant_override("separation", 5)
	ruby_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	ruby_hbox.add_child(ruby_icon)
	ruby_hbox.add_child(score_label)
	shop_hbox.add_child(ruby_hbox)
	
	# Glide assist button or owned label
	var glide_count_label = Label.new()
	if SaveSystem.glide_count > 0:
		glide_count_label.text = "glides: %d" % SaveSystem.glide_count
		glide_count_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	else:
		glide_count_label.text = "glides: 0"
		glide_count_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	glide_count_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	glide_count_label.add_theme_font_size_override("font_size", 28)
	glide_count_label.add_theme_constant_override("outline_size", 5)
	shop_hbox.add_child(glide_count_label)
	
	# Always show buy button
	var buy_btn = UIFactory.create_glass_button("buy glide (30)", Color(0.2, 0.6, 1.0))
	buy_btn.pressed.connect(_on_buy_glide)
	# Disable if not enough rubies
	if SaveSystem.global_score < 30:
		buy_btn.disabled = true
		buy_btn.modulate.a = 0.4
	shop_hbox.add_child(buy_btn)
	
	var shop_margin = MarginContainer.new()
	shop_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	shop_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	shop_margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
	shop_margin.add_theme_constant_override("margin_bottom", 20)
	shop_margin.add_theme_constant_override("margin_right", 40)
	shop_margin.add_child(shop_hbox)
	add_child(shop_margin)

func load_style(type: String) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 25
	style.corner_radius_top_right = 25
	style.corner_radius_bottom_right = 25
	style.corner_radius_bottom_left = 25
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	
	if type == "unlocked":
		style.bg_color = Color(0.8, 0.4, 0.1, 0.8) # Orange
		style.border_color = Color(1.0, 0.6, 0.2, 0.8)
		style.shadow_color = Color(1.0, 0.5, 0.0, 0.4)
		style.shadow_size = 15
	elif type == "unlocked_hover":
		style.bg_color = Color(0.9, 0.5, 0.1, 1.0)
		style.border_color = Color(1.0, 0.8, 0.3, 1.0)
		style.shadow_color = Color(1.0, 0.6, 0.0, 0.6)
		style.shadow_size = 25
	else:
		style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
		style.border_color = Color(0.3, 0.3, 0.3, 0.5)
		
	return style

func add_stars(parent: Control, star_count: int):
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hbox.offset_bottom = 20
	hbox.offset_top = 0
	hbox.add_theme_constant_override("separation", 5)
	
	for i in range(star_count):
		var star = TextureRect.new()
		star.texture = load("res://assets/star.png")
		star.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.custom_minimum_size = Vector2(25, 25)
		hbox.add_child(star)
		
	parent.add_child(hbox)

func _on_level_selected(level: int):
	GameManager.current_level = level
	GameManager.reset_score()
	BgmManager.stop_menu_music()
	get_tree().change_scene_to_file("res://scenes/level_" + str(level) + ".tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _on_buy_glide():
	if SaveSystem.purchase_glide():
		# Refresh the scene to show updated shop
		get_tree().change_scene_to_file("res://scenes/level_select.tscn")
