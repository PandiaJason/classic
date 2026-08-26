extends ColorRect

# Self-contained Achievements Modal Overlay with Full Controller / Joystick / Keyboard Navigation

const GAME_FONT = preload("res://assets/game_font.ttf")

var scroll: ScrollContainer
var grid: VBoxContainer
var close_btn: Button
var tab_buttons: Array = []
var selected_cat: String = "all"
var current_tab_idx: int = 0
var on_close_callback: Callable

var categories = [
	{"id": "all", "label": "all (75)"},
	{"id": "endless", "label": "endless"},
	{"id": "campaign", "label": "campaign"},
	{"id": "stars", "label": "stars"},
	{"id": "rubies", "label": "rubies"},
	{"id": "skills", "label": "skills"},
	{"id": "survival", "label": "survival"}
]

func _ready() -> void:
	name = "AchievementsOverlay"
	color = Color(0, 0, 0, 0.88)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_build_ui()
	set_process(true)
	set_process_unhandled_input(true)

func _build_ui() -> void:
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.09, 0.95)
	style.corner_radius_top_left = 25
	style.corner_radius_top_right = 25
	style.corner_radius_bottom_right = 25
	style.corner_radius_bottom_left = 25
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(1, 0.85, 0.2, 0.9)
	style.content_margin_left = 25
	style.content_margin_right = 25
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	style.shadow_color = Color(0.8, 0.6, 0.0, 0.25)
	style.shadow_size = 20
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	
	var outer_vbox = VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 10)
	outer_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Header HBox: Title & Overall Progress
	var header_vbox = VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 4)
	header_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var unlocked_num = AchievementManager.get_unlocked_count()
	var total_num = AchievementManager.get_total_count()
	var pct = (float(unlocked_num) / float(total_num)) * 100.0 if total_num > 0 else 0.0
	
	var title = Label.new()
	title.text = "🏆 achievements (%d / %d  •  %.0f%%)" % [unlocked_num, total_num, pct]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", GAME_FONT)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	header_vbox.add_child(title)
	
	# Overall Progress Bar
	var pbar = ProgressBar.new()
	pbar.custom_minimum_size = Vector2(500, 10)
	pbar.min_value = 0
	pbar.max_value = total_num
	pbar.value = unlocked_num
	pbar.show_percentage = false
	var pbar_bg = StyleBoxFlat.new()
	pbar_bg.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	pbar_bg.corner_radius_top_left = 5
	pbar_bg.corner_radius_top_right = 5
	pbar_bg.corner_radius_bottom_right = 5
	pbar_bg.corner_radius_bottom_left = 5
	var pbar_fg = StyleBoxFlat.new()
	pbar_fg.bg_color = Color(1.0, 0.85, 0.2, 0.9)
	pbar_fg.corner_radius_top_left = 5
	pbar_fg.corner_radius_top_right = 5
	pbar_fg.corner_radius_bottom_right = 5
	pbar_fg.corner_radius_bottom_left = 5
	pbar.add_theme_stylebox_override("background", pbar_bg)
	pbar.add_theme_stylebox_override("fill", pbar_fg)
	header_vbox.add_child(pbar)
	outer_vbox.add_child(header_vbox)
	
	# Category Filter Tabs
	var tabs_hbox = HBoxContainer.new()
	tabs_hbox.add_theme_constant_override("separation", 8)
	tabs_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Scrollable container for achievements
	scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(760, 400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	
	grid = VBoxContainer.new()
	grid.add_theme_constant_override("separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	
	for i in range(categories.size()):
		var tab_info = categories[i]
		var tab_btn = Button.new()
		tab_btn.text = tab_info.label
		tab_btn.add_theme_font_override("font", GAME_FONT)
		tab_btn.add_theme_font_size_override("font_size", 18)
		tab_btn.focus_mode = Control.FOCUS_ALL
		
		var t_style = StyleBoxFlat.new()
		t_style.bg_color = Color(0.12, 0.12, 0.2, 0.8)
		t_style.corner_radius_top_left = 10
		t_style.corner_radius_top_right = 10
		t_style.corner_radius_bottom_right = 10
		t_style.corner_radius_bottom_left = 10
		t_style.content_margin_left = 12
		t_style.content_margin_right = 12
		t_style.content_margin_top = 4
		t_style.content_margin_bottom = 4
		tab_btn.add_theme_stylebox_override("normal", t_style)
		
		var active_style = t_style.duplicate()
		active_style.bg_color = Color(0.3, 0.4, 0.8, 0.9)
		active_style.border_width_bottom = 2
		active_style.border_color = Color(1.0, 0.85, 0.2)
		
		var tab_idx = i
		var tab_id = tab_info.id
		tab_btn.pressed.connect(func():
			SoundManager.play_sfx("ui_click")
			_switch_tab(tab_idx)
		)
		
		tab_buttons.append(tab_btn)
		tabs_hbox.add_child(tab_btn)
	
	outer_vbox.add_child(tabs_hbox)
	outer_vbox.add_child(scroll)
	
	# Gamepad / Keyboard navigation hints footer
	var hints_lbl = Label.new()
	hints_lbl.text = "🎮 [L-Stick / R-Stick / D-Pad] Scroll  •  [LB / RB] Category  •  [B / ESC] Close"
	hints_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hints_lbl.add_theme_font_override("font", GAME_FONT)
	hints_lbl.add_theme_font_size_override("font_size", 14)
	hints_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7, 0.7))
	outer_vbox.add_child(hints_lbl)
	
	# Close button
	close_btn = UIFactory.create_glass_button("close", UIFactory.RED_COLOR)
	close_btn.pressed.connect(func():
		SoundManager.play_sfx("ui_click")
		if on_close_callback.is_valid():
			on_close_callback.call()
		queue_free()
	)
	outer_vbox.add_child(close_btn)
	
	# Focus loop
	close_btn.focus_neighbor_left = close_btn.get_path()
	close_btn.focus_neighbor_right = close_btn.get_path()
	close_btn.focus_neighbor_top = close_btn.get_path()
	close_btn.focus_neighbor_bottom = close_btn.get_path()
	close_btn.focus_next = close_btn.get_path()
	close_btn.focus_previous = close_btn.get_path()
	
	panel.add_child(outer_vbox)
	_switch_tab(0)
	close_btn.grab_focus()

