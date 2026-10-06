class_name CARD_DATA
extends Resource

enum Target {SINGLE_ENEMY, ALL_ENEMIES, EVERYONE}

@export_group("Card Properties")
@export var id : String
@export var energy_cost : int
@export var target : Target
@export var card_art : Texture2D
@export var dice_list : Array[Die_Data] = []

func is_single_target() -> bool:
	return target == Target.SINGLE_ENEMY
