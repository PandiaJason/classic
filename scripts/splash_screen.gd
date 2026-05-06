extends Control

func _ready():
	# Show for 5 seconds then go to menu
	var timer = Timer.new()
	timer.wait_time = 5.0
	timer.one_shot = true
	timer.timeout.connect(_go_to_menu)
	add_child(timer)
	timer.start()

func _go_to_menu():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
