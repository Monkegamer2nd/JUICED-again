class_name Die_Data
extends Resource

enum DieType {SLASH, PIERCE, BLUNT, BLOCK, EVADE}

@export_group("Die Properties")
@export var type : DieType
@export var min_roll : int
@export var max_roll : int
@export var special_effects : Script #THIS ONE IS OPTIONAL
