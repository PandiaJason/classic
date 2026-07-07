extends Sprite2D

var target_scale: Vector2 = Vector2(0.8, 0.8)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	material = CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	
	# If scale was set before ready, use it as a base for target_scale
	if scale != Vector2.ONE:
		target_scale = scale
	
	# Start tiny, expand quickly, and fade out
	# C3: Fixed tween timing — queue_free now waits for the longest animation (0.7s total)
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", target_scale, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.2)
	tween.tween_callback(queue_free).set_delay(0.7)
