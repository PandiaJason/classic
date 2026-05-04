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
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", target_scale, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.2)
	tween.chain().tween_callback(queue_free)
