extends Control

const LEVEL_SELECT_SCENE = "res://Scenes/levels.tscn"
const DECK_SCENE = "res://Scenes/decks.tscn"
const JUICING_SCENE = "res://Scenes/juicing.tscn"
const OPTIONS_SCENE = "res://Scenes/options.tscn"
const looking_right = preload("res://Sprites/Characters/Looking Right.png")
const looking_left = preload("res://Sprites/Characters/Looking Left.png")

func _ready() -> void:
	SoundEffectManager.play_music("main_menu_theme", 0.75, true, -15)
	$Levels.pressed.connect(_on_levels_pressed)
	$Deck.pressed.connect(_on_teams_pressed)
	$Juicing.pressed.connect(_on_juice_pressed)
	$Options.pressed.connect(_on_options_pressed)

func _on_levels_pressed():
	SceneTransition.change_scene(LEVEL_SELECT_SCENE, "cloud")

func _on_teams_pressed():
	SceneTransition.change_scene(DECK_SCENE, "cloud")

func _on_juice_pressed():
	SceneTransition.change_scene(JUICING_SCENE, "cloud")

func _on_options_pressed():
	SceneTransition.previous_scene = "res://Scenes/main_menu.tscn"
	SceneTransition.change_scene(OPTIONS_SCENE, "cloud")


func _on_levels_mouse_entered() -> void:
	$Glasses.texture = looking_left
	$LookingLeftCorrections.visible = true
	$Looking_Right_Correction.visible = false

func _on_teams_mouse_entered() -> void:
	$Glasses.texture = looking_left
	$LookingLeftCorrections.visible = true
	$Looking_Right_Correction.visible = false

func _on_juicing_mouse_entered() -> void:
	$Glasses.texture = looking_right
	$LookingLeftCorrections.visible = false
	$Looking_Right_Correction.visible = true

func _on_options_mouse_entered() -> void:
	$Glasses.texture = looking_right
	$LookingLeftCorrections.visible = false
	$Looking_Right_Correction.visible = true
