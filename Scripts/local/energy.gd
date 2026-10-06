extends Control

const FULL_ENERGY = preload("res://Sprites/Misc/Energy.png")
const EMPTY_ENERGY = preload("res://Sprites/Misc/Empty_Energy.png")

@onready var energy_sprite = $EnergySprite

func set_filled(is_filled: bool):
	if is_filled:
		energy_sprite.texture = FULL_ENERGY
	else:
		energy_sprite.texture = EMPTY_ENERGY
