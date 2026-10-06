extends Control

@onready var master_volume_slider = $OptionBackground/MasterSoud
@onready var master_percentage = $OptionBackground/MasterPercentage
@onready var music_volume_slider = $OptionBackground/Music
@onready var music_percentage = $OptionBackground/MusicPercentage
@onready var sound_effect_volume_slider = $OptionBackground/SFX
@onready var sound_effect_percentage = $OptionBackground/SoundEffectPercentage
@onready var input_manager = $"../../../InputManager"
@onready var fullscreen = $OptionBackground/FullscreenButton

func _ready() -> void:
	input_manager.p_key_pressed.connect(unpaused_while_in_options)
	$OptionBackground/Back.pressed.connect(back_button_pressed)
	master_volume_slider.value = GlobalData.master_volume
	GlobalData.setting_changed.connect(_on_global_setting_changed)
	master_volume_slider.value_changed.connect(_on_master_value_changed)
	music_volume_slider.value_changed.connect(_on_music_value_changed)
	sound_effect_volume_slider.value_changed.connect(_on_sfx_value_changed)
	master_volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	music_volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	sound_effect_volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	update_percentage_label(master_percentage, master_volume_slider.value)
	update_percentage_label(music_percentage, music_volume_slider.value)
	update_percentage_label(sound_effect_percentage, sound_effect_volume_slider.value)
	fullscreen.button_pressed = GlobalData.is_fullscreen

func _process(_delta: float) -> void:
	if fullscreen.button_pressed != GlobalData.is_fullscreen:
		fullscreen.button_pressed = GlobalData.is_fullscreen

func update_percentage_label(label: Label, value: float) -> void:
	label.text = str(int(value * 100)) + "%"

func update_bus_volume(bus_name: String, value: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	
	if value == 0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		var db_volume = linear_to_db(value)
		AudioServer.set_bus_volume_db(bus_index, db_volume)

func _on_master_value_changed(value: float) -> void:
	update_bus_volume("Master", value)
	GlobalData.set_setting("master_volume", value)
	update_percentage_label(master_percentage, value)

func _on_music_value_changed(value: float) -> void:
	update_bus_volume("Music", value)
	GlobalData.set_setting("music_volume", value)
	update_percentage_label(music_percentage, value)

func _on_sfx_value_changed(value: float) -> void:
	update_bus_volume("SFX", value)
	GlobalData.set_setting("sound_effects_volume", value)
	update_percentage_label(sound_effect_percentage, value)

func back_button_pressed():
	var tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property($OptionBackground, "position", Vector2(0, -648), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _on_global_setting_changed(setting_name: String, value: float):
	if setting_name == "master_volume":
		master_volume_slider.set_value_no_signal(value)
		update_percentage_label(master_percentage, master_volume_slider.value)
	if setting_name == "music_volume":
		master_volume_slider.set_value_no_signal(value)
		update_percentage_label(master_percentage, master_volume_slider.value)
	if setting_name == "sound_effects_volume":
		master_volume_slider.set_value_no_signal(value)
		update_percentage_label(master_percentage, master_volume_slider.value)

func unpaused_while_in_options():
	var tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property($OptionBackground, "position", Vector2(0, -648), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _on_fullscreen_button_toggled(toggled_on: bool) -> void:
	GlobalData.set_fullscreen(toggled_on)
