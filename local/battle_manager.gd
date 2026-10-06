class_name BATTLE_MANAGER
extends Node

signal approaching
signal against_each_other
signal back_to_normal
signal going_backwards
signal player_defeated
signal enemy_defeated
signal enemies_instantiated(enemies)
signal attack_thrown(attacker, die_type)
signal attack_landed(hurt)
signal clash_started(player_card, enemy_card)
signal die_rolled(combatant_type, die_type, roll_value)
signal hit_landed(target, damage, stagger_damage, damage_type)
signal evade_triggered(evader)
signal block_triggered(blocker)
signal clash_ended()

enum DieType { SLASH = 0, PIERCE = 1, BLUNT = 2, BLOCK = 3, EVADE = 4 }

# The starting hand size of each game
const STARTING_HAND_SIZE = 5
const DEFAULT_SPEED = 0.1
const CLASH_SEPERATION = 75
const DODGE_SOUND = preload("res://Sounds/SoundEffects/another whoosh.wav")
const NORMAL_DICE = preload("res://Sprites/Dice/Blank.png")
const RESISTANCE_MULTIPLIERS = {
	0 : 0.5,
	1 : 1.0,
	2 : 2.0, 
}

@onready var player : MAIN_PLAYER = $"../PlayerTeamContainer/Control/Player"
@onready var enemy_container : Control = $"../EnemyTeamContainer/Control"
@onready var player_card_display = $"../CanvasLayer/UI/PlayerCardDisplay"
@onready var enemy_card_display = $"../CanvasLayer/UI/EnemyCardDisplayed"
@onready var dice_for_arrow = $"../dice_arrow"
@onready var ui_manager : Node = $"../UIManager"
@onready var player_hand : Node2D = $"../PlayerHand"
@onready var card_manager : Node2D = $"../CardManager"
@export var enemy_to_spawn : PackedScene 

var reward_amount
var current_level_id : String
var current_floor_level : int
var enemy : ENEMY
var player_battle_deck: Array[CARD_DATA] = []
var enemy_battle_deck: Array[CARD_DATA] = []
var player_discard_pile: Array[CARD_DATA] = []
var enemy_discard_pile: Array[CARD_DATA] = []
var player_retained_defense: Array = []
var enemy_retained_defense: Array = []
var player_global_home : Vector2
var enemy_global_home : Vector2
var active_player_dice_ui: Control = null
var active_enemy_dice_ui: Control = null
var player_team: Array = []
var enemy_team: Array = []
var enemy_cards_in_hand: Array = []
var turn_count_being_shown
var turn_count : int = 1
var is_one_sided_attack_enemy : bool = false
var is_one_sided_attack_player : bool = false
var clashing_begin : bool = false

func _ready() -> void:
	SoundEffectManager.play_music("fight_theme", 0.3, true, -15)
	await get_tree().process_frame
	current_floor_level = SceneTransition.current_floor_level
	current_level_id = SceneTransition.current_level_id
	reward_amount = SceneTransition.reward_amount
	player_team = $"../PlayerTeamContainer/Control".get_children()
	enemy_team = $"../EnemyTeamContainer/Control".get_children()
	start_battle()
	$"../InputManager".connect("space_bar_pressed", space_bar_pressed)
	$"../InputManager".connect("left_mouse_button_clicked", left_mouse_clicked)

func start_battle() -> void:
	if enemy_to_spawn:
		var new_enemy = enemy_to_spawn.instantiate()
		new_enemy.initialize_enemy(self, enemy_card_display, dice_for_arrow)
		enemy_container.add_child(new_enemy)
		new_enemy.position = Vector2(175.0, 275.0)
		enemy = new_enemy as ENEMY
		enemy_team.append(enemy) 
		ui_manager.setup_enemy_ui(enemy)
		card_manager.assign_enemy(enemy)
		$"../InputManager".setup_enemy_input(enemy)
		emit_signal("enemies_instantiated", enemy)
	turn_count_being_shown = true
	GlobalData.saved_character_data = player.character_stats
	player_global_home = player.global_position
	enemy_global_home = enemy.global_position
	player_battle_deck.append_array(player.player_deck)
	player_battle_deck.shuffle()
	player.setup_speed_dice()
	player.set_up_energy_display()
	enemy.setup_speed_dice()
	enemy_battle_deck.append_array(enemy.enemy_deck)
	enemy_battle_deck.shuffle()
	
	for i in range(STARTING_HAND_SIZE):
		draw_card()
		set_up_enemy_hand()
	
	enemy.set_up_attack(player_team)
	enemy.set_up_energy_display()
	
	if turn_count_being_shown == true:
		ui_manager.show_turn_count(turn_count)
		await wait(1.1)
		turn_count_being_shown = false

