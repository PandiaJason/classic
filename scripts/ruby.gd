extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# Add a floating animation
	var tween = create_tween().set_loops()
	tween.tween_property($Sprite2D, "position:y", -10.0, 1.0).as_relative().set_trans(Tween.TRANS_SINE)
	tween.tween_property($Sprite2D, "position:y", 10.0, 1.0).as_relative().set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player2D":
		GameManager.add_score(10)
		
		# Optional: Add collection sound or effect here
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
		tween.tween_callback(queue_free)