func _switch_tab(idx: int) -> void:
	current_tab_idx = idx
	selected_cat = categories[idx].id
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.12, 0.12, 0.2, 0.8)
	normal_style.corner_radius_top_left = 10
	normal_style.corner_radius_top_right = 10
	normal_style.corner_radius_bottom_right = 10
	normal_style.corner_radius_bottom_left = 10
	normal_style.content_margin_left = 12
	normal_style.content_margin_right = 12
	normal_style.content_margin_top = 4
	normal_style.content_margin_bottom = 4
	
	var active_style = normal_style.duplicate()
	active_style.bg_color = Color(0.3, 0.4, 0.8, 0.9)
	active_style.border_width_bottom = 2
	active_style.border_color = Color(1.0, 0.85, 0.2)
	
	for i in range(tab_buttons.size()):
		tab_buttons[i].remove_theme_stylebox_override("normal")
		if i == idx:
			tab_buttons[i].add_theme_stylebox_override("normal", active_style)
		else:
			tab_buttons[i].add_theme_stylebox_override("normal", normal_style)
			
	_populate_list(selected_cat)
	if is_instance_valid(scroll):
		scroll.scroll_vertical = 0

func _populate_list(cat: String) -> void:
	for child in grid.get_children():
		child.queue_free()
		
	var achievements = AchievementManager.get_all_achievements(cat)
	var current_cat_heading = ""
	
	for ach in achievements:
		# Category subheader if in "all" view
		if cat == "all" and ach.category != current_cat_heading:
			current_cat_heading = ach.category
			var cat_lbl = Label.new()
			cat_lbl.text = "— " + current_cat_heading.to_upper() + " —"
			cat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cat_lbl.add_theme_font_override("font", GAME_FONT)
			cat_lbl.add_theme_font_size_override("font_size", 20)
			cat_lbl.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9))
			grid.add_child(cat_lbl)
		
		# Achievement row
		var row_panel = PanelContainer.new()
		var row_style = StyleBoxFlat.new()
		row_style.corner_radius_top_left = 12
		row_style.corner_radius_top_right = 12
		row_style.corner_radius_bottom_right = 12
		row_style.corner_radius_bottom_left = 12
		row_style.content_margin_left = 16
		row_style.content_margin_right = 16
		row_style.content_margin_top = 8
		row_style.content_margin_bottom = 8
		
		if ach.unlocked:
			row_style.bg_color = Color(0.12, 0.24, 0.12, 0.75)
			row_style.border_width_left = 2
			row_style.border_width_top = 2
			row_style.border_width_right = 2
			row_style.border_width_bottom = 2
			row_style.border_color = Color(0.3, 0.85, 0.3, 0.8)
		else:
			row_style.bg_color = Color(0.08, 0.08, 0.12, 0.5)
			row_style.border_width_left = 1
			row_style.border_width_top = 1
			row_style.border_width_right = 1
			row_style.border_width_bottom = 1
			row_style.border_color = Color(0.3, 0.3, 0.4, 0.3)
		
		row_panel.add_theme_stylebox_override("panel", row_style)
		
		var row_hbox = HBoxContainer.new()
		row_hbox.add_theme_constant_override("separation", 14)
		
		# Icon
		var icon_rect = TextureRect.new()
		icon_rect.texture = load(ach.icon)
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(46, 46)
		if not ach.unlocked:
			icon_rect.modulate = Color(0.25, 0.25, 0.3, 0.8)
		row_hbox.add_child(icon_rect)
		
		# Info VBox
		var info_vbox = VBoxContainer.new()
		info_vbox.add_theme_constant_override("separation", 2)
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var name_lbl = Label.new()
		name_lbl.text = ach.name
		name_lbl.add_theme_font_override("font", GAME_FONT)
		name_lbl.add_theme_font_size_override("font_size", 22)
		if ach.unlocked:
			name_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
		else:
			name_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		info_vbox.add_child(name_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = ach.desc
		desc_lbl.add_theme_font_override("font", GAME_FONT)
		desc_lbl.add_theme_font_size_override("font_size", 16)
		desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
		info_vbox.add_child(desc_lbl)
		
		row_hbox.add_child(info_vbox)
		
		# Status VBox
		var progress = ach.progress
		var status_vbox = VBoxContainer.new()
		status_vbox.add_theme_constant_override("separation", 2)
		status_vbox.custom_minimum_size = Vector2(130, 0)
		
		if ach.unlocked:
			var done_lbl = Label.new()
			done_lbl.text = "✓ UNLOCKED"
			done_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			done_lbl.add_theme_font_override("font", GAME_FONT)
			done_lbl.add_theme_font_size_override("font_size", 18)
			done_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
			status_vbox.add_child(done_lbl)
		else:
			var prog_lbl = Label.new()
			prog_lbl.text = "%d / %d" % [progress.current, progress.target]
			prog_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			prog_lbl.add_theme_font_override("font", GAME_FONT)
			prog_lbl.add_theme_font_size_override("font_size", 18)
			prog_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			status_vbox.add_child(prog_lbl)
		
		var reward_lbl = Label.new()
		reward_lbl.text = "+%d rubies" % ach.reward
		reward_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		reward_lbl.add_theme_font_override("font", GAME_FONT)
		reward_lbl.add_theme_font_size_override("font_size", 15)
		if ach.unlocked:
			reward_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 0.3, 0.8))
		else:
			reward_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 0.7))
		status_vbox.add_child(reward_lbl)
		
		row_hbox.add_child(status_vbox)
		row_panel.add_child(row_hbox)
		grid.add_child(row_panel)

