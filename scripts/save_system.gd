extends Node

const SAVE_PATH = "user://save_data.cfg"
var config = ConfigFile.new()

# level_id -> stars (int)
var level_stars = {}
# highest unlocked level
var unlocked_levels = 1
# Global score system
var global_score = 0
# Music preference
var music_on = true
# SFX preference
var sfx_on = true
# Glide assist consumable count
var glide_count: int = 0
# Tutorial completion state
var tutorial_complete: bool = false

func _ready():
	load_data()

func load_data():
	var err = config.load(SAVE_PATH)
	if err == OK:
		unlocked_levels = config.get_value("Progress", "unlocked_levels", 1)
		global_score = config.get_value("Progress", "global_score", 0)
		music_on = config.get_value("Progress", "music_on", true)
		sfx_on = config.get_value("Progress", "sfx_on", true)
		glide_count = config.get_value("Progress", "glide_count", 0)
		tutorial_complete = config.get_value("Progress", "tutorial_complete", false)
		# Load stars for all 30 possible levels
		for i in range(1, 91):
			level_stars[i] = config.get_value("Stars", str(i), 0)
	else:
		# Initialize default
		unlocked_levels = 1
		global_score = 0
		music_on = true
		sfx_on = true
		glide_count = 0
		tutorial_complete = false
		for i in range(1, 91):
			level_stars[i] = 0
		save_data()

func save_data():
	config.set_value("Progress", "unlocked_levels", unlocked_levels)
	config.set_value("Progress", "global_score", global_score)
	config.set_value("Progress", "music_on", music_on)
	config.set_value("Progress", "sfx_on", sfx_on)
	config.set_value("Progress", "glide_count", glide_count)
	config.set_value("Progress", "tutorial_complete", tutorial_complete)
	for i in level_stars.keys():
		config.set_value("Stars", str(i), level_stars[i])
	config.save(SAVE_PATH)

func complete_level(level_id: int, stars: int):
	# Update max stars
	if level_stars.has(level_id):
		if stars > level_stars[level_id]:
			level_stars[level_id] = stars
	else:
		level_stars[level_id] = stars
		
	# Unlock next level
	if level_id >= unlocked_levels:
		unlocked_levels = level_id + 1
		
	save_data()

func get_stars(level_id: int) -> int:
	if level_stars.has(level_id):
		return level_stars[level_id]
	return 0

func get_total_stars() -> int:
	var total = 0
	for i in range(1, 91):
		total += get_stars(i)
	return total

func is_level_unlocked(level_id: int) -> bool:
	if level_id <= 1:
		return true
	if level_id > unlocked_levels:
		return false
		
	# Enforce star gates
	var total_stars = get_total_stars()
	if level_id >= 81:
		return total_stars >= 200
	elif level_id >= 71:
		return total_stars >= 165
	elif level_id >= 61:
		return total_stars >= 135
	elif level_id >= 51:
		return total_stars >= 110
	elif level_id >= 41:
		return total_stars >= 90
	elif level_id >= 31:
		return total_stars >= 75
	elif level_id >= 26:
		return total_stars >= 60
	elif level_id >= 21:
		return total_stars >= 45
	elif level_id >= 16:
		return total_stars >= 30
	elif level_id >= 11:
		return total_stars >= 15
	elif level_id >= 6:
		return total_stars >= 5
	return true

func purchase_glide() -> bool:
	if global_score >= 30:
		global_score -= 30
		glide_count += 1
		save_data()
		return true
	return false

func use_glide() -> bool:
	if glide_count > 0:
		glide_count -= 1
		save_data()
		return true
	return false
