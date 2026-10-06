extends Control

@onready var animation_player = $AnimationPlayer
@onready var button_container = $ButtonContainer
@onready var input_manager = $"../../../InputManager"
@onready var battle_manager = $"../../../BattleManager"
@onready var options = $"../OptionManager/OptionBackground"

func _ready() -> void:
	animation_player.play("RESET")
	input_manager.connect("p_key_pressed", pause_button_pressed)
	for button in button_container.get_children():
		button.disabled = true 

func pause_button_pressed():
	if !get_tree().paused:
		pause()
	else:
		resume()

func pause():
	get_tree().paused = true
	animation_player.play("fade_in")
	for button in button_container.get_children():
		button.disabled = false

func resume():
	get_tree().paused = false
	animation_player.play("fade_out")
	for button in button_container.get_children():
		button.disabled = true 

func _on_start_pressed() -> void:
	resume()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	resume()
	battle_manager.restart_battle()

func _on_options_pressed() -> void:
	var tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(options, "position", Vector2(0, 0), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _on_quit_pressed() -> void:
	get_tree().quit()
