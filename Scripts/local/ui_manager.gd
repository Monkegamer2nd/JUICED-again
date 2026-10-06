extends Node

const DEFAULT_SPEED = 0.13
const CARD_DISPLAY_LOWERED_VALUE = 140
const DAMAGE_NUMBER_SCENE = preload("res://Prefabs/damage_number.tscn")

@onready var player : MAIN_PLAYER = $"../PlayerTeamContainer/Control/Player"
@onready var player_card_display = $"../CanvasLayer/UI/PlayerCardDisplay"
@onready var enemy_card_display = $"../CanvasLayer/UI/EnemyCardDisplayed"
@onready var player_information : VBoxContainer = $"../CanvasLayer/UI/PlayerInformation"
@onready var enemy_information : VBoxContainer = $"../CanvasLayer/UI/EnemyInformation"
@onready var turncounter : Control = $"../CanvasLayer/UI/TurnCounter"

var player_card_found = null
var enemy = null

func _ready() -> void:
	player.connect("mouse_enetered_player_area", hovering_over_player_speed_dice)
	player.connect("mouse_exited_player_area", hovering_off_player_speed_dice)
	player.connect("mouse_entered_player_character", hovering_over_player)
	player.connect("mouse_exited_player_character", hovering_off_player)
	$"../BattleManager".hit_landed.connect(_on_hit_landed)

func setup_enemy_ui(spawned_enemy) -> void:
	enemy = spawned_enemy
	enemy.connect("mouse_enetered_enemy_area", hovering_over_enemy_speed_dice)
	enemy.connect("mouse_exited_enemy_area", hovering_off_enemy_speed_dice)
	enemy.connect("mouse_entered_enemy_character", hovering_over_enemy)
	enemy.connect("mouse_exited_enemy_character", hovering_off_enemy)

func hovering_over_player_speed_dice(speed_dice):
	card_display_show(speed_dice, true)
	for target in speed_dice.viable_clashing_speed_dice:
		card_display_show(target, true)

func hovering_off_player_speed_dice(speed_dice):
	card_display_show(speed_dice, false)
	if !speed_dice.viable_clashing_speed_dice.is_empty():
		card_display_show(speed_dice.viable_clashing_speed_dice[0], false)

func hovering_over_enemy_speed_dice(speed_dice):
	var targets_index = speed_dice.current_target_index
	var container = player.speed_dice_container
	card_display_show(speed_dice, true)
	
	if targets_index >= 0 and targets_index < container.get_child_count():
		var target_dice = container.get_child(targets_index)
	
		if target_dice and !target_dice.viable_clashing_speed_dice.is_empty():
			if speed_dice == target_dice.viable_clashing_speed_dice[0]:
				card_display_show(target_dice, true)

func hovering_off_enemy_speed_dice(speed_dice):
	var targets_index = speed_dice.current_target_index
	var container = player.speed_dice_container
	card_display_show(speed_dice, false)
	
	if targets_index >= 0 and targets_index < container.get_child_count():
		var target_dice = container.get_child(targets_index)
	
		if target_dice and !target_dice.viable_clashing_speed_dice.is_empty():
			if speed_dice == target_dice.viable_clashing_speed_dice[0]:
				card_display_show(target_dice, false)

func _on_hit_landed(target_type: String, health_damage: int, stagger_damage: int, _damage_type) -> void:
	var base_pos: Vector2 = Vector2.ZERO
	if target_type == "player" and player.damage_anchor:
		base_pos = player.damage_anchor.global_position
	elif target_type == "enemy" and enemy.damage_anchor:
		base_pos = enemy.damage_anchor.global_position
	
	if health_damage > 0:
		var health_popup = DAMAGE_NUMBER_SCENE.instantiate()
		add_child(health_popup)
		var hp_spawn_pos = base_pos + Vector2(0, -30) 
		health_popup.setup(health_damage, Color.RED, hp_spawn_pos)
	
	if stagger_damage > 0:
		var stagger_popup = DAMAGE_NUMBER_SCENE.instantiate()
		add_child(stagger_popup)
		var stagger_spawn_pos = base_pos + Vector2(0, 10) 
		stagger_popup.setup(stagger_damage, Color.YELLOW, stagger_spawn_pos)

func hovering_over_player(character):
	show_information(character, true)

func hovering_off_player(character):
	show_information(character,false)

func hovering_over_enemy(character):
	show_information(character, true)

func hovering_off_enemy(character):
	show_information(character, false)

