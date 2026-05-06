extends Area2D

@export var speed: float = 300.0
@export var rotation_speed: float = 2.0
var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if direction != Vector2.ZERO:
		position += direction * speed * delta
		rotation += rotation_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body is Player2D:
		# Spawn explosion at player
		var explosion_scene = ResourceManager.get_scene("res://scenes/explosion.tscn")
		if not explosion_scene: return
		var explosion = explosion_scene.instantiate()
		explosion.global_position = body.global_position
		# Make it a bigger "BOOM" for player deaths
		explosion.scale = Vector2(1.5, 1.5)
		get_tree().root.call_deferred("add_child", explosion)
		
		# Hide and disable player
		body.hide()
		body.set_physics_process(false)
		
		if "is_game_over" in body:
			body.is_game_over = true
		
		GameManager.game_over("An asteroid destroyed your scooter!")
		queue_free()
		
	# Asteroid destroys itself and explodes if it hits a planet
	elif body.name.begins_with("Planet"):
		var explosion = load("res://scenes/explosion.tscn").instantiate()
		explosion.global_position = global_position
		get_tree().root.call_deferred("add_child", explosion)
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
