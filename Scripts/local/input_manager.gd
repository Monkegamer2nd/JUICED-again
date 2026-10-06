extends Node2D

signal left_mouse_button_clicked
signal left_mouse_button_released
signal right_mouse_button_clicked
signal space_bar_pressed
signal p_key_pressed


const COLLISION_MASK_CARD = 1
const COLLISION_MASK_SPEED_DICE = 4
var card_manager_reference
var player_reference
var hand_reference
var battle_manager_reference
var enemy_reference

func _ready() -> void:
	card_manager_reference = $"../CardManager"
	player_reference = $"../PlayerTeamContainer/Control/Player"
	battle_manager_reference = $"../BattleManager"
	enemy_reference = battle_manager_reference.enemy
	hand_reference = $"../PlayerHand"

func setup_enemy_input(spawned_enemy) -> void:
	enemy_reference = spawned_enemy

func _input(event):
	if !battle_manager_reference.turn_count_being_shown:
		if event is InputEventKey and event.keycode == KEY_P and not event.is_echo():
			if event.pressed:
				emit_signal("p_key_pressed")
				return
		
		if get_tree().paused:
			return
	
	if !battle_manager_reference.clashing_begin:
		if event is InputEventKey and event.keycode == KEY_SPACE and not event.is_echo():
			if event.pressed:
				emit_signal("space_bar_pressed")
			
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			emit_signal("left_mouse_button_clicked")
			raycast_at_cursor()
		else:
			emit_signal("left_mouse_button_released")
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			emit_signal("right_mouse_button_clicked")
			raycast_for_right_click()
	

func raycast_at_cursor():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	var results = space_state.intersect_point(parameters)
	if results.size() > 0:
		var result_collision_mask = results[0].collider.collision_mask
		if result_collision_mask == COLLISION_MASK_CARD:
			#card clicked
			var card_found = results[0].collider.get_parent()
			if card_found:
				card_manager_reference.start_drag(get_card_with_highest_z_index(results))
		if result_collision_mask == COLLISION_MASK_SPEED_DICE:
			var speed_dice_found = results[0].collider.get_parent()
			if speed_dice_found.dice_owner == player_reference:
				speed_dice_found.get_parent().get_parent().speed_dice_selected(speed_dice_found)
				

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

func raycast_for_right_click():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	
	var results = space_state.intersect_point(parameters)
	if results.size() > 0:
		var result_collision_mask = results[0].collider.collision_mask
		
		if result_collision_mask == COLLISION_MASK_SPEED_DICE:
			var speed_dice_found = results[0].collider.get_parent()
			
			if speed_dice_found.dice_owner == player_reference:
				remove_card_from_player_dice(speed_dice_found)

func remove_card_from_player_dice(speed_dice):
	var speed_dice_selected_obj = player_reference.selected_speed_dice
	var previous_enemy_speed_dice = null
	
	if speed_dice.card_for_dice.is_empty():
		return
	
	card_manager_reference.hand_is_drawing = true
	card_manager_reference.grow_cards()
	speed_dice.card_for_dice[0].set(&"is_drawing", true)
	$"../PlayerHand".add_card_to_hand(speed_dice.card_for_dice[0])
	
	if speed_dice_selected_obj and !speed_dice_selected_obj.target_speed_dice.is_empty():
		previous_enemy_speed_dice = speed_dice_selected_obj.target_speed_dice[0]
	
	if speed_dice.get("viable_clashing_speed_dice") != null:
		if !speed_dice.viable_clashing_speed_dice.is_empty():
			enemy_reference.emit_signal("mouse_exited_enemy_area", speed_dice.viable_clashing_speed_dice[0])
		if previous_enemy_speed_dice != null and is_instance_valid(previous_enemy_speed_dice):
			previous_enemy_speed_dice.viable_clashing_speed_dice.erase(speed_dice_selected_obj)
			previous_enemy_speed_dice.current_target_index = previous_enemy_speed_dice.starting_target_index
		speed_dice.viable_clashing_speed_dice.clear()
		
	player_reference.emit_signal("mouse_exited_player_area", speed_dice)
	
	if enemy_reference.get("arrow_for_dice") and enemy_reference.arrow_for_dice:
		enemy_reference.arrow_for_dice.redraw_all_arrows(enemy_reference.all_units)
	
	player_reference.current_energy += speed_dice.card_for_dice[0].energy_cost
	player_reference.set_up_energy_display()
	await get_tree().create_timer(0.15 * 1.5).timeout
	speed_dice.card_for_dice[0].set(&"is_drawing", false)
	card_manager_reference.hand_is_drawing = false
	speed_dice.card_for_dice.clear()
