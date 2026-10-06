extends Control

const OPTIONS = "res://Scenes/options.tscn"

func _ready() -> void:
	$Back.pressed.connect(back_button_pressed)

func back_button_pressed():
	SceneTransition.change_scene(OPTIONS, "cloud")