func draw_card() -> void:
	card_manager.hand_is_drawing = true
	card_manager.grow_cards()
	if player_battle_deck.is_empty():
		if not player_discard_pile.is_empty():
			player_battle_deck.append_array(player_discard_pile)
			player_battle_deck.shuffle()
			player_discard_pile.clear()
		else:
			card_manager.hand_is_drawing = false
			return
	
	var card_data: CARD_DATA = player_battle_deck.pop_front()
	var card = $"../CardGenerator".create_card(card_data)
	
	card.set(&"is_drawing", true)
	$"../PlayerHand".draw_card(card)
	
	await get_tree().create_timer(DEFAULT_SPEED * 1.5).timeout
	card.set(&"is_drawing", false)
	card_manager.hand_is_drawing = false

func set_up_enemy_hand():
	if enemy_battle_deck.is_empty():
		if not enemy_discard_pile.is_empty():
			enemy_battle_deck.append_array(enemy_discard_pile)
			enemy_battle_deck.shuffle()
			enemy_discard_pile.clear()
		else:
			return
	
	enemy_cards_in_hand.append(enemy_battle_deck.pop_front())

func battle_turn():
	clashing_begin = true
	card_manager.is_hovering_on_card = false
	ui_manager.force_lower_card_display()
	var hovered_card = card_manager.raycast_check_for_card()
	if hovered_card:
		card_manager.highlight_card(hovered_card, false)
		for card in card_manager.get_children():
			card.resting.disabled = true
			card.skirt.disabled = true
		await get_tree().process_frame
		
	card_manager.shrink_cards()
	var active_slots : Array[Node] = []
	for slot in player.speed_dice_container.get_children():
		if !slot.card_for_dice.is_empty():
			active_slots.append(slot)
	for slot in enemy.speed_dice_container.get_children():
		if slot.chosen_card != null:
			if slot.viable_clashing_speed_dice.is_empty():
				active_slots.append(slot)
	
	active_slots.sort_custom(func(a, b): return a.speed_dice_value > b.speed_dice_value)
	if has_node("../dice_arrow"):
		get_node("../dice_arrow").visible = false
	
	player.speed_dice_container.visible = false
	player.energy_container.visible = false
	player.collider.disabled = true
	enemy.speed_dice_container.visible = false
	enemy.energy_container.visible = false
	enemy.collider.disabled = true
	player.emit_signal("mouse_entered_player_character", player)
	enemy.emit_signal("mouse_entered_enemy_character", enemy)
	
	for speed_dice in active_slots:
		var is_player_slot = speed_dice.get_parent() == player.speed_dice_container
		var player_card_data = null
		var enemy_card_data = null
		
		if is_player_slot:
			var player_has_card = not speed_dice.card_for_dice.is_empty() and speed_dice.card_for_dice[0] != null
			player_card_data = speed_dice.card_for_dice[0].card_data if player_has_card else null
			var has_clash = not speed_dice.viable_clashing_speed_dice.is_empty()
			var enemy_speed_dice = speed_dice.viable_clashing_speed_dice[0] if has_clash else null
			enemy_card_data = enemy_speed_dice.chosen_card if enemy_speed_dice != null else null
		else:
			enemy_card_data = speed_dice.chosen_card
			player_card_data = null
			
		if player_card_data == null and enemy_card_data == null:
			continue
		
		is_one_sided_attack_enemy = (player_card_data == null)
		is_one_sided_attack_player = (enemy_card_data == null)
		clash_started.emit(player_card_data, enemy_card_data)
		var p_dice_pool = player_card_data.dice_list.duplicate(true) if player_card_data != null else []
		var e_dice_pool = enemy_card_data.dice_list.duplicate(true) if enemy_card_data != null else []
		
		if player.is_dead():
			clash_ended.emit()
			continue
		if enemy.is_dead():
			clash_ended.emit()
			continue
		
		if player.is_staggered():
			p_dice_pool.clear()
		
		if enemy.is_staggered():
			e_dice_pool.clear()
		
		var p_idx = 0
		var e_idx = 0
		var new_p_pool : Array = []
		var new_p_retained : Array = []
		var new_e_pool : Array = []
		var new_e_retained : Array = []

		while p_idx < p_dice_pool.size() or e_idx < e_dice_pool.size():
			var p_has_die = p_idx < p_dice_pool.size()
			var e_has_die = e_idx < e_dice_pool.size()
			var p_die = p_dice_pool[p_idx] if p_has_die else null
			var e_die = e_dice_pool[e_idx] if e_has_die else null
			
			if p_has_die and e_has_die:
				var p_is_def = (p_die.type == 3 or p_die.type == 4)
				var e_is_def = (e_die.type == 3 or e_die.type == 4)
				
				if p_is_def and e_is_def:
					#  Defense Clash (Skip)
					new_p_retained.append(p_die)
					new_e_retained.append(e_die)
					p_idx += 1
					e_idx += 1
				else:
					# Not defense clash (continue)
					new_p_pool.append(p_die)
					new_e_pool.append(e_die)
					p_idx += 1
					e_idx += 1
			elif p_has_die and not e_has_die:
				# One Sided Defense Clash (Skip)
				if p_die.type == 3 or p_die.type == 4:
					new_p_retained.append(p_die)
				else:
					new_p_pool.append(p_die)
				p_idx += 1
			elif e_has_die and not p_has_die:
				# One Sided Defense Clash (Skip)
				if e_die.type == 3 or e_die.type == 4:
					new_e_retained.append(e_die)
				else:
					new_e_pool.append(e_die)
				e_idx += 1
		
		player_retained_defense.append_array(new_p_retained)
		enemy_retained_defense.append_array(new_e_retained)
		
		p_dice_pool = new_p_pool
		e_dice_pool = new_e_pool
	
		
		if p_dice_pool.is_empty() and e_dice_pool.is_empty():
			if player_card_data != null:
				player_discard_pile.append(player_card_data)
			if enemy_card_data != null:
				enemy_discard_pile.append(enemy_card_data)
			clash_ended.emit()
			continue
		
		
		await animate_clash_approach()
		
		while not p_dice_pool.is_empty() or not e_dice_pool.is_empty():
			if player.is_dead() or enemy.is_dead():
				break
			if player.is_staggered():
				p_dice_pool.clear()
			if enemy.is_staggered():
				e_dice_pool.clear()
			if p_dice_pool.is_empty() and e_dice_pool.is_empty():
				break
				
			var p_is_nothing = p_dice_pool.is_empty()
			var e_is_nothing = e_dice_pool.is_empty()
			
			var p_die = null if p_is_nothing else p_dice_pool[0]
			var e_die = null if e_is_nothing else e_dice_pool[0]
			
			if p_die and e_die:
				var p_is_defense = (p_die.type == 3 or p_die.type == 4)
				var e_is_defense = (e_die.type == 3 or e_die.type == 4)
				
				if p_is_defense and e_is_defense:
					p_dice_pool.pop_front()
					e_dice_pool.pop_front()
					continue # Skip the rest of this loop iteration
			
			var p_roll = randi_range(p_die.min_roll, p_die.max_roll) if not p_is_nothing else 0
			var e_roll = randi_range(e_die.min_roll, e_die.max_roll) if not e_is_nothing else 0
			
			if active_player_dice_ui: active_player_dice_ui.queue_free()
			if active_enemy_dice_ui: active_enemy_dice_ui.queue_free()

			if not p_is_nothing:
				active_player_dice_ui = spawn_dice_overlay(player, p_die.type)
				die_rolled.emit("player", p_die.type, p_roll)
			if not e_is_nothing:
				active_enemy_dice_ui = spawn_dice_overlay(enemy, e_die.type)
				die_rolled.emit("enemy", e_die.type, e_roll)
			
			if not p_is_nothing:
				animate_dice_roll(active_player_dice_ui, p_roll, p_die.min_roll, p_die.max_roll)
			if not e_is_nothing:
				animate_dice_roll(active_enemy_dice_ui, e_roll, e_die.min_roll, e_die.max_roll)
			
			await get_tree().create_timer(0.4).timeout 
			
			await resolve_die_interaction(p_die, e_die, p_roll, e_roll, p_dice_pool, e_dice_pool)
			await get_tree().create_timer(0.4).timeout 
			
		if active_player_dice_ui:
			active_player_dice_ui.queue_free()
		if active_enemy_dice_ui:
			active_enemy_dice_ui.queue_free()
		
		if player_card_data != null:
			player_discard_pile.append(player_card_data)
		if enemy_card_data != null:
			enemy_discard_pile.append(enemy_card_data)
		
		clash_ended.emit()
		await animate_clash_return() 
		
	end_turn_and_prepare_next()

