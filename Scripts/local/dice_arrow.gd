extends Node2D

@export var arrow_scene : PackedScene
@onready var canvas_layer = $CanvasLayer


var active_arrows: Dictionary = {}

func clear_arrows():
	for arrow in active_arrows.values():
		if is_instance_valid(arrow):
			arrow.queue_free()
	active_arrows.clear()

func redraw_all_arrows(all_characters: Array) -> void:
	clear_arrows()
	for character in all_characters:
		if not is_instance_valid(character) or not character.has_node("SpeedDiceContainer"):
			continue
			
		var dice_container = character.get_node("SpeedDiceContainer")
		for speed_dice in dice_container.get_children():
			if speed_dice.target_character == null or speed_dice.current_target_index == -1:
				continue
			var target_team = speed_dice.target_character
			if not target_team.has_node("SpeedDiceContainer"):
				continue
				
			var target_container = target_team.get_node("SpeedDiceContainer")
			
			if speed_dice.current_target_index >= target_container.get_child_count():
				continue
				
			var target_dice = target_container.get_child(speed_dice.current_target_index)
			var arrow = arrow_scene.instantiate()
			canvas_layer.add_child(arrow)
			active_arrows[speed_dice] = arrow
			var dice_slot_index = speed_dice.get_index()
			arrow.curve_height = -250.0 - (dice_slot_index * 80.0)
			arrow.setup(speed_dice, target_dice)
			active_arrows[speed_dice] = arrow
			
			
