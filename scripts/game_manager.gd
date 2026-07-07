extends Node

var current_rubies: int = 0
var has_box: bool = true
var box_health: float = 100.0
var current_level: int = 1
var is_gameplay_started: bool = false

signal health_changed(new_health)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_ui_joypad()
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node):
	if node is BaseButton:
		node.pressed.connect(func():
			trigger_haptic(0.06, 0.1, 0.05)
		)
	elif node is Slider:
		node.value_changed.connect(func(_val):
			trigger_haptic(0.03, 0.05, 0.03)
		)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A):
		var focus = get_viewport().gui_get_focus_owner()
		if focus and focus is BaseButton:
			focus.pressed.emit()
			get_viewport().set_input_as_handled()

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

func game_over(reason: String) -> void:
	await get_tree().process_frame

	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		player.is_game_over = true
		player.hide()

	var ui_scene = ResourceManager.get_scene("res://scenes/game_over_ui.tscn")
	if ui_scene:
		var ui = ui_scene.instantiate()
		ui.game_over_reason = reason
		get_tree().root.add_child(ui)

func level_complete() -> void:
	await get_tree().process_frame
	var ui_scene = ResourceManager.get_scene("res://scenes/level_complete_ui.tscn")
	if ui_scene:
		var ui = ui_scene.instantiate()
		get_tree().root.add_child(ui)

var level_rubies: int = 0
var level_rubies_earned: int = 0

func add_ruby(points: int) -> void:
	current_rubies += points
	level_rubies_earned += points
	if points == 10:
		level_rubies += 1
	SaveSystem.global_rubies += points
	SaveSystem.save_data()

func reset_rubies() -> void:
	current_rubies = 0
	level_rubies = 0
	level_rubies_earned = 0
	has_box = true
	box_health = 100.0
	is_gameplay_started = false
	health_changed.emit(box_health)

func load_next_level() -> void:
	# current_rubies is kept for the session, but we also saved it globally
	level_rubies = 0
	level_rubies_earned = 0
	has_box = true
	box_health = 100.0
	
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
	# Local platforms
	for joy in Input.get_connected_joypads():
		Input.start_joy_vibration(joy, weak, strong, duration)
	Input.start_joy_vibration(0, weak, strong, duration)
	
	# Web platform fallback
	if OS.has_feature("web"):
		var duration_ms = int(duration * 1000)
		var js_code = "(function() { if (navigator.vibrate) { var dur = " + str(duration_ms) + "; var pattern = dur; if (dur === 50) { pattern = [15, 15, 15]; } else if (dur === 30) { pattern = [8]; } else if (dur === 80) { pattern = [20, 25, 20]; } else if (dur === 120) { pattern = [40, 30, 40]; } else if (dur === 150) { pattern = [80, 40, 60]; } else if (dur === 250) { pattern = [120, 60, 120]; } navigator.vibrate(pattern); } var gamepads = navigator.getGamepads(); for (var i = 0; i < gamepads.length; i++) { var gp = gamepads[i]; if (gp) { if (gp.vibrationActuator) { gp.vibrationActuator.playEffect('dual-rumble', { startDelay: 0, duration: " + str(duration_ms) + ", weakMagnitude: " + str(weak) + ", strongMagnitude: " + str(strong) + " }).catch(function(e){}); } } } })();"
		JavaScriptBridge.eval(js_code)
