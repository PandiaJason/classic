extends Area2D

# H10: Explicit signal connection (don't rely on editor wiring)
func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player2D:
		GameManager.has_box = true
		queue_free()
