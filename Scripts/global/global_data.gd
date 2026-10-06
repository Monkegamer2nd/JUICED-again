extends Node

signal setting_changed(setting_name: String, value: float)

const FLOOR_UNLOCK_REQUIREMENTS = {}

var highest_unlocked_floor: int = 0
var completed_levels: Array[String] = []
var level_complete: int = 0
var player_inventory: Dictionary = {}
var unlocked_combat_cards: Array[Resource] = [
	preload("res://Cards/basic_attack.tres"),
	preload("res://Cards/basic_block.tres"),
	preload("res://Cards/heavy_attack.tres"),
	preload("res://Cards/cower_away.tres")
]
var card_reward_information : Array = []
var reward_information: Dictionary = {}
var saved_character_data : Resource = preload("res://Characters/defaultplayer.tres")
var master_volume: float = 0.5
var sfx_volume: float = 0.5
var is_fullscreen: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		set_fullscreen(!is_fullscreen)
	
func set_fullscreen(value: bool) -> void:
	is_fullscreen = value
	
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func set_setting(setting_name: String, value: float) -> void:
	if setting_name in self:
		self[setting_name] = value
		setting_changed.emit(setting_name, value)

func clear_level(level_id: String, floor_number: int) -> void:
	if not completed_levels.has(level_id):
		completed_levels.append(level_id)
		level_complete += 1
		
	if FLOOR_UNLOCK_REQUIREMENTS.has(floor_number):
		var required_continuation_id = FLOOR_UNLOCK_REQUIREMENTS[floor_number]
		if level_id == required_continuation_id and highest_unlocked_floor == floor_number:
			highest_unlocked_floor += 1