func show_information(owner_character, hovered : bool):
	if owner_character == player:
		if hovered:
			player_information.set_the_information(owner_character.character_stats.max_health, owner_character.current_health, owner_character.character_stats.max_stagger, owner_character.current_stagger, owner_character.character_stats.Resistance.keys()[owner_character.character_stats.slash_resistance], owner_character.character_stats.Resistance.keys()[owner_character.character_stats.pierce_resistance], owner_character.character_stats.Resistance.keys()[owner_character.character_stats.blunt_resistance])
			var tween = get_tree().create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(player_information, "position", Vector2(player_information.starting_position.x, player_information.starting_position.y + 104), 0.15)
		else:
			var tween = get_tree().create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(player_information, "position", Vector2(player_information.starting_position.x, player_information.starting_position.y), 0.15)
	if owner_character == enemy:
		if hovered:
			enemy_information.set_the_information(owner_character.character_stats.max_health, owner_character.current_health, owner_character.character_stats.max_stagger, owner_character.current_stagger, owner_character.character_stats.Resistance.keys()[owner_character.character_stats.slash_resistance], owner_character.character_stats.Resistance.keys()[owner_character.character_stats.pierce_resistance], owner_character.character_stats.Resistance.keys()[owner_character.character_stats.blunt_resistance])
			var tween = get_tree().create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(enemy_information, "position", Vector2(enemy_information.starting_position.x, enemy_information.starting_position.y + 104), 0.15)
		else:
			var tween = get_tree().create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(enemy_information, "position", Vector2(enemy_information.starting_position.x, enemy_information.starting_position.y), 0.15)


func card_display_show(speed_dice, hovered):
	if speed_dice.dice_owner == player:
		var has_card = !speed_dice.card_for_dice.is_empty() and speed_dice.card_for_dice[0].card_data != null
		if hovered:
			if has_card:
				player_card_display.get_child(0).setup_labels(speed_dice.card_for_dice[0].card_data)
				player_card_display.get_child(0).setup_dice(speed_dice.card_for_dice[0].card_data)
				player_card_display.get_child(0).setup_dice_information(speed_dice.card_for_dice[0].card_data)
				var tween = get_tree().create_tween()
				tween.set_trans(Tween.TRANS_QUAD)
				tween.set_ease(Tween.EASE_OUT)
				tween.tween_property(player_card_display, "position", Vector2(player_card_display.starting_position.x, player_card_display.starting_position.y + CARD_DISPLAY_LOWERED_VALUE), DEFAULT_SPEED)
		else:
			var tween = get_tree().create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(player_card_display, "position", Vector2(player_card_display.starting_position.x, player_card_display.starting_position.y), DEFAULT_SPEED)
			player_card_display.get_child(0).clear_information()
			
	if speed_dice.dice_owner == enemy:
		if hovered:
			if speed_dice.chosen_card != null:
				enemy_card_display.get_child(0).setup_labels(speed_dice.chosen_card)
				enemy_card_display.get_child(0).setup_dice(speed_dice.chosen_card)
				enemy_card_display.get_child(0).setup_dice_information(speed_dice.chosen_card)
				var tween = get_tree().create_tween()
				tween.set_trans(Tween.TRANS_QUAD)
				tween.set_ease(Tween.EASE_OUT)
				tween.tween_property(enemy_card_display, "position", Vector2(enemy_card_display.starting_position.x, enemy_card_display.starting_position.y + CARD_DISPLAY_LOWERED_VALUE), DEFAULT_SPEED)
		else:
			var tween = get_tree().create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(enemy_card_display, "position", Vector2(enemy_card_display.starting_position.x, enemy_card_display.starting_position.y), DEFAULT_SPEED)
			enemy_card_display.get_child(0).clear_information()

func show_turn_count(value):
	turncounter.get_node("TurnCount").text = str("TURN ", value)
	turncounter.get_node("TurnCountAnimation").play("turncount")
	await wait(0.5)
	turncounter.get_node("TurnCountAnimation").play("turncountfadeaway")

func wait(wait_time):
	var timer = get_tree().create_timer(wait_time)
	await timer.timeout

func refresh_information():
	player_information.set_the_information(player.character_stats.max_health, player.current_health, player.character_stats.max_stagger, player.current_stagger, player.character_stats.Resistance.keys()[player.character_stats.slash_resistance], player.character_stats.Resistance.keys()[player.character_stats.pierce_resistance], player.character_stats.Resistance.keys()[player.character_stats.blunt_resistance])
	enemy_information.set_the_information(enemy.character_stats.max_health, enemy.current_health, enemy.character_stats.max_stagger, enemy.current_stagger, enemy.character_stats.Resistance.keys()[enemy.character_stats.slash_resistance], enemy.character_stats.Resistance.keys()[enemy.character_stats.pierce_resistance], enemy.character_stats.Resistance.keys()[enemy.character_stats.blunt_resistance])

func force_lower_card_display():
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(player_card_display, "position", Vector2(player_card_display.starting_position.x, player_card_display.starting_position.y), DEFAULT_SPEED)
	player_card_display.get_child(0).clear_information()
	var tween2 = get_tree().create_tween()
	tween2.set_trans(Tween.TRANS_QUAD)
	tween2.set_ease(Tween.EASE_OUT)
	tween2.tween_property(enemy_card_display, "position", Vector2(enemy_card_display.starting_position.x, enemy_card_display.starting_position.y), DEFAULT_SPEED)
	enemy_card_display.get_child(0).clear_information()
