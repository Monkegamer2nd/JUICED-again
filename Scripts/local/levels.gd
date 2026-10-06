extends Node2D

const MAIN_MENU = "res://Scenes/main_menu.tscn"
@onready var tutorial_level = $TutorialLevel
@onready var level_one = $LevelOne

func _ready() -> void:
	$CanvasGroup/UI/Back.pressed.connect(back_button_pressed)
	check_map_progression()

func back_button_pressed():
	SceneTransition.change_scene(MAIN_MENU, "cloud")

func check_map_progression() -> void:
	level_one.disabled = (GlobalData.level_complete > 1)
	level_one.visible = (GlobalData.level_complete >= 1)


func _on_level_one_pressed() -> void:
	SceneTransition.current_floor_level = -1
	SceneTransition.current_level_id = "Level One"
	SceneTransition.reward_amount = 5
	SceneTransition.next_cutscene_data = load("res://Cutscenes/leveloneentrance.tres")
	SceneTransition.next_scene_after_cutscene = "res://Scenes/level_one.tscn"
	
	SceneTransition.change_scene("res://Scenes/main_cutscene.tscn", "fade")


func _on_tutorial_level_pressed() -> void:
	SceneTransition.current_floor_level = -1
	SceneTransition.current_level_id = "Tutorial Level"
	SceneTransition.reward_amount = 5
	SceneTransition.change_scene("res://Scenes/tutorial.tscn", "fade")
