extends Node2D

# The max X value that the hand should be able to be.
const HAND_SIZE = 900
const CARD_WIDTH = 110

# These two constants are just extras for me to correct the equation
const X_DIFFERENCE = -90
const Y_DIFFERENCE = 150
const DEFAULT_CARD_MOVE_SPEED = 0.15
const SPEED_DICE_COLLISION_LAYER = 4

@onready var card_manager = $"../CardManager"

# The curve that determines how high up the cards may be
@export var hand_curve: Curve

# The curve that determines rotation of the cards
@export var rotation_curve: Curve

# The max possible rotation of degrees
@export var max_rotation_degrees := 15

# The max possible seperation of each card
@export var x_sep := 15.0

# The lowest the cards can go
@export var y_min := 425

# The highest the cards can go
@export var  y_max := -45

var player_hand = []
var center_screen_x : float
var y_multiplier : float
var new_rotation
var player_reference


func _ready() -> void:
	player_reference = $"../PlayerTeamContainer/Control/Player"
	center_screen_x = get_viewport_rect().size.x / 2
	$"../CardTargetSelector".connect("enemy_selected", enemy_selected)
	
#Draws a card
func draw_card(card: CARDS) -> void:
	$"../CardManager".add_child(card)
	card.name = "Card"
	add_card_to_hand(card)

func add_card_to_hand(card, speed := DEFAULT_CARD_MOVE_SPEED):
	if card not in player_hand:
		card_manager.grow_cards()
		player_hand.insert(0, card)
		update_hand_position(speed)

func update_hand_position(speed, y_offset := 0.0):
	for i in range(player_hand.size()):
		var new_position = Vector2(calculate_card_position_x(i), calculate_card_position_y(i) + y_offset)
		
		var card = player_hand[i]
		var rot_multiplier := rotation_curve.sample(1.0 / (player_hand.size() - 1) * i)
		
		if player_hand.size() == 1:
			rot_multiplier = 0.0
		
		card.starting_position = new_position
		new_rotation = max_rotation_degrees * rot_multiplier
		animate_card_to_position(card, new_position, new_rotation, speed)
		
func calculate_card_position_x(index):
	var final_x_sep := x_sep
	var total_width = (player_hand.size()-1) * CARD_WIDTH + ((player_hand.size()-1) * final_x_sep)
	if total_width > HAND_SIZE:
		final_x_sep = (HAND_SIZE - (CARD_WIDTH * float(player_hand.size()))) / float((player_hand.size() - 1))
		total_width = HAND_SIZE + X_DIFFERENCE
	var x_offset : float = center_screen_x + index * (CARD_WIDTH + final_x_sep) - total_width / 2
	return x_offset

func calculate_card_position_y(index):
	var card_count = player_hand.size()
	y_multiplier = hand_curve.sample(1.0/(card_count-1)*index)
		
	if card_count == 1:
		y_multiplier = 0.0
	var final_y: float = (y_min + y_max * y_multiplier) + Y_DIFFERENCE
	return final_y 

func animate_card_to_position(card, new_position, rotation_for_cards, speed):
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "position", new_position, speed)
	var tween2 = get_tree().create_tween()
	tween2.set_trans(Tween.TRANS_CUBIC)
	tween2.set_ease(Tween.EASE_IN_OUT)
	tween2.tween_property(card, "rotation_degrees", rotation_for_cards, speed)

func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		var tween = get_tree().create_tween()
		tween.tween_property(card, "position", Vector2(card.position.x, card.position.y + 400) , DEFAULT_CARD_MOVE_SPEED)
		update_hand_position(DEFAULT_CARD_MOVE_SPEED)
	
func enemy_selected(current_card):
	var speed_dice_selected = player_reference.selected_speed_dice
	var enemy_speed_dice = raycast_check_for_speed_dice()
	var selected_index = speed_dice_selected.get_index()
	var previous_enemy_speed_dice = null
	
	if enemy_speed_dice == null:
		return
	
	if !speed_dice_selected.target_speed_dice.is_empty():
		previous_enemy_speed_dice = speed_dice_selected.target_speed_dice[0]
	
	if speed_dice_selected == null:
		return
	
	var old_card_cost = 0
	if !speed_dice_selected.card_for_dice.is_empty():
		old_card_cost = speed_dice_selected.card_for_dice[0].energy_cost
	
	if player_reference.current_energy + old_card_cost - current_card.energy_cost < 0:
		return
	
	if !speed_dice_selected.card_for_dice.is_empty():
		var old_card = speed_dice_selected.card_for_dice[0]
		
		if old_card.has_method("clear_targets"):
			old_card.clear_targets()
		else:
			old_card.targets.clear()
		
		player_reference.current_energy += old_card.energy_cost
		add_card_to_hand(old_card, DEFAULT_CARD_MOVE_SPEED) 
		speed_dice_selected.card_for_dice.clear()
		speed_dice_selected.target_speed_dice.clear()
		speed_dice_selected.viable_clashing_speed_dice.clear()
	
	if previous_enemy_speed_dice != null and is_instance_valid(previous_enemy_speed_dice):
		previous_enemy_speed_dice.viable_clashing_speed_dice.erase(speed_dice_selected)
		previous_enemy_speed_dice.current_target_index = previous_enemy_speed_dice.starting_target_index
		var old_enemy_unit = previous_enemy_speed_dice.get_parent().get_parent()
		old_enemy_unit.arrow_for_dice.redraw_all_arrows(old_enemy_unit.all_units)
	
	var tween3 = get_tree().create_tween()
	tween3.set_trans(Tween.TRANS_CUBIC)
	tween3.set_ease(Tween.EASE_IN_OUT)
	tween3.tween_property(current_card.card_information, "position", current_card.card_information_starting_position, DEFAULT_CARD_MOVE_SPEED)
	remove_card_from_hand(current_card)
	speed_dice_selected.card_for_dice.append(current_card)
	speed_dice_selected.target_speed_dice.append(enemy_speed_dice)
	player_reference.current_energy -= current_card.energy_cost
	player_reference.set_up_energy_display()
	if enemy_speed_dice.speed_dice_value < speed_dice_selected.speed_dice_value or enemy_speed_dice.starting_target_index == selected_index:
		if enemy_speed_dice.viable_clashing_speed_dice.is_empty():
			speed_dice_selected.viable_clashing_speed_dice.append(enemy_speed_dice)
			enemy_speed_dice.viable_clashing_speed_dice.append(speed_dice_selected)
			enemy_speed_dice.current_target_index = selected_index
			if enemy_speed_dice.current_target_index != enemy_speed_dice.starting_target_index:
				enemy_speed_dice.get_parent().get_parent().arrow_for_dice.redraw_all_arrows(enemy_speed_dice.get_parent().get_parent().all_units)

	if !enemy_speed_dice.viable_clashing_speed_dice.is_empty():
		$"../UIManager".card_display_show(enemy_speed_dice.viable_clashing_speed_dice[0], true)

func raycast_check_for_speed_dice():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = SPEED_DICE_COLLISION_LAYER
	var results = space_state.intersect_point(parameters)
	if results.size() > 0:
		var result_parent = results[0].collider.get_parent()
		return result_parent
	return null
