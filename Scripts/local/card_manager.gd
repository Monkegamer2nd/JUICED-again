extends Node2D

const COLLISION_MASK_CARD = 2
const DEFAULT_CARD_MOVE_SPEED = 0.1
const DEFAULT_CARD_SCALE = 1.0
const CARD_LARGER_SCALE = 1.1
const CARD_SMALLER_SCALE = 0.7
const LOWER_VALUE = 75
const SOUND_EFFECT_LIBRARY : Dictionary = {"card_rustle": [preload("res://Sounds/SoundEffects/cardrustle.mp3")]}

var hand_reference
var screen_size
var card_being_dragged
var is_hovering_on_card
var cards_shrunk
var turn_start
var mouse_is_in_shrink_zone
var cards_targets = []
var enemy_reference
var player_reference
var battle_manager_reference
var speed_dice_selected
var hand_is_drawing: bool = false

func _ready() -> void:
	screen_size = get_viewport_rect().size
	hand_reference = $"../PlayerHand"
	player_reference = $"../PlayerTeamContainer/Control/Player"
	battle_manager_reference = $"../BattleManager"
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)
	cards_shrunk = false
	speed_dice_selected = false
	mouse_is_in_shrink_zone = false
	turn_start = true
	await wait(DEFAULT_CARD_MOVE_SPEED * 5)
	turn_start = false

func assign_enemy(spawned_enemy) -> void:
	enemy_reference = spawned_enemy

func _process(_delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	
	if turn_start:
		return
	elif hand_is_drawing:
		return
	elif card_being_dragged:
		return
	elif battle_manager_reference.clashing_begin:
		return
	elif enemy_reference.hovering_over_speed_dice:
		return
	elif is_hovering_on_card:
		return
	
	if mouse_pos.y <= 400:
		shrink_cards()
	else:
		grow_cards()

func start_drag(card):
	if player_reference.selected_speed_dice:
		card_being_dragged = card
		Events.card_aim_started.emit(card_being_dragged)
		card.scale = Vector2(CARD_LARGER_SCALE, CARD_LARGER_SCALE)

func finish_drag():
	if card_being_dragged:
		var dragged_card = card_being_dragged
		var new_card_hovered = raycast_check_for_card()
		card_being_dragged = null
		Events.card_aim_ended.emit(dragged_card)
		
		if dragged_card in hand_reference.player_hand:
			highlight_card(dragged_card, false)
			
			if new_card_hovered:
				is_hovering_on_card = true
				highlight_card(new_card_hovered, true)
				
			else:
				is_hovering_on_card = false
		else:
			is_hovering_on_card = false


func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)

func on_hovered_over_card(card):
	if !is_hovering_on_card:
		is_hovering_on_card = true
		highlight_card(card, true)

func on_hovered_off_card(card):
	if !card_being_dragged:
		highlight_card(card, false)
		var new_card_hovered = raycast_check_for_card()
		if new_card_hovered and new_card_hovered != card:
			is_hovering_on_card = true
			highlight_card(new_card_hovered, true)
		else:
			is_hovering_on_card = false

func highlight_card(card, hovered):
	if hovered:
		SoundEffectManager.play_sfx("card_rustle", "SFX", randf_range(-15, -5), randf_range(0.85, 1.2), 0.34, 0.7)
		hand_reference.animate_card_to_position(card, Vector2(card.position.x, card.starting_position.y - 75), 0, DEFAULT_CARD_MOVE_SPEED)
		var tween2 = get_tree().create_tween()
		tween2.tween_property(card, "scale", Vector2(CARD_LARGER_SCALE, CARD_LARGER_SCALE) , DEFAULT_CARD_MOVE_SPEED)
		var tween3 = get_tree().create_tween()
		tween3.set_trans(Tween.TRANS_CUBIC)
		tween3.set_ease(Tween.EASE_IN_OUT)
		tween3.tween_property(card.card_information, "position", Vector2(65 ,-92), DEFAULT_CARD_MOVE_SPEED)
		card.z_index = 2
		card.skirt.disabled = false 
	else:
		hand_reference.update_hand_position(DEFAULT_CARD_MOVE_SPEED, 0)
		var tween2 = get_tree().create_tween()
		tween2.tween_property(card, "scale", Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE) , DEFAULT_CARD_MOVE_SPEED)
		var tween3 = get_tree().create_tween()
		tween3.set_trans(Tween.TRANS_CUBIC)
		tween3.set_ease(Tween.EASE_IN_OUT)
		tween3.tween_property(card.card_information, "position", Vector2(card.card_information_starting_position.x ,card.card_information_starting_position.y), DEFAULT_CARD_MOVE_SPEED)
		card.z_index = 1
		card.skirt.disabled = true

func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var results = space_state.intersect_point(parameters)
	if results.size() > 0:
		return get_card_with_highest_z_index(results)
	return null


func get_card_with_highest_z_index(cards):
	# Assume the first card in cards array has the highest z index
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	# Loop through the rest of the cards checking for a higher z index
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card

func on_left_click_released():
	finish_drag()

func wait(wait_time):
	var timer = get_tree().create_timer(wait_time)
	await timer.timeout

func shrink_cards():
	if cards_shrunk:
		return
	
	cards_shrunk = true
	
	hand_reference.x_sep = -25
	hand_reference.update_hand_position(DEFAULT_CARD_MOVE_SPEED, 100)
	
	for cards in hand_reference.player_hand:
		if cards.get(&"is_drawing") == true: 
			continue
		cards.resting.disabled = true
		cards.get_node("AnimationPlayer").play("shrink")
		var tween = get_tree().create_tween()
		tween.tween_property(cards, "scale", Vector2(CARD_SMALLER_SCALE, CARD_SMALLER_SCALE) , DEFAULT_CARD_MOVE_SPEED)

func grow_cards():
	if !cards_shrunk:
		return
	
	cards_shrunk = false
	
	hand_reference.x_sep = 25
	hand_reference.update_hand_position(DEFAULT_CARD_MOVE_SPEED, 0)
	
	for cards in hand_reference.player_hand:
		cards.get_node("AnimationPlayer").play("grow")
		var tween = get_tree().create_tween()
		tween.tween_property(cards, "scale", Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE) , DEFAULT_CARD_MOVE_SPEED)
		cards.resting.disabled = false
	
