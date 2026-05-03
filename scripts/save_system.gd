extends Node

const SAVE_PATH = "user://save_data.cfg"
var config = ConfigFile.new()

# level_id -> stars (int)
var level_stars = {}
# highest unlocked level
var unlocked_levels = 1
# Global score system
var global_score = 0

func _ready():
	load_data()

func load_data():
	var err = config.load(SAVE_PATH)
	if err == OK:
		unlocked_levels = config.get_value("Progress", "unlocked_levels", 1)
		global_score = config.get_value("Progress", "global_score", 0)
		# Load stars for all 30 possible levels
		for i in range(1, 31):
			level_stars[i] = config.get_value("Stars", str(i), 0)
	else:
		# Initialize default
		unlocked_levels = 1
		global_score = 0
		for i in range(1, 31):
			level_stars[i] = 0
		save_data()

func save_data():
	config.set_value("Progress", "unlocked_levels", unlocked_levels)
	config.set_value("Progress", "global_score", global_score)
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

func is_level_unlocked(level_id: int) -> bool:
	return level_id <= unlocked_levels
