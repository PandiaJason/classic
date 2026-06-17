extends AudioStreamPlayer

var _has_stream: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists("res://Petal_Path_Dash.mp3"):
		stream = load("res://Petal_Path_Dash.mp3")
		_has_stream = true
	else:
		_has_stream = false
	finished.connect(_on_finished)

func _on_finished():
	# Only loop if music is still enabled, volume > 0, and we have a valid stream
	if _has_stream and SaveSystem.music_on and SaveSystem.music_volume > 0.01:
		volume_db = linear_to_db(SaveSystem.music_volume)
		play()

func play_menu_music():
	if not _has_stream:
		return
	if SaveSystem.music_on and SaveSystem.music_volume > 0.01:
		volume_db = linear_to_db(SaveSystem.music_volume)
		if not playing:
			play()
	else:
		if playing:
			stop()

func stop_menu_music():
	if playing:
		stop()

func update_volume():
	if not _has_stream:
		return
	if SaveSystem.music_on and SaveSystem.music_volume > 0.01:
		volume_db = linear_to_db(SaveSystem.music_volume)
		if not playing:
			play()
	else:
		if playing:
			stop()
