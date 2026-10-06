extends Node2D

const CARD_SCENE = preload("res://Prefabs/card.tscn")

func create_card(card_data: CARD_DATA) -> CARDS:
	var card = CARD_SCENE.instantiate() as CARDS
	
	card.card_data = card_data.duplicate(true)
	
	return card