func _process(delta: float) -> void:
	if not is_instance_valid(scroll):
		return
		
	# Smooth analog joystick & D-Pad scrolling
	var joy_y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	var right_joy_y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	var scroll_speed = 750.0 # px/s
	var scroll_dir = 0.0
	
	if abs(joy_y) > 0.15:
		scroll_dir = joy_y
	elif abs(right_joy_y) > 0.15:
		scroll_dir = right_joy_y
	elif Input.is_key_pressed(KEY_UP) or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP):
		scroll_dir = -1.0
	elif Input.is_key_pressed(KEY_DOWN) or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN):
		scroll_dir = 1.0
	elif Input.is_key_pressed(KEY_PAGEUP):
		scroll_dir = -3.0
	elif Input.is_key_pressed(KEY_PAGEDOWN):
		scroll_dir = 3.0
		
	if scroll_dir != 0.0:
		scroll.scroll_vertical += int(scroll_dir * scroll_speed * delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			var prev_idx = (current_tab_idx - 1 + categories.size()) % categories.size()
			_switch_tab(prev_idx)
			get_viewport().set_input_as_handled()
		elif event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			var next_idx = (current_tab_idx + 1) % categories.size()
			_switch_tab(next_idx)
			get_viewport().set_input_as_handled()
		elif event.button_index == JOY_BUTTON_B:
			if is_instance_valid(close_btn):
				close_btn.pressed.emit()
				get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if is_instance_valid(close_btn):
				close_btn.pressed.emit()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_Q:
			var prev_idx = (current_tab_idx - 1 + categories.size()) % categories.size()
			_switch_tab(prev_idx)
		elif event.keycode == KEY_E:
			var next_idx = (current_tab_idx + 1) % categories.size()
			_switch_tab(next_idx)
