extends CanvasLayer

# Full-screen Modal CanvasLayer for Achievements
# Guarantees 100% input isolation, touch & drag scrolling, joystick scrolling, and clean UI

const GAME_FONT = preload("res://assets/game_font.ttf")

var scroll: ScrollContainer
var grid: VBoxContainer
var close_btn: Button
var tab_buttons: Array = []
var categories = [
	{"id": "all", "label": "all (75)"},
	{"id": "endless", "label": "endless"},
	{"id": "campaign", "label": "campaign"},
	{"id": "stars", "label": "stars"},
	{"id": "rubies", "label": "rubies"},
	{"id": "skills", "label": "skills"},
	{"id": "survival", "label": "survival"}
]
var selected_cat: String = "all"
var current_tab_idx: int = 0
var on_close_callback: Callable
var _scroll_pos_float: float = 0.0

# Touch & drag scrolling state
var _is_touch_dragging: bool = false
var _touch_velocity_y: float = 0.0
var _last_touch_time: float = 0.0

func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	set_process(true)
	set_process_unhandled_input(true)

func _build_ui() -> void:
	# Full-screen blocking background
	var bg_overlay = ColorRect.new()
	bg_overlay.name = "AchievementsBackdrop"
	bg_overlay.color = Color(0, 0, 0, 0.88)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	# Clicking or touching the backdrop outside the panel closes the modal
	bg_overlay.gui_input.connect(func(event: InputEvent):
		if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
			_close_modal()
	)
	add_child(bg_overlay)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	
	var panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.09, 0.96)
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
	outer_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Header: Title & Overall Progress (No Emojis)
	var header_vbox = VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 4)
	header_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var unlocked_num = AchievementManager.get_unlocked_count()
	var total_num = AchievementManager.get_total_count()
	var pct = (float(unlocked_num) / float(total_num)) * 100.0 if total_num > 0 else 0.0
	
	var title = Label.new()
	title.text = "achievements (%d / %d  •  %.0f%%)" % [unlocked_num, total_num, pct]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", GAME_FONT)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_vbox.add_child(title)
	
	# Overall Progress Bar
	var pbar = ProgressBar.new()
	pbar.custom_minimum_size = Vector2(500, 10)
	pbar.min_value = 0
	pbar.max_value = total_num
	pbar.value = unlocked_num
	pbar.show_percentage = false
	pbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	tabs_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Scrollable container for achievements
	scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(760, 400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	scroll.follow_focus = false
	scroll.gui_input.connect(_on_scroll_gui_input)
	
	grid = VBoxContainer.new()
	grid.add_theme_constant_override("separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(grid)
	
	for i in range(categories.size()):
		var tab_info = categories[i]
		var tab_btn = Button.new()
		tab_btn.text = tab_info.label
		tab_btn.add_theme_font_override("font", GAME_FONT)
		tab_btn.add_theme_font_size_override("font_size", 18)
		tab_btn.custom_minimum_size = Vector2(0, 36)
		tab_btn.focus_mode = Control.FOCUS_ALL
		tab_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		
		var t_style = StyleBoxFlat.new()
		t_style.bg_color = Color(0.12, 0.12, 0.2, 0.8)
		t_style.corner_radius_top_left = 10
		t_style.corner_radius_top_right = 10
		t_style.corner_radius_bottom_right = 10
		t_style.corner_radius_bottom_left = 10
		t_style.content_margin_left = 12
		t_style.content_margin_right = 12
		t_style.content_margin_top = 6
		t_style.content_margin_bottom = 6
		tab_btn.add_theme_stylebox_override("normal", t_style)
		
		var active_style = t_style.duplicate()
		active_style.bg_color = Color(0.3, 0.4, 0.8, 0.9)
		active_style.border_width_bottom = 2
		active_style.border_color = Color(1.0, 0.85, 0.2)
		
		var tab_idx = i
		tab_btn.pressed.connect(func():
			SoundManager.play_sfx("ui_click")
			_switch_tab(tab_idx)
		)
		
		tab_buttons.append(tab_btn)
		tabs_hbox.add_child(tab_btn)
	
	outer_vbox.add_child(tabs_hbox)
	outer_vbox.add_child(scroll)
	
	# Gamepad / Keyboard navigation hints footer (No Emojis)
	var hints_lbl = Label.new()
	hints_lbl.text = "[L-Stick / R-Stick / D-Pad] Scroll  •  [LB / RB] Category  •  [B / ESC] Close"
	hints_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hints_lbl.add_theme_font_override("font", GAME_FONT)
	hints_lbl.add_theme_font_size_override("font_size", 14)
	hints_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7, 0.7))
	hints_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer_vbox.add_child(hints_lbl)
	
	# Close button
	close_btn = UIFactory.create_glass_button("close", UIFactory.RED_COLOR)
	close_btn.custom_minimum_size = Vector2(160, 44)
	close_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	close_btn.pressed.connect(func():
		_close_modal()
	)
	outer_vbox.add_child(close_btn)
	
	panel.add_child(outer_vbox)
	_switch_tab(0)
	call_deferred("_setup_focus_navigation")