func end_turn_and_prepare_next():
	clashing_begin = false
	turn_count += 1
	
	for slot in player.speed_dice_container.get_children():
		slot.card_for_dice.clear()
		player.speed_dice_container.remove_child(slot)
		slot.queue_free()
		
	for slot in enemy.speed_dice_container.get_children():
		slot.chosen_card = null
		slot.viable_clashing_speed_dice.clear()
		enemy.speed_dice_container.remove_child(slot)
		slot.queue_free()
	if has_node("../dice_arrow"):
		get_node("../dice_arrow").visible = true
	
	player.speed_dice_container.visible = true
	enemy.speed_dice_container.visible = true
	player.collider.disabled = false
	enemy.collider.disabled = false
	player.emit_signal("mouse_exited_player_character", player)
	enemy.emit_signal("mouse_exited_enemy_character", enemy)
	emit_signal("back_to_normal")
	player_retained_defense.clear()
	enemy_retained_defense.clear()
	if enemy.current_energy < enemy.character_stats.max_energy:
		enemy.current_energy += 1
	if player.current_energy < player.character_stats.max_energy:
		player.current_energy += 1
	player.set_up_energy_display()
	player.energy_container.visible = true
	enemy.set_up_energy_display()
	enemy.energy_container.visible = true
	player.setup_speed_dice()
	enemy.setup_speed_dice()
	draw_card()
	set_up_enemy_hand()
	enemy.set_up_attack(player_team)
	if enemy.is_dead():
		emit_signal("enemy_defeated")
		await wait(0.2)
		battle_won()
	if player.is_dead():
		emit_signal("player_defeated")
		await wait(0.2)
		battle_lost()
	else:
		ui_manager.turncounter.visible = true
		turn_count_being_shown = true
		ui_manager.show_turn_count(turn_count)
		ui_manager.refresh_information()
		await wait(1.1)
		turn_count_being_shown = false

