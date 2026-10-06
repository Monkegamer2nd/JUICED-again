class_name DICE_UI
extends Control

const DICE_SLASH_SPRITE = preload("res://Sprites/Dice/Slash.png")
const DICE_PIERCE_SPRITE = preload("res://Sprites/Dice/Pierce.png")
const DICE_BLUNT_SPRITE = preload("res://Sprites/Dice/Blunt.png")
const DICE_BLOCK_SPRITE = preload("res://Sprites/Dice/Block.png")
const DICE_EVADE_SPRITE = preload("res://Sprites/Dice/Evade.png")

@onready var dice_sprite : TextureRect = $TextureRect

func _ready() -> void:
	pass

func setup(type) -> void:
	match type:
		Die_Data.DieType.SLASH:
			dice_sprite.texture = DICE_SLASH_SPRITE
		Die_Data.DieType.PIERCE:
			dice_sprite.texture = DICE_PIERCE_SPRITE
		Die_Data.DieType.BLUNT:
			dice_sprite.texture = DICE_BLUNT_SPRITE
		Die_Data.DieType.BLOCK:
			dice_sprite.texture = DICE_BLOCK_SPRITE
		Die_Data.DieType.EVADE:
			dice_sprite.texture = DICE_EVADE_SPRITE
