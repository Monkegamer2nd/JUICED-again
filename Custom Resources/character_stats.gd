class_name CHARACTERS
extends Resource

enum Resistance {Ineffective, Normal, Effective}

@export_group("Character Stats")
@export var id : String
@export var max_health : int
@export var max_stagger : int
@export var max_energy : int
@export var slash_resistance : Resistance
@export var blunt_resistance : Resistance
@export var pierce_resistance : Resistance
@export var fruit_art : Texture2D
@export var card_deck : Array[CARD_DATA] = []

@export_group("Speed Dice")
@export var speed_dice_amount : int
@export var min_speed_roll : int
@export var max_speed_roll : int