func resolve_die_interaction(p_die, e_die, p_roll: int, e_roll: int, p_pool: Array, e_pool: Array):
	if p_die == null and e_die == null:
		return
	
	if e_die == null:
		var p_category = get_die_category(p_die["type"])
		if p_category == "Offense":
			if not enemy_retained_defense.is_empty():
				var substituted_e_die = enemy_retained_defense.pop_front()
				var substituted_e_roll = randi_range(substituted_e_die.min_roll, substituted_e_die.max_roll)
				if active_enemy_dice_ui:
					active_enemy_dice_ui.queue_free()
				active_enemy_dice_ui = spawn_dice_overlay(enemy, substituted_e_die.type)
				die_rolled.emit("enemy", substituted_e_die.type, substituted_e_roll)
				var temp_e_pool = [substituted_e_die] 
				animate_dice_roll(active_enemy_dice_ui, substituted_e_roll, substituted_e_die.min_roll, substituted_e_die.max_roll)
				await get_tree().create_timer(0.4).timeout
				await resolve_die_interaction(p_die, substituted_e_die, p_roll, substituted_e_roll, p_pool, temp_e_pool)
				return
			else:
				emit_signal("attack_thrown", player, p_die["type"])
				emit_signal("attack_landed", enemy)
				await play_strike_animation(player, enemy, p_die["type"])
				apply_damage(enemy, p_roll, p_die["type"])
				apply_stagger_damage(enemy, p_roll)
				ui_manager.refresh_information()
				if not p_pool.is_empty(): p_pool.pop_front()
		elif p_category == "Defense":
			if not p_pool.is_empty(): p_pool.pop_front() 
			return

	if p_die == null:
		var e_category = get_die_category(e_die["type"])
		if e_category == "Offense":
			if not player_retained_defense.is_empty():
				var substituted_p_die = player_retained_defense.pop_front()
				var substituted_p_roll = randi_range(substituted_p_die.min_roll, substituted_p_die.max_roll)
				if active_player_dice_ui:
					active_player_dice_ui.queue_free()
				active_player_dice_ui = spawn_dice_overlay(player, substituted_p_die.type)
				die_rolled.emit("player", substituted_p_die.type, substituted_p_roll)
				animate_dice_roll(active_player_dice_ui, substituted_p_roll, substituted_p_die.min_roll, substituted_p_die.max_roll)
				var temp_p_pool = [substituted_p_die]
				await get_tree().create_timer(0.4).timeout
				await resolve_die_interaction(substituted_p_die, e_die, substituted_p_roll, e_roll, temp_p_pool, e_pool)
				return
			else:
				emit_signal("attack_thrown", enemy, e_die["type"])
				emit_signal("attack_landed", player)
				await play_strike_animation(enemy, player, e_die["type"])
				apply_damage(player, e_roll, e_die["type"])
				apply_stagger_damage(player, e_roll)
				ui_manager.refresh_information()
				if not e_pool.is_empty(): e_pool.pop_front()
		elif e_category == "Defense":
			if not e_pool.is_empty(): e_pool.pop_front()
			return
		
	if p_roll > e_roll:
		await execute_clash_win(player, enemy, p_die, e_die, p_roll, e_roll, p_pool, e_pool)
		ui_manager.refresh_information()
	elif e_roll > p_roll:
		await execute_clash_win(enemy, player, e_die, p_die, e_roll, p_roll, e_pool, p_pool)
		ui_manager.refresh_information()
	else:
		await play_clash_parry_effect(player, enemy)
		p_pool.remove_at(0)
		e_pool.remove_at(0)

