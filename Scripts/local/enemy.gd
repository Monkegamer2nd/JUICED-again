extends Node2D
class_name ENEMY

signal mouse_enetered_enemy_area
signal mouse_exited_enemy_area
signal mouse_entered_enemy_character
signal mouse_exited_enemy_character

const SPEED_DIE = preload("res://Prefabs/speed_dice.tscn")
const ENERGY_SCENE = preload("res://Prefabs/energy.tscn")
const SPEED_DIE_LARGER = 1.07
const SPEED_DIE_DEFAULT = 1.0
const DEFAULT_SPEED = 0.1

@export var character_stats : CHARACTERS
@onready var speed_dice_container : HBoxContainer = $SpeedDiceContainer
@onready var energy_container : HBoxContainer = $EnergyContainer
@onready var collider = $Area2D/CollisionShape2D
@onready var damage_anchor = $DamageAnchor
@onready var animated_sprite = $Area2D/AnimatedSprite2D

var current_health : int
var current_energy : int
var current_stagger : int
var enemy_deck : Array = []
var is_currently_staggered : bool = false
var stagger_recovery_turn : int

var battle_manager
var card_display
var arrow_for_dice
var target_player
var target_speed_dice
var chosen_card
var hovering_over_enemy
var targetting : bool
var hovering_over_speed_dice
var all_units
var starting_position

func initialize_enemy(bm_ref, cd_ref, afd_ref) -> void:
	battle_manager = bm_ref
	card_display = cd_ref
	arrow_for_dice = afd_ref
	battle_manager.against_each_other.connect(battle_animation_manager.bind("against_each_other"))
	battle_manager.back_to_normal.connect(battle_animation_manager.bind("idle"))
	battle_manager.enemy_defeated.connect(battle_animation_manager.bind("defeat"))
	battle_manager.connect("approaching", check_if_one_sided_approach)
	battle_manager.connect("going_backwards", check_if_one_sided_back)
	battle_manager.connect("attack_landed", check_if_hurt)
	battle_manager.connect("attack_thrown", check_what_attack_type)
	battle_manager.connect("block_triggered", check_if_blocking)
	battle_manager.connect("evade_triggered", check_if_dodging)

func _ready() -> void:
	starting_position = position
	targetting = false
	hovering_over_speed_dice = false
	current_health = character_stats.max_health
	current_energy = character_stats.max_energy
	current_stagger = character_stats.max_stagger
	enemy_deck = character_stats.card_deck
	Events.card_aim_started.connect(_on_card_aim_started)
	Events.card_aim_ended.connect(_on_card_aim_ended)

func is_dead() -> bool:
	return current_health <= 0 

func is_staggered() -> bool:
	return is_currently_staggered

func take_damage(amount : int):
	current_health = max(0, current_health - amount)

func take_stagger_damage(amount):
	if is_currently_staggered:
		return
	
	current_stagger = max(0, current_stagger - amount)
	if current_stagger <= 0:
		trigger_stagger()
	
	
func trigger_stagger():
	stagger_recovery_turn = battle_manager.turn_count + 1
	is_currently_staggered = true
	SoundEffectManager.play_sfx("stagger_hit", "SFX")

func setup_speed_dice() -> void:
	for child in speed_dice_container.get_children():
		speed_dice_container.remove_child(child)
		child.queue_free()
	
	for i in range(character_stats.speed_dice_amount):
		var die = SPEED_DIE.instantiate() as SPEED_DICE_UI
		
		die.dice_hovered_on.connect(on_speed_dice_hovered)
		die.dice_hovered_off.connect(on_speed_dice_hovered_off)
		
		speed_dice_container.add_child(die)
		
		var roll = randi_range(character_stats.min_speed_roll, character_stats.max_speed_roll)
		
		die.set_value(roll)
		die.dice_owner = self
		die.hover_area.collision_layer = 4
		
		if battle_manager.turn_count > stagger_recovery_turn and is_currently_staggered:
			is_currently_staggered = false
			die.set_stagger_state(false)
			animated_sprite.play("idle")
			arrow_for_dice.visible = true
			current_stagger = character_stats.max_stagger
		elif is_currently_staggered:
			die.set_stagger_state(true)
			animated_sprite.play("staggered")
			arrow_for_dice.visible = false
	

func set_up_energy_display():
	for child in energy_container.get_children():
		energy_container.remove_child(child)
		child.queue_free()
	
	for i in range(character_stats.max_energy):
		var energy = ENERGY_SCENE.instantiate()
		energy_container.add_child(energy)
		
		energy.set_filled(i < current_energy)


