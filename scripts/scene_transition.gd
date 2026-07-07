extends CanvasLayer

var color_rect: ColorRect
var is_transitioning: bool = false

func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	color_rect = ColorRect.new()
	color_rect.color = Color(0.02, 0.02, 0.08, 0.0) # Very dark space navy
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(color_rect)

func transition_to(scene_path: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect, "color:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	# M1: Check return value to prevent permanent black screen on invalid path
	var err = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("SceneTransition: Failed to load scene '%s' (error %d)" % [scene_path, err])
		# Fade back out and reset so the game isn't stuck
		var recover_tween = create_tween()
		recover_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		recover_tween.tween_property(color_rect, "color:a", 0.0, 0.3)
		await recover_tween.finished
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		is_transitioning = false
		return
	
	# Wait two frames to allow the tree to restructure and new scene to load
	await get_tree().process_frame
	await get_tree().process_frame
	
	var tween_in = create_tween()
	tween_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_in.tween_property(color_rect, "color:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween_in.finished
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false

func reload_current() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect, "color:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	var err = get_tree().reload_current_scene()
	if err != OK:
		push_error("SceneTransition: Failed to reload current scene (error %d)" % err)
		var recover_tween = create_tween()
		recover_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		recover_tween.tween_property(color_rect, "color:a", 0.0, 0.3)
		await recover_tween.finished
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		is_transitioning = false
		return
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var tween_in = create_tween()
	tween_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_in.tween_property(color_rect, "color:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween_in.finished
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false