func execute_clash_win(winner, loser, win_die, lose_die, win_roll : int, lose_roll : int, win_pool : Array, lose_pool : Array):
	var win_category
	var lose_category
	if win_die != null:
		win_category = get_die_category(win_die["type"])
	if lose_die != null:
		lose_category = get_die_category(lose_die["type"])
	
	var winner_is_player : bool = (winner == player)

	if win_category == "Offense" and lose_category == "Offense":
		emit_signal("attack_thrown", winner, win_die["type"])
		emit_signal("attack_landed", loser)
		await play_strike_animation(winner, loser, win_die["type"])
		apply_damage(loser, win_roll, win_die["type"])
		apply_stagger_damage(loser, win_roll)
		lose_pool.remove_at(0)
		win_pool.remove_at(0)
	
	elif win_category == "Offense" and lose_category == "Defense":
		if lose_die["type"] == 3: # Block
			emit_signal("attack_thrown", winner, win_die["type"])
			emit_signal("attack_landed", loser)
			await play_defense_animation(loser, winner, "block")
			var block_damage = win_roll - lose_roll
			apply_damage(loser, block_damage, win_die["type"])
			apply_stagger_damage(loser, block_damage)
			win_pool.remove_at(0)
		elif lose_die["type"] == 4: # Evade
			emit_signal("attack_thrown", winner, win_die["type"])
			emit_signal("attack_landed", loser)
			await play_strike_animation(loser, winner, win_die["type"])
			apply_damage(loser, win_roll, win_die["type"])
			apply_stagger_damage(loser, win_roll)
			win_pool.remove_at(0)
		if winner_is_player:
			if enemy_retained_defense.is_empty():
				lose_pool.remove_at(0)
			else:
				enemy_retained_defense.remove_at(0)
		else:
			if player_retained_defense.is_empty():
				lose_pool.remove_at(0)
			else:
				player_retained_defense.remove_at(0)
				
	
	elif win_category == "Defense" and lose_category == "Offense":
		if win_die["type"] == 3: # Block
			emit_signal("attack_thrown", loser, lose_die["type"])
			emit_signal("block_triggered", winner)
			await play_defense_animation(loser, winner, "block")
			var block_damage = win_roll - lose_roll
			apply_stagger_damage(loser, block_damage)
			win_pool.remove_at(0)
		elif win_die["type"] == 4: # Evade
			SoundEffectManager.play_sfx("back_off", "SFX", 0.0, 1.0, 0.45)
			emit_signal("attack_thrown", loser, lose_die["type"])
			emit_signal("evade_triggered", winner)
			await play_defense_animation(loser, winner, "evade")
			evade_triggered.emit(winner)
			win_pool.remove_at(0)
			if winner_is_player:
				player_retained_defense.append(win_die)
			else:
				enemy_retained_defense.append(win_die)
		lose_pool.remove_at(0) 

	elif win_category == "Defense" and lose_category == "Defense":
		if win_die["type"] == 3: # Block
			if lose_die["type"] == 3:
				emit_signal("block_triggered", loser)
			if lose_die["type"] == 4:
				emit_signal("evade_triggered", loser)
			emit_signal("block_triggered", winner)
			await play_defense_animation(loser, winner, "block")
			apply_stagger_damage(loser, win_roll)
			win_pool.remove_at(0)
		elif win_die["type"] == 4: # Evade
			if lose_die["type"] == 3:
				emit_signal("block_triggered", loser)
			if lose_die["type"] == 4:
				emit_signal("evade_triggered", loser)
			emit_signal("evade_triggered", winner)
			await play_defense_animation(loser, winner, "evade")
			win_pool.remove_at(0)
			if winner_is_player:
				player_retained_defense.append(win_die)
			else:
				enemy_retained_defense.append(win_die)
		lose_pool.remove_at(0)


