extends Node

var sfx_library: Dictionary = {}
var pool_size: int = 16
var player_pool: Array[AudioStreamPlayer] = []
var pool_index: int = 0
var looping_players: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Create player pool
	for i in range(pool_size):
		var player = AudioStreamPlayer.new()
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		player_pool.append(player)
		
	# Pre-generate SFX
	_generate_sfx_library()

func play_sfx(name: String) -> void:
	if not SaveSystem.sfx_on or SaveSystem.sfx_volume <= 0.01:
		return
	# Disabled all click/button sounds as requested
	if name == "click" or not sfx_library.has(name):
		return
	
	# Use pool round-robin
	var player = player_pool[pool_index]
	player.stream = sfx_library[name]
	player.volume_db = linear_to_db(SaveSystem.sfx_volume)
	player.play()
	
	pool_index = (pool_index + 1) % pool_size

func start_sfx_loop(name: String) -> void:
	if not SaveSystem.sfx_on or SaveSystem.sfx_volume <= 0.01:
		return
	if not sfx_library.has(name):
		return
	if looping_players.has(name) and looping_players[name].playing:
		return
		
	var player = AudioStreamPlayer.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	# H4: Duplicate stream to avoid mutating the shared sfx_library resource
	player.stream = sfx_library[name].duplicate()
	if player.stream is AudioStreamWAV:
		player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		player.stream.loop_begin = 0
		player.stream.loop_end = player.stream.data.size() / 2
	add_child(player)
	player.volume_db = linear_to_db(SaveSystem.sfx_volume)
	player.play()
	looping_players[name] = player

func stop_sfx_loop(name: String) -> void:
	if looping_players.has(name):
		var player = looping_players[name]
		player.stop()
		player.queue_free()
		looping_players.erase(name)

func update_looping_sfx_volumes() -> void:
	var vol_db = linear_to_db(SaveSystem.sfx_volume)
	for name in looping_players.keys():
		var player = looping_players[name]
		if is_instance_valid(player):
			player.volume_db = vol_db

func _generate_sfx_library() -> void:
	sfx_library["jump"] = _generate_sweep(150.0, 800.0, 0.15, "sine")
	sfx_library["landing"] = _generate_landing_puff(0.18)
	sfx_library["ruby"] = _generate_arpeggio([659.25, 987.77], 0.25, "sine")
	sfx_library["tether"] = _generate_sweep(1200.0, 300.0, 0.35, "laser")
	sfx_library["explosion"] = _generate_noise(0.6)
	sfx_library["warning"] = _generate_sweep(250.0, 250.0, 0.2, "sine")
	sfx_library["thruster"] = _generate_thruster_loop(0.3)

func _generate_sweep(start_freq: float, end_freq: float, duration: float, type: String) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / num_samples
		# Exponential frequency sweep
		var freq = start_freq + (end_freq - start_freq) * t
		
		# Fade in/out envelope to prevent clicks
		var envelope = 1.0
		if t < 0.1:
			envelope = t / 0.1
		elif t > 0.8:
			envelope = 1.0 - (t - 0.8) / 0.2
			
		var val = 0.0
		if type == "sine":
			val = sin(phase)
		elif type == "square":
			val = 1.0 if sin(phase) >= 0.0 else -1.0
		elif type == "thud":
			val = sin(phase) + randf_range(-0.15, 0.15)
		elif type == "laser":
			# Sine wave frequency modulated (FM / warble)
			var lfo = sin(2.0 * PI * 15.0 * t) * 0.3 # 15Hz warble
			freq += freq * lfo
			val = sin(phase)
			
		var sample = int(val * 0.7 * envelope * 32767)
		data.encode_s16(i * 2, sample)
		
		phase += 2.0 * PI * freq / sample_rate
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

func _generate_landing_puff(duration: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	var last_val = 0.0
	for i in range(num_samples):
		var t = float(i) / num_samples
		
		# Exponential volume decay representing a puff of stabilizer gas
		var envelope = exp(-18.0 * t)
		var raw_val = randf_range(-1.0, 1.0) * envelope
		
		# Basic low-pass filter (averaging with previous sample) to soften the hiss
		var val = (raw_val + last_val) * 0.5
		last_val = raw_val
		
		# Prevent click at the end
		if t > 0.8:
			val *= (1.0 - t) / 0.2
			
		var sample = int(val * 0.45 * 32767)
		data.encode_s16(i * 2, sample)
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

func _generate_noise(duration: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	var noise_val = 0.0
	var last_noise_sample_t = 0
	
	for i in range(num_samples):
		var t = float(i) / num_samples
		
		# Swept noise frequency: drops from high frequency crunch to low rumble
		var noise_freq = max(60.0, 7000.0 * exp(-9.0 * t))
		var samples_between = sample_rate / noise_freq
		
		if i - last_noise_sample_t >= samples_between:
			noise_val = randf_range(-1.0, 1.0)
			last_noise_sample_t = i
			
		# Apply light distortion (clipping) for crunchy explosion impact
		var val = clamp(noise_val * 1.6, -1.0, 1.0)
		
		# Volume envelope: sharp decay
		var envelope = exp(-4.0 * t)
		val *= envelope
		
		# Prevent click at the end
		if t > 0.8:
			val *= (1.0 - t) / 0.2
			
		var sample = int(val * 0.9 * 32767)
		data.encode_s16(i * 2, sample)
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

func _generate_thruster_loop(duration: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	var last_val = 0.0
	for i in range(num_samples):
		var raw_val = randf_range(-1.0, 1.0)
		var val = (raw_val + last_val) * 0.5
		last_val = raw_val
		
		var sample = int(val * 0.38 * 32767)
		data.encode_s16(i * 2, sample)
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

func _generate_arpeggio(freqs: Array, duration: float, type: String) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	var num_notes = freqs.size()
	var samples_per_note = num_samples / num_notes
	
	var phase = 0.0
	for i in range(num_samples):
		var note_idx = i / samples_per_note
		if note_idx >= num_notes:
			note_idx = num_notes - 1
		var freq = freqs[note_idx]
		
		# Envelope per note to give it bounce
		var note_t = float(i % samples_per_note) / samples_per_note
		var envelope = 1.0
		if note_t < 0.1:
			envelope = note_t / 0.1
		elif note_t > 0.7:
			envelope = 1.0 - (note_t - 0.7) / 0.3
			
		var val = sin(phase)
		var sample = int(val * 0.6 * envelope * 32767)
		data.encode_s16(i * 2, sample)
		
		phase += 2.0 * PI * freq / sample_rate
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream
