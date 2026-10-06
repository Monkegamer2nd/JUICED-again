extends Control

const COLLECTED_FRUIT = preload("res://Prefabs/collected_fruit.tscn")

@onready var grid_container = $ScrollContainer/GridContainer
@onready var nothing_is_there = $Nothing
var nothing_as_a_reward : bool = true

func _ready() -> void:
	SoundEffectManager.play_music("win_screen_theme", 0.6, true, -15)
	if not GlobalData or GlobalData.reward_information.is_empty():
		return
	
	for fruits in GlobalData.reward_information["quantity"]:
		var fruit = COLLECTED_FRUIT.instantiate()
		grid_container.add_child(fruit)
		fruit.set_up_name_and_amount(GlobalData.reward_information["resource"], GlobalData.reward_information["quantity"])
		fruit.amount.visible = false
		fruit.collider.disabled = true
		nothing_as_a_reward = false
	if nothing_as_a_reward:
		nothing_is_there.visible = true
	else:
		nothing_is_there.visible = false

func _on_continue_pressed() -> void:
	GlobalData.reward_information.clear()
	if SceneTransition.current_level_id == "Tutorial Level":
		SceneTransition.next_cutscene_data = load("res://Cutscenes/tutorialwin.tres")
		SceneTransition.next_scene_after_cutscene = "res://Scenes/main_menu.tscn"
	elif SceneTransition.current_level_id == "Level One":
		SceneTransition.next_cutscene_data = load("res://Cutscenes/levelonewin.tres")
		SceneTransition.next_scene_after_cutscene = "res://Scenes/main_menu.tscn"
	
	SceneTransition.change_scene("res://Scenes/main_cutscene.tscn", "fade")

func _on_quit_pressed() -> void:
	get_tree().quit()