func apply_damage(target, base_damage: int, damage_type: int):
	if base_damage <= 0:
		return
		
	var target_type = "player" if target == player else "enemy"
	var multiplier = 1.0
	
	var char_resource = target.character_stats if "character_stats" in target else null
	if char_resource and char_resource is CHARACTERS:
		var resistance_enum_value = char_resource.Resistance.Normal
		match damage_type:
			DieType.SLASH: resistance_enum_value = char_resource.slash_resistance
			DieType.BLUNT: resistance_enum_value = char_resource.blunt_resistance
			DieType.PIERCE: resistance_enum_value = char_resource.pierce_resistance
					
		if RESISTANCE_MULTIPLIERS.has(resistance_enum_value):
			multiplier = RESISTANCE_MULTIPLIERS[resistance_enum_value]
		if target.has_method("is_staggered") and target.is_staggered():
			multiplier = 2.0
		
	var final_damage = roundi(base_damage * multiplier)
	
	if target.has_method("take_damage"):
		target.take_damage(final_damage)
	else:
		target.current_health = max(0, target.current_health - final_damage)
		
	hit_landed.emit(target_type, final_damage, 0, damage_type)

func apply_stagger_damage(target, stagger_damage: int):
	if stagger_damage <= 0:
		return
		
	if target.has_method("is_staggered") and target.is_staggered():
		return
		
	var target_type = "player" if target == player else "enemy"
	var multiplier = 1.0
	
	var final_stagger = roundi(stagger_damage * multiplier)
	
	if target.has_method("take_stagger_damage"):
		target.take_stagger_damage(final_stagger)
	elif "stagger" in target:
		target.stagger = max(0, target.stagger - final_stagger)
		
	hit_landed.emit(target_type, 0, final_stagger, "Stagger")

func get_die_category(die_type: int) -> String:
	match die_type:
		DieType.SLASH, DieType.PIERCE, DieType.BLUNT:
			return "Offense"
		DieType.BLOCK, DieType.EVADE:
			return "Defense"
		_:
			return "Offense"

func space_bar_pressed():
	battle_turn()

func restart_battle():
	turn_count = 1
	turn_count_being_shown = true
	player.reset_for_battle()
	for child in $"../EnemyTeamContainer/Control".get_children():
		$"../EnemyTeamContainer/Control".remove_child(child)
		child.queue_free()
	_clear_player_hand()
	_clear_enemy_hand()
	start_battle()

func _clear_player_hand() -> void:
	for card in card_manager.get_children():
		player_hand.remove_card_from_hand(card)
	player_battle_deck.clear()


func _clear_enemy_hand() -> void:
	enemy_battle_deck.clear()
	enemy_cards_in_hand.clear()

func left_mouse_clicked():
	if turn_count_being_shown:
		turn_count_being_shown = false
		ui_manager.turncounter.visible = false