func set_up_attack(player_team: Array) -> void:
	if !is_currently_staggered:
		var temporary_hand = battle_manager.enemy_cards_in_hand.duplicate()
		var cards_to_remove = []
		var wants_to_hoard: bool = false
		
		for card in temporary_hand:
			if card.energy_cost >= 3:
				wants_to_hoard = true
				break
			else:
				wants_to_hoard = false
		
		for speed_dice in speed_dice_container.get_children():
			var cards_available = []
			
			for card in temporary_hand:
				if card.energy_cost > current_energy:
					continue
					
				if wants_to_hoard and current_energy < 3 and card.energy_cost > 0:
					continue
					
				cards_available.append(card)
			
			if cards_available.is_empty():
				continue
			
			var local_chosen_card = cards_available[randi() % cards_available.size()]
			temporary_hand.erase(local_chosen_card) 
			cards_to_remove.append(local_chosen_card)
			chosen_card = local_chosen_card
			current_energy -= chosen_card.energy_cost
			target_player = player_team[randi() % player_team.size()]
			target_speed_dice = randi() % target_player.speed_dice_container.get_child_count()
			
			
			speed_dice.assign_action(local_chosen_card, target_player, target_speed_dice)
			
		for card in cards_to_remove:
			battle_manager.enemy_discard_pile.append(card)
			battle_manager.enemy_cards_in_hand.erase(card)
			
		all_units = player_team + battle_manager.enemy_team
		await get_tree().process_frame
		arrow_for_dice.redraw_all_arrows(all_units)
	


func on_speed_dice_hovered(speed_dice):
	hovering_over_speed_dice = true
	speed_dice_highlight(speed_dice, true)
	emit_signal("mouse_enetered_enemy_area", speed_dice)
		

func on_speed_dice_hovered_off(speed_dice):
	hovering_over_speed_dice = false
	speed_dice_highlight(speed_dice, false)
	emit_signal("mouse_exited_enemy_area", speed_dice)

func speed_dice_highlight(speed_dice, hovered):
	if hovered:
		var tween = get_tree().create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(speed_dice, "scale", Vector2(SPEED_DIE_LARGER, SPEED_DIE_LARGER), DEFAULT_SPEED)
	else:
		var tween = get_tree().create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(speed_dice, "scale", Vector2(SPEED_DIE_DEFAULT, SPEED_DIE_DEFAULT), DEFAULT_SPEED)

func _on_card_aim_started(_card: CARDS):
	targetting = true

func _on_card_aim_ended(_card: CARDS):
	targetting = false
	if hovering_over_enemy:
		emit_signal("mouse_entered_enemy_character", self)

func _on_area_2d_mouse_entered() -> void:
	hovering_over_enemy = true
	if !targetting:
		emit_signal("mouse_entered_enemy_character", self)


func _on_area_2d_mouse_exited() -> void:
	hovering_over_enemy = false
	if !targetting:
		emit_signal("mouse_exited_enemy_character", self)

func reset_for_battle():
	current_health = character_stats.max_health
	current_stagger = character_stats.max_stagger
	current_energy = character_stats.max_energy

func check_if_hurt(hurt):
	if hurt == self:
		battle_animation_manager("hurt")
		SoundEffectManager.play_sfx("hit", "SFX", -10.0)
	else:
		return

func check_what_attack_type(attacker, die_type):
	if attacker == self:
		if die_type == 0: # slash
			battle_animation_manager("slash")
			SoundEffectManager.play_sfx("throwing_attack", "SFX", -10.0)
		elif die_type == 1: # pierce
			battle_animation_manager("pierce")
			SoundEffectManager.play_sfx("throwing_attack", "SFX", -10.0)
		elif die_type == 2: # blunt
			battle_animation_manager("blunt")
			SoundEffectManager.play_sfx("throwing_attack", "SFX", -10.0)
	else:
		return

func check_if_blocking(blocker):
	if blocker == self:
		battle_animation_manager("block")
		SoundEffectManager.play_sfx("block_hit", "SFX" ,-10.0)
	else:
		return

func check_if_dodging(evader):
	if evader == self:
		battle_animation_manager("evade")
	else:
		return

func check_if_one_sided_approach():
	if !battle_manager.is_one_sided_attack_player:
		battle_animation_manager("approaching")
		if !character_stats.id == "Apple Cop":
			SoundEffectManager.play_sfx("running", "SFX", 20.0, 6.5, randf_range(0.0, 0.2), 0.5)
	else:
		return

func check_if_one_sided_back():
	if !battle_manager.is_one_sided_attack_player:
		battle_animation_manager("evade")
	else:
		return

func battle_animation_manager(animation_name : String):
	if !is_currently_staggered:
		if animated_sprite.sprite_frames.has_animation(animation_name):
			animated_sprite.play(animation_name)
	if animation_name == "hurt":
		animated_sprite.play("hurt")
