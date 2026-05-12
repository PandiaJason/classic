extends AudioStreamPlayer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	stream = load("res://Petal_Path_Dash.mp3")
	finished.connect(play)

func play_menu_music():
	if not playing:
		play()

func stop_menu_music():
	if playing:
		stop()