func _setup_focus_navigation() -> void:
	for i in range(tab_buttons.size()):
		var btn = tab_buttons[i]
		if is_instance_valid(btn):
			var prev_btn = tab_buttons[(i - 1 + tab_buttons.size()) % tab_buttons.size()]
			var next_btn = tab_buttons[(i + 1) % tab_buttons.size()]
			btn.focus_neighbor_left = prev_btn.get_path()
			btn.focus_neighbor_right = next_btn.get_path()
			btn.focus_neighbor_bottom = close_btn.get_path()
	
	if is_instance_valid(close_btn) and close_btn.is_inside_tree():
		if tab_buttons.size() > 0:
			close_btn.focus_neighbor_top = tab_buttons[current_tab_idx].get_path()
		close_btn.grab_focus()

func _close_modal() -> void:
	SoundManager.play_sfx("ui_click")
	if on_close_callback.is_valid():
		on_close_callback.call()
	queue_free()

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
	normal_style.content_margin_top = 6
	normal_style.content_margin_bottom = 6
	
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
	_scroll_pos_float = 0.0
	_touch_velocity_y = 0.0
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
			cat_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			grid.add_child(cat_lbl)
		
		# Achievement row
		var row_panel = PanelContainer.new()
		row_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		row_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Icon
		var icon_rect = TextureRect.new()
		icon_rect.texture = load(ach.icon)
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(46, 46)
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not ach.unlocked:
			icon_rect.modulate = Color(0.25, 0.25, 0.3, 0.8)
		row_hbox.add_child(icon_rect)
		
		# Info VBox
		var info_vbox = VBoxContainer.new()
		info_vbox.add_theme_constant_override("separation", 2)
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var name_lbl = Label.new()
		name_lbl.text = ach.name
		name_lbl.add_theme_font_override("font", GAME_FONT)
		name_lbl.add_theme_font_size_override("font_size", 22)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_vbox.add_child(desc_lbl)
		
		row_hbox.add_child(info_vbox)
		
		# Status VBox
		var progress = ach.progress
		var status_vbox = VBoxContainer.new()
		status_vbox.add_theme_constant_override("separation", 2)
		status_vbox.custom_minimum_size = Vector2(130, 0)
		status_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		if ach.unlocked:
			var done_lbl = Label.new()
			done_lbl.text = "UNLOCKED"
			done_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			done_lbl.add_theme_font_override("font", GAME_FONT)
			done_lbl.add_theme_font_size_override("font_size", 18)
			done_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
			done_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			status_vbox.add_child(done_lbl)
		else:
			var prog_lbl = Label.new()
			prog_lbl.text = "%d / %d" % [progress.current, progress.target]
			prog_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			prog_lbl.add_theme_font_override("font", GAME_FONT)
			prog_lbl.add_theme_font_size_override("font_size", 18)
			prog_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			prog_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			status_vbox.add_child(prog_lbl)
		
		var reward_lbl = Label.new()
		reward_lbl.text = "+%d rubies" % ach.reward
		reward_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		reward_lbl.add_theme_font_override("font", GAME_FONT)
		reward_lbl.add_theme_font_size_override("font_size", 15)
		reward_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ach.unlocked:
			reward_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 0.3, 0.8))
		else:
			reward_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 0.7))
		status_vbox.add_child(reward_lbl)
		
		row_hbox.add_child(status_vbox)
		row_panel.add_child(row_hbox)
		grid.add_child(row_panel)