func wait(wait_time):
	var timer = get_tree().create_timer(wait_time)
	await timer.timeout

func animate_clash_approach():
	emit_signal("approaching")
	var tween = create_tween().set_parallel(true)
	var player_target = Vector2(player_global_home.x, player_global_home.y)
	var enemy_target = Vector2(enemy_global_home.x, enemy_global_home.y)
	if !player.is_currently_staggered and !enemy.is_currently_staggered:
		if !is_one_sided_attack_enemy:
			tween.tween_property(player, "global_position", Vector2(((player_target.x + enemy_target.x)/2) - CLASH_SEPERATION, player_target.y), 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		if !is_one_sided_attack_player:
			tween.tween_property(enemy, "global_position", Vector2(((player_target.x + enemy_target.x)/2) + CLASH_SEPERATION, enemy_target.y), 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	if player.is_currently_staggered or is_one_sided_attack_enemy:
		tween.tween_property(enemy, "global_position", Vector2(player_target.x * 2 + CLASH_SEPERATION, enemy_target.y), 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	if enemy.is_currently_staggered or is_one_sided_attack_player:
		tween.tween_property(player, "global_position", Vector2(enemy_target.x - (CLASH_SEPERATION * 2), player_target.y), 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await tween.finished
	emit_signal("against_each_other")

func animate_clash_return():
	emit_signal("going_backwards")
	var back_audio_player = AudioStreamPlayer.new()
	back_audio_player.stream = DODGE_SOUND
	back_audio_player.bus = "SFX" 
	back_audio_player.pitch_scale = 1.5
	back_audio_player.volume_db = -2.5
	get_tree().root.add_child(back_audio_player)
	back_audio_player.play(0.45)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(player, "global_position", player_global_home, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(enemy, "global_position", enemy_global_home, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await tween.finished

func play_strike_animation(attacker, defender, _strike_type: int):
	var tween = create_tween().set_parallel(false)
	var direction = -1 if attacker == player else 1
	
	tween.tween_property(attacker, "global_position", attacker.global_position + Vector2(-100 * direction, 0), 0.05)
	tween.tween_property(attacker, "global_position", attacker.global_position + Vector2(45 * direction, 0), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var def_tween = create_tween().set_parallel(true)
	def_tween.tween_property(defender, "global_position", defender.global_position + Vector2(-150 * direction, 0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	def_tween.tween_property(defender, "modulate", Color.RED, 0.05)
	
	var settle_tween = create_tween().set_parallel(true)
	settle_tween.tween_property(attacker, "global_position", attacker.global_position, 0.15)
	settle_tween.tween_property(defender, "global_position", defender.global_position, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	settle_tween.tween_property(defender, "modulate", Color.WHITE, 0.15)
	
	await settle_tween.finished
	
func play_defense_animation(attacker, defender, type: String):
	var tween = create_tween()
	var direction = 1 if defender == player else -1
	if type == "evade":
		tween.tween_property(attacker, "global_position", attacker.global_position + Vector2(-100 * direction, 0), 0.05)
		tween.tween_property(attacker, "global_position", attacker.global_position + Vector2(45 * direction, 0), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		var def_tween = create_tween().set_parallel(true)
		def_tween.tween_property(defender, "global_position", defender.global_position + Vector2(-250 * direction, 0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		var settle_tween = create_tween().set_parallel(true)
		settle_tween.tween_property(attacker, "global_position", attacker.global_position, 0.15)
		settle_tween.tween_property(defender, "global_position", defender.global_position, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	elif type == "block":
		tween.tween_property(attacker, "global_position", attacker.global_position + Vector2(-100 * direction, 0), 0.05)
		tween.tween_property(attacker, "global_position", attacker.global_position + Vector2(45 * direction, 0), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		var def_tween = create_tween().set_parallel(true)
		def_tween.tween_property(defender, "global_position", defender.global_position + Vector2(-150 * direction, 0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		def_tween.tween_property(defender, "modulate", Color.BLUE, 0.05)
		
		var settle_tween = create_tween().set_parallel(true)
		settle_tween.tween_property(attacker, "global_position", attacker.global_position, 0.15)
		settle_tween.tween_property(defender, "global_position", defender.global_position, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		settle_tween.tween_property(defender, "modulate", Color.WHITE, 0.15)
	await tween.finished

func play_clash_parry_effect(player_character, enemy_character):
	SoundEffectManager.play_sfx("clash_tie", "SFX", 0.85)
	var tween = create_tween()
	tween.tween_property(player_character, "global_position", player_character.global_position + Vector2(-400, 0), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var def_tween = create_tween().set_parallel(true)
	def_tween.tween_property(enemy_character, "global_position", enemy_character.global_position + Vector2(400, 0), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	emit_signal("evade_triggered", player_character)
	emit_signal("evade_triggered", enemy_character)
	
	var settle_tween = create_tween().set_parallel(true)
	settle_tween.tween_property(player_character, "global_position", player_character.global_position, 0.15)
	settle_tween.tween_property(enemy_character, "global_position", enemy_character.global_position, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await tween.finished

func spawn_dice_overlay(target_node, die_type: int) -> Control:
	var dice_box = TextureRect.new()
	var label = Label.new()
	
	dice_box.texture = NORMAL_DICE
	dice_box.custom_minimum_size = Vector2(64, 64)
	dice_box.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dice_box.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	label.text = "?"
	label.name = "DiceLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 40)
	
	match die_type:
		0, 1, 2:
			label.add_theme_color_override("font_color", Color.from_string("#ff4d4d", Color.RED))
		3, 4:
			label.add_theme_color_override("font_color", Color.from_string("#3399ff", Color.BLUE))
			
	dice_box.add_child(label)
	
	get_parent().add_child(dice_box)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	if target_node.has_node("DiceAnchor"):
		var anchor = target_node.get_node("DiceAnchor") as Marker2D
		dice_box.global_position = anchor.global_position - Vector2(32, 32)
	else:
		dice_box.global_position = Vector2(target_node.global_position.x - 32, target_node.global_position.y - 120)
		
	dice_box.pivot_offset = dice_box.custom_minimum_size / 2.0
	return dice_box

func animate_dice_roll(dice_node: Control, final_value: int, min_val: int, max_val: int):
	if dice_node == null: return
	var label = dice_node.get_node("DiceLabel") as Label
	
	for i in range(6):
		label.text = str(randi_range(min_val, max_val))
		dice_node.scale = Vector2(1.2, 1.2)
		var t = create_tween()
		t.tween_property(dice_node, "scale", Vector2.ONE, 0.05)
		await get_tree().create_timer(0.05).timeout
		
	label.text = str(final_value)
	
	dice_node.scale = Vector2(1.5, 1.5)
	var final_tween = create_tween()
	final_tween.tween_property(dice_node, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func has_offensive_die(dice_pool: Array) -> bool:
	for die in dice_pool:
		if die.type != 3 and die.type != 4:
			return true
	return false

func battle_won():
	SoundEffectManager.play_sfx("win_effect", "SFX", -5.0)
	GlobalData.saved_character_data = player.character_stats
	var reward_stats = enemy.character_stats
	var item_id = reward_stats.id
	
	var pure_reward = {"resource": reward_stats, "quantity": reward_amount}
	GlobalData.reward_information = pure_reward.duplicate(true)
	
	if GlobalData.player_inventory.has(item_id):
		GlobalData.player_inventory[item_id]["quantity"] += reward_amount
	else:
		GlobalData.player_inventory[item_id] = pure_reward
		
	GlobalData.clear_level(current_level_id, current_floor_level)
	SceneTransition.change_scene("res://Scenes/win_screen.tscn", "fade")

func battle_lost():
	SoundEffectManager.play_sfx("lose_jingle", "SFX", -5.0)
	GlobalData.saved_character_data = player.character_stats
	var lost_items = enemy.character_stats
	var item_id = lost_items.id
	var loss_amount = reward_amount

	var pure_loss = {"resource": lost_items, "quantity": loss_amount}
	GlobalData.reward_information = pure_loss.duplicate(true) 

	if GlobalData.player_inventory.has(item_id):
		GlobalData.player_inventory[item_id]["quantity"] -= loss_amount
		if GlobalData.player_inventory[item_id]["quantity"] <= 0:
			GlobalData.player_inventory.erase(item_id)
	else:
		pass
	
	SceneTransition.change_scene("res://Scenes/lose_screen.tscn", "fade")
