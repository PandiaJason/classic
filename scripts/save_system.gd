extends Node

const SAVE_PATH = "user://save_data.cfg"
var config = ConfigFile.new()

# level_id -> stars (int)
var level_stars = {}
# highest unlocked level
var unlocked_levels = 1
# Global ruby system
var global_rubies = 0
# Music preference
var music_on = true
var music_volume: float = 0.8
# SFX preference
var sfx_on = true
var sfx_volume: float = 0.8
# Glide assist consumable count
var glide_count: int = 0
# Speed boost consumable count
var speed_count: int = 0
# Tutorial completion state
var tutorial_complete: bool = false
# Daily streak system
var streak_count: int = 0
var last_claim_day: int = -1

func _ready():
	load_data()

func load_data():
	var err = config.load(SAVE_PATH)
	if err == OK:
		unlocked_levels = config.get_value("Progress", "unlocked_levels", 1)
		global_rubies = config.get_value("Progress", "global_rubies", config.get_value("Progress", "global_score", 0))
		music_on = config.get_value("Progress", "music_on", true)
		music_volume = config.get_value("Progress", "music_volume", 0.8)
		sfx_on = config.get_value("Progress", "sfx_on", true)
		sfx_volume = config.get_value("Progress", "sfx_volume", 0.8)
		glide_count = config.get_value("Progress", "glide_count", 0)
		speed_count = config.get_value("Progress", "speed_count", 0)
		tutorial_complete = config.get_value("Progress", "tutorial_complete", false)
		streak_count = config.get_value("Progress", "streak_count", 0)
		last_claim_day = config.get_value("Progress", "last_claim_day", -1)
		# Load stars for all 30 possible levels
		for i in range(1, 91):
			level_stars[i] = config.get_value("Stars", str(i), 0)
	else:
		# Initialize default
		unlocked_levels = 1
		global_rubies = 0
		music_on = true
		music_volume = 0.8
		sfx_on = true
		sfx_volume = 0.8
		glide_count = 0
		speed_count = 0
		tutorial_complete = false
		streak_count = 0
		last_claim_day = -1
		for i in range(1, 91):
			level_stars[i] = 0
		save_data()

func save_data():
	config.set_value("Progress", "unlocked_levels", unlocked_levels)
	config.set_value("Progress", "global_rubies", global_rubies)
	config.set_value("Progress", "global_score", global_rubies)
	config.set_value("Progress", "music_on", music_on)
	config.set_value("Progress", "music_volume", music_volume)
	config.set_value("Progress", "sfx_on", sfx_on)
	config.set_value("Progress", "sfx_volume", sfx_volume)
	config.set_value("Progress", "glide_count", glide_count)
	config.set_value("Progress", "speed_count", speed_count)
	config.set_value("Progress", "tutorial_complete", tutorial_complete)
	config.set_value("Progress", "streak_count", streak_count)
	config.set_value("Progress", "last_claim_day", last_claim_day)
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
	if global_rubies >= 10:
		global_rubies -= 10
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

func purchase_speed() -> bool:
	if global_rubies >= 10:
		global_rubies -= 10
		speed_count += 1
		save_data()
		return true
	return false

func use_speed() -> bool:
	if speed_count > 0:
		speed_count -= 1
		save_data()
		return true
	return false

func get_local_day_number() -> int:
	var bias_seconds = Time.get_time_zone_from_system().get("bias", 0) * 60
	return int((Time.get_unix_time_from_system() + bias_seconds) / 86400)

func is_daily_reward_available() -> bool:
	var today = get_local_day_number()
	return last_claim_day == -1 or today > last_claim_day

func get_next_streak_day() -> int:
	var today = get_local_day_number()
	if last_claim_day == -1:
		return 1
	elif today == last_claim_day:
		return streak_count
	elif today == last_claim_day + 1:
		return (streak_count % 7) + 1
	else:
		return 1

func claim_daily_reward() -> Dictionary:
	if not is_daily_reward_available():
		return {"success": false, "amount": 0, "streak": streak_count}
		
	var today = get_local_day_number()
	var next_streak = get_next_streak_day()
	var amount = 0
	
	if next_streak == 7:
		amount = 300
		streak_count = 0
	else:
		amount = 50
		streak_count = next_streak
		
	last_claim_day = today
	global_rubies += amount
	save_data()
	
	return {"success": true, "amount": amount, "streak": streak_count}
