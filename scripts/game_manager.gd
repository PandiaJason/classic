extends Node

var current_rubies: int = 0
var has_box: bool = true
var box_health: float = 100.0
var current_level: int = 1
var is_gameplay_started: bool = false
var _game_ended: bool = false
var _save_dirty: bool = false
var _last_button_press_time: Dictionary = {}

var is_endless_mode: bool = false
var endless_score: int = 0
var endless_deliveries: int = 0

signal health_changed(new_health)
signal endless_score_changed(new_score, deliveries)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.max_fps = 60
	_setup_ui_joypad()
	get_tree().node_added.connect(_on_node_added)

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_A or event.button_index == JOY_BUTTON_B:
			var focus = get_viewport().gui_get_focus_owner()
			if focus and focus is BaseButton:
				var now = Time.get_ticks_msec()
				var btn_id = focus.get_instance_id()
				if not _last_button_press_time.has(btn_id) or now - _last_button_press_time[btn_id] > 150:
					_last_button_press_time[btn_id] = now
					if event.button_index == JOY_BUTTON_A:
						focus.pressed.emit()
					elif event.button_index == JOY_BUTTON_B:
						# B button triggers back if the button matches cancel actions
						if focus.name.to_lower().contains("back") or focus.name.to_lower().contains("close") or focus.name.to_lower().contains("cancel") or focus.name.to_lower().contains("menu"):
							focus.pressed.emit()
					get_viewport().set_input_as_handled()
	# Pre-register JS haptic function once for web (H3: avoid rebuilding ~600-char string per call)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""
			window._ranotot_haptic = function(w, s, dm, gm) {
				if (navigator.vibrate) {
					var pattern = dm;
					if (dm === 50) { pattern = [15, 15, 15]; }
					else if (dm === 30) { pattern = [8]; }
					else if (dm === 80) { pattern = [20, 25, 20]; }
					else if (dm === 120) { pattern = [40, 30, 40]; }
					else if (dm === 150) { pattern = [80, 40, 60]; }
					else if (dm === 250) { pattern = [120, 60, 120]; }
					navigator.vibrate(pattern);
				}
				var gamepads = navigator.getGamepads();
				for (var i = 0; i < gamepads.length; i++) {
					var gp = gamepads[i];
					if (gp && gp.vibrationActuator) {
						if (gp.vibrationActuator.playEffect) {
							gp.vibrationActuator.playEffect('dual-rumble', {
								startDelay: 0, duration: gm,
								weakMagnitude: w, strongMagnitude: s
							}).catch(function(e){});
						} else if (gp.vibrationActuator.pulse) {
							gp.vibrationActuator.pulse(s, gm);
						}
					}
				}
			};
		""")

# C2: Named method to avoid lambda signal leak — can check is_connected
func _haptic_button_press() -> void:
	trigger_haptic(0.06, 0.1, 0.05)

func _haptic_slider_tick(_val) -> void:
	trigger_haptic(0.03, 0.05, 0.03)

func _on_node_added(node: Node):
	if node is BaseButton:
		if not node.pressed.is_connected(_haptic_button_press):
			node.pressed.connect(_haptic_button_press)
	elif node is Slider:
		if not node.value_changed.is_connected(_haptic_slider_tick):
			node.value_changed.connect(_haptic_slider_tick)

# C1: Removed manual ui_accept → pressed.emit() — Godot handles this natively.
# The _input override for double-fire has been deleted entirely.

func _setup_ui_joypad():
	var mapping = {
		"ui_left": {"axis": JOY_AXIS_LEFT_X, "dir": -1.0},
		"ui_right": {"axis": JOY_AXIS_LEFT_X, "dir": 1.0},
		"ui_up": {"axis": JOY_AXIS_LEFT_Y, "dir": -1.0},
		"ui_down": {"axis": JOY_AXIS_LEFT_Y, "dir": 1.0}
	}
	for action in mapping:
		if not InputMap.has_action(action): continue
		var has_stick = false
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadMotion and ev.axis == mapping[action].axis and sign(ev.axis_value) == sign(mapping[action].dir):
				has_stick = true
				break
		if not has_stick:
			var ev = InputEventJoypadMotion.new()
			ev.axis = mapping[action].axis
			ev.axis_value = mapping[action].dir
			InputMap.action_add_event(action, ev)
			InputMap.action_set_deadzone(action, 0.5)

	# Ensure A and B buttons are mapped to Accept/Cancel
	_ensure_joy_button("ui_accept", JOY_BUTTON_A)
	_ensure_joy_button("ui_cancel", JOY_BUTTON_B)

	# Ensure jump and speed actions exist and are mapped correctly
	if not InputMap.has_action("jump"):
		InputMap.add_action("jump")
	_ensure_joy_button("jump", JOY_BUTTON_A)
	_ensure_key("jump", KEY_SPACE)
	_ensure_key("jump", KEY_UP)

	if not InputMap.has_action("speed"):
		InputMap.add_action("speed")
	_ensure_joy_button("speed", JOY_BUTTON_X)
	_ensure_key("speed", KEY_SHIFT)

func _ensure_joy_button(action: String, btn_index: JoyButton):
	if not InputMap.has_action(action): return
	var has_btn = false
	for ev in InputMap.action_get_events(action):
		if ev is InputEventJoypadButton and ev.button_index == btn_index:
			has_btn = true
			break
	if not has_btn:
		var ev = InputEventJoypadButton.new()
		ev.button_index = btn_index
		InputMap.action_add_event(action, ev)

func _ensure_key(action: String, keycode: Key):
	if not InputMap.has_action(action): return
	var has_key = false
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and ev.keycode == keycode:
			has_key = true
			break
	if not has_key:
		var ev = InputEventKey.new()
		ev.keycode = keycode
		InputMap.action_add_event(action, ev)

func take_jump_damage() -> void:
	if has_box:
		trigger_haptic(0.15, 0.25, 0.15)
		AchievementManager.on_jump()
		box_health -= 3.0
		box_health = max(0.0, box_health)
		health_changed.emit(box_health)
		if box_health <= 0.0:
			game_over("rough riding destroyed your delivery box!")

func repair_box(amount: float) -> void:
	if has_box:
		box_health = min(100.0, box_health + amount)
		health_changed.emit(box_health)

func take_damage(amount: float, reason: String) -> void:
	if has_box:
		trigger_haptic(0.25, 0.4, 0.25)
		box_health -= amount
		box_health = max(0.0, box_health)
		health_changed.emit(box_health)
		if box_health <= 0.0:
			game_over(reason)

# H7: Guard against double game-over/level-complete UI from multi-hit in same frame
func game_over(reason: String) -> void:
	if _game_ended:
		return
	_game_ended = true
	_flush_save()
	# Track "lost in space" achievement
	if reason.contains("lost in space"):
		AchievementManager.on_lost_in_space()
	await get_tree().process_frame

	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		player.is_game_over = true
		player.hide()

	var in_game_ui = get_tree().get_first_node_in_group("in_game_ui")
	if is_instance_valid(in_game_ui):
		in_game_ui.hide()

	var ui_scene = ResourceManager.get_scene("res://scenes/game_over_ui.tscn")
	if ui_scene:
		var ui = ui_scene.instantiate()
		ui.game_over_reason = reason
		get_tree().root.add_child(ui)

func level_complete() -> void:
	if _game_ended:
		return
	_game_ended = true
	_flush_save()
	await get_tree().process_frame
	
	var in_game_ui = get_tree().get_first_node_in_group("in_game_ui")
	if is_instance_valid(in_game_ui):
		in_game_ui.hide()
		
	var ui_scene = ResourceManager.get_scene("res://scenes/level_complete_ui.tscn")
	if ui_scene:
		var ui = ui_scene.instantiate()
		get_tree().root.add_child(ui)

var level_rubies: int = 0
var level_rubies_earned: int = 0

# H2: Mark dirty instead of saving to disk on every ruby pickup
func add_ruby(points: int) -> void:
	current_rubies += points
	level_rubies_earned += points
	if points == 10:
		level_rubies += 1
	SaveSystem.global_rubies += points
	_save_dirty = true
	AchievementManager.on_ruby_collected(points)

# Flush pending save to disk (called at level end / game over)
func _flush_save() -> void:
	if _save_dirty:
		SaveSystem.save_data()
		_save_dirty = false

func reset_rubies() -> void:
	current_rubies = 0
	level_rubies = 0
	level_rubies_earned = 0
	has_box = true
	box_health = 100.0
	is_gameplay_started = false
	_game_ended = false
	health_changed.emit(box_health)

func load_next_level() -> void:
	# current_rubies is kept for the session, but we also saved it globally
	level_rubies = 0
	level_rubies_earned = 0
	has_box = true
	box_health = 100.0
	_game_ended = false
	
	var next_level = current_level + 1
	if next_level > 90:
		is_gameplay_started = false
		health_changed.emit(box_health)
		SceneTransition.transition_to("res://scenes/credits.tscn")
	elif not SaveSystem.is_level_unlocked(next_level):
		is_gameplay_started = false
		health_changed.emit(box_health)
		SceneTransition.transition_to("res://scenes/level_select.tscn")
	else:
		current_level = next_level
		is_gameplay_started = false
		health_changed.emit(box_health)
		SceneTransition.transition_to("res://scenes/level_" + str(current_level) + ".tscn")

func trigger_haptic(weak: float, strong: float, duration: float) -> void:
	# Scale magnitudes above physical motor activation threshold
	var adj_weak = (0.22 + weak * 0.78) if weak > 0.01 else 0.0
	var adj_strong = (0.25 + strong * 0.75) if strong > 0.01 else 0.0
	# Gamepad motors need ~200ms minimum spin-up time to be felt
	var gp_duration = maxf(duration, 0.2)
	
	# Local platforms (native gamepad rumble) — H12: loop covers all connected pads including 0
	for joy in Input.get_connected_joypads():
		Input.start_joy_vibration(joy, adj_weak, adj_strong, gp_duration)
	
	# Web platform: call pre-registered JS function (H3)
	if OS.has_feature("web"):
		var duration_ms = int(duration * 1000)
		var gp_duration_ms = int(gp_duration * 1000)
		JavaScriptBridge.eval("window._ranotot_haptic(%s,%s,%s,%s)" % [adj_weak, adj_strong, duration_ms, gp_duration_ms])

func start_endless_mode():
	get_tree().paused = false
	is_endless_mode = true
	endless_score = 0
	endless_deliveries = 0
	current_rubies = 0
	level_rubies_earned = 0
	has_box = true
	box_health = 100.0
	_game_ended = false
	is_gameplay_started = true
	SceneTransition.transition_to("res://scenes/level_endless.tscn")

func add_endless_score(pts: int):
	endless_score += pts
	endless_score_changed.emit(endless_score, endless_deliveries)
