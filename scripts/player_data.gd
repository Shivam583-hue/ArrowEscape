extends Node

const SAVE_PATH = "user://save.json"
const LIVES_MAX = 3
const LIVES_REFILL_SECONDS = 3600
const COINS_PER_LEVEL = 40
const LIVES_COST = 300

var coins: int = 0
var lives: int = LIVES_MAX
var lives_lost_time: float = 0.0
var current_level: int = 1
var highest_unlocked: int = 1
var hints_used: int = 0

func _ready():
	load_data()

func _process(_delta):
	if lives < LIVES_MAX and lives_lost_time > 0.0:
		var elapsed = Time.get_unix_time_from_system() - lives_lost_time
		if elapsed >= LIVES_REFILL_SECONDS:
			lives = LIVES_MAX
			lives_lost_time = 0.0
			save_data()

func lose_life() -> int:
	lives -= 1
	if lives <= 0:
		lives = 0
		lives_lost_time = Time.get_unix_time_from_system()
	save_data()
	return lives

func reset_lives():
	lives = LIVES_MAX
	lives_lost_time = 0.0
	save_data()

func buy_lives() -> bool:
	if coins >= LIVES_COST:
		coins -= LIVES_COST
		lives = LIVES_MAX
		lives_lost_time = 0.0
		save_data()
		return true
	return false

func complete_level(level: int):
	coins += COINS_PER_LEVEL
	if level >= highest_unlocked:
		highest_unlocked = level + 1
	lives = LIVES_MAX
	save_data()

func get_time_until_refill() -> float:
	if lives >= LIVES_MAX or lives_lost_time <= 0.0:
		return 0.0
	var elapsed = Time.get_unix_time_from_system() - lives_lost_time
	return max(0.0, LIVES_REFILL_SECONDS - elapsed)

func save_data():
	var data = {
		"coins": coins,
		"lives": lives,
		"lives_lost_time": lives_lost_time,
		"current_level": current_level,
		"highest_unlocked": highest_unlocked,
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_data():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	var data = json.data
	if data is Dictionary:
		coins = data.get("coins", 0)
		lives = data.get("lives", LIVES_MAX)
		lives_lost_time = data.get("lives_lost_time", 0.0)
		current_level = data.get("current_level", 1)
		highest_unlocked = data.get("highest_unlocked", 1)
