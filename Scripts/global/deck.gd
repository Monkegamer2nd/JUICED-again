extends Node

const BASIC_ATTACK = preload("res://Cards/basic_attack.tres")
const BASIC_BLOCK = preload("res://Cards/basic_block.tres")
const BIG_ATTACK = preload("res://Cards/heavy_attack.tres")

var player_deck: Array[CARD_DATA] = []

func _ready() -> void:
	set_default_deck()

func set_default_deck() -> void:
	player_deck = [BASIC_ATTACK, BASIC_ATTACK, BASIC_ATTACK, BASIC_BLOCK, BASIC_BLOCK, BASIC_BLOCK, BIG_ATTACK, BIG_ATTACK]
