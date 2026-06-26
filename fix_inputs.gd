extends SceneTree

func _init():
	# Load current or default settings
	var accept = ProjectSettings.get_setting("input/ui_accept")
	if not accept:
		accept = {"deadzone": 0.5, "events": []}
	var a_btn = InputEventJoypadButton.new()
	a_btn.button_index = JOY_BUTTON_A
	var has_a = false
	for ev in accept["events"]:
		if ev is InputEventJoypadButton and ev.button_index == JOY_BUTTON_A:
			has_a = true
	if not has_a:
		accept["events"].append(a_btn)
		ProjectSettings.set_setting("input/ui_accept", accept)

	var cancel = ProjectSettings.get_setting("input/ui_cancel")
	if not cancel:
		cancel = {"deadzone": 0.5, "events": []}
	var b_btn = InputEventJoypadButton.new()
	b_btn.button_index = JOY_BUTTON_B
	var has_b = false
	for ev in cancel["events"]:
		if ev is InputEventJoypadButton and ev.button_index == JOY_BUTTON_B:
			has_b = true
	if not has_b:
		cancel["events"].append(b_btn)
		ProjectSettings.set_setting("input/ui_cancel", cancel)

	ProjectSettings.save()
	print("Inputs fixed.")
	quit()
