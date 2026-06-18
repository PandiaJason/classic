extends Control

@onready var grid = $ScrollContainer/MarginContainer/GridContainer

var total_levels = 90

var ruby_label: Label
var glide_count_label: Label
var buy_btn: Button
var speed_count_label: Label
var buy_speed_btn: Button

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
			
			# Determine star gate requirement
			var req_stars = 0
			if i >= 81: req_stars = 200
			elif i >= 71: req_stars = 165
			elif i >= 61: req_stars = 135
			elif i >= 51: req_stars = 110
			elif i >= 41: req_stars = 90
			elif i >= 31: req_stars = 75
			elif i >= 26: req_stars = 60
			elif i >= 21: req_stars = 45
			elif i >= 16: req_stars = 30
			elif i >= 11: req_stars = 15
			elif i >= 6: req_stars = 5
			
			var lock_tex = load("res://assets/lock_icon.png")
			if lock_tex:
				var lock_icon = TextureRect.new()
				lock_icon.texture = lock_tex
				lock_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
				lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				lock_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				lock_icon.offset_left = 35
				lock_icon.offset_top = 20
				lock_icon.offset_right = -35
				lock_icon.offset_bottom = -45
				btn.add_child(lock_icon)
				
			if req_stars > 0:
				var req_label = Label.new()
				req_label.text = "%d ★" % req_stars
				req_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
				req_label.add_theme_font_size_override("font_size", 20)
				req_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
				req_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				req_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
				req_label.offset_bottom = -8
				btn.add_child(req_label)
				
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
	
	# Stars progress indicator
	var stars_hbox = HBoxContainer.new()
	stars_hbox.add_theme_constant_override("separation", 5)
	stars_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var star_icon = TextureRect.new()
	star_icon.texture = load("res://assets/star.png")
	star_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	star_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star_icon.custom_minimum_size = Vector2(30, 30)
	
	var stars_lbl = Label.new()
	stars_lbl.text = "%d/%d" % [SaveSystem.get_total_stars(), 270]
	stars_lbl.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	stars_lbl.add_theme_font_size_override("font_size", 32)
	stars_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	stars_lbl.add_theme_constant_override("outline_size", 5)
	
	stars_hbox.add_child(star_icon)
	stars_hbox.add_child(stars_lbl)
	shop_hbox.add_child(stars_hbox)
	
	var ruby_icon = TextureRect.new()
	ruby_icon.texture = load("res://assets/ruby.png")
	ruby_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ruby_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ruby_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ruby_icon.custom_minimum_size = Vector2(30, 30)
	
	ruby_label = Label.new()
	ruby_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	ruby_label.add_theme_font_size_override("font_size", 32)
	ruby_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	ruby_label.add_theme_constant_override("outline_size", 5)
	
	var ruby_hbox = HBoxContainer.new()
	ruby_hbox.add_theme_constant_override("separation", 5)
	ruby_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	ruby_hbox.add_child(ruby_icon)
	ruby_hbox.add_child(ruby_label)
	shop_hbox.add_child(ruby_hbox)
	
	# Glide assist button or owned label
	glide_count_label = Label.new()
	glide_count_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	glide_count_label.add_theme_font_size_override("font_size", 28)
	glide_count_label.add_theme_constant_override("outline_size", 5)
	shop_hbox.add_child(glide_count_label)
	
	# Always show buy button
	buy_btn = UIFactory.create_glass_button("buy glide (30)", Color(0.2, 0.6, 1.0))
	buy_btn.pressed.connect(_on_buy_glide)
	shop_hbox.add_child(buy_btn)

	# Speed assist button or owned label
	speed_count_label = Label.new()
	speed_count_label.add_theme_font_override("font", load("res://assets/game_font.ttf"))
	speed_count_label.add_theme_font_size_override("font_size", 28)
	speed_count_label.add_theme_constant_override("outline_size", 5)
	shop_hbox.add_child(speed_count_label)
	
	# Always show buy speed button
	buy_speed_btn = UIFactory.create_glass_button("buy speed (30)", Color(1.0, 0.4, 0.2))
	buy_speed_btn.pressed.connect(_on_buy_speed)
	shop_hbox.add_child(buy_speed_btn)
	
	_update_shop_ui()
	
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
	GameManager.reset_rubies()
	BgmManager.stop_menu_music()
	SceneTransition.transition_to("res://scenes/level_" + str(level) + ".tscn")

func _on_back_pressed():
	SceneTransition.transition_to("res://scenes/menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _on_buy_glide():
	if SaveSystem.purchase_glide():
		_update_shop_ui()

func _on_buy_speed():
	if SaveSystem.purchase_speed():
		_update_shop_ui()

func _update_shop_ui() -> void:
	if is_instance_valid(ruby_label):
		ruby_label.text = str(SaveSystem.global_rubies)
		
	if is_instance_valid(glide_count_label):
		if SaveSystem.glide_count > 0:
			glide_count_label.text = "glides: %d" % SaveSystem.glide_count
			glide_count_label.add_theme_color_override("font_color", Color.WHITE)
		else:
			glide_count_label.text = "glides: 0"
			glide_count_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			
	if is_instance_valid(buy_btn):
		if SaveSystem.global_rubies < 30:
			buy_btn.disabled = true
			buy_btn.modulate.a = 0.4
		else:
			buy_btn.disabled = false
			buy_btn.modulate.a = 1.0

	if is_instance_valid(speed_count_label):
		if SaveSystem.speed_count > 0:
			speed_count_label.text = "speeds: %d" % SaveSystem.speed_count
			speed_count_label.add_theme_color_override("font_color", Color.WHITE)
		else:
			speed_count_label.text = "speeds: 0"
			speed_count_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			
	if is_instance_valid(buy_speed_btn):
		if SaveSystem.global_rubies < 30:
			buy_speed_btn.disabled = true
			buy_speed_btn.modulate.a = 0.4
		else:
			buy_speed_btn.disabled = false
			buy_speed_btn.modulate.a = 1.0