func _on_scroll_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_is_touch_dragging = true
			_touch_velocity_y = 0.0
			_last_touch_time = Time.get_ticks_msec() / 1000.0
		else:
			_is_touch_dragging = false
	elif event is InputEventScreenDrag:
		if _is_touch_dragging:
			var dy = event.relative.y
			_scroll_pos_float -= dy
			var max_s = max(0, scroll.get_v_scroll_bar().max_value - scroll.size.y)
			_scroll_pos_float = clamp(_scroll_pos_float, 0.0, float(max_s))
			scroll.scroll_vertical = int(_scroll_pos_float)
			
			var now = Time.get_ticks_msec() / 1000.0
			var dt = now - _last_touch_time
			if dt > 0.001:
				_touch_velocity_y = -dy / dt
			_last_touch_time = now
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_touch_dragging = true
				_touch_velocity_y = 0.0
				_last_touch_time = Time.get_ticks_msec() / 1000.0
			else:
				_is_touch_dragging = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll_pos_float -= 80.0
			var max_s = max(0, scroll.get_v_scroll_bar().max_value - scroll.size.y)
			_scroll_pos_float = clamp(_scroll_pos_float, 0.0, float(max_s))
			scroll.scroll_vertical = int(_scroll_pos_float)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll_pos_float += 80.0
			var max_s = max(0, scroll.get_v_scroll_bar().max_value - scroll.size.y)
			_scroll_pos_float = clamp(_scroll_pos_float, 0.0, float(max_s))
			scroll.scroll_vertical = int(_scroll_pos_float)
	elif event is InputEventMouseMotion:
		if _is_touch_dragging:
			var dy = event.relative.y
			_scroll_pos_float -= dy
			var max_s = max(0, scroll.get_v_scroll_bar().max_value - scroll.size.y)
			_scroll_pos_float = clamp(_scroll_pos_float, 0.0, float(max_s))
			scroll.scroll_vertical = int(_scroll_pos_float)
			
			var now = Time.get_ticks_msec() / 1000.0
			var dt = now - _last_touch_time
			if dt > 0.001:
				_touch_velocity_y = -dy / dt
			_last_touch_time = now

func _process(delta: float) -> void:
	if not is_instance_valid(scroll):
		return
		
	# Check joystick / gamepad devices
	var scroll_dir = 0.0
	for joy_id in Input.get_connected_joypads() + [0]:
		var ly = Input.get_joy_axis(joy_id, JOY_AXIS_LEFT_Y)
		var ry = Input.get_joy_axis(joy_id, JOY_AXIS_RIGHT_Y)
		if abs(ly) > 0.12:
			scroll_dir = ly
			break
		elif abs(ry) > 0.12:
			scroll_dir = ry
			break
		elif Input.is_joy_button_pressed(joy_id, JOY_BUTTON_DPAD_UP):
			scroll_dir = -1.0
			break
		elif Input.is_joy_button_pressed(joy_id, JOY_BUTTON_DPAD_DOWN):
			scroll_dir = 1.0
			break
			
	if scroll_dir == 0.0:
		if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
			scroll_dir = -1.0
		elif Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
			scroll_dir = 1.0
		elif Input.is_key_pressed(KEY_PAGEUP):
			scroll_dir = -3.0
		elif Input.is_key_pressed(KEY_PAGEDOWN):
			scroll_dir = 3.0
			
	if scroll_dir != 0.0:
		var scroll_speed = 850.0 # px/s
		_scroll_pos_float += scroll_dir * scroll_speed * delta
		var max_s = max(0, scroll.get_v_scroll_bar().max_value - scroll.size.y)
		_scroll_pos_float = clamp(_scroll_pos_float, 0.0, float(max_s))
		scroll.scroll_vertical = int(_scroll_pos_float)
		_touch_velocity_y = 0.0
	elif not _is_touch_dragging and abs(_touch_velocity_y) > 15.0:
		# Kinetic momentum decay
		_scroll_pos_float += _touch_velocity_y * delta
		_touch_velocity_y = lerp(_touch_velocity_y, 0.0, 8.0 * delta)
		var max_s = max(0, scroll.get_v_scroll_bar().max_value - scroll.size.y)
		_scroll_pos_float = clamp(_scroll_pos_float, 0.0, float(max_s))
		scroll.scroll_vertical = int(_scroll_pos_float)
	elif not _is_touch_dragging:
		_scroll_pos_float = float(scroll.scroll_vertical)

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
			_close_modal()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_close_modal()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_Q:
			var prev_idx = (current_tab_idx - 1 + categories.size()) % categories.size()
			_switch_tab(prev_idx)
		elif event.keycode == KEY_E:
			var next_idx = (current_tab_idx + 1) % categories.size()
			_switch_tab(next_idx)
