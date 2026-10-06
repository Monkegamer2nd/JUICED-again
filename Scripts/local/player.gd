class_name MAIN_PLAYER
extends Node2D

signal mouse_enetered_player_area
signal mouse_exited_player_area
signal mouse_entered_player_character
signal mouse_exited_player_character

const SPEED_DIE = preload("res://Prefabs/speed_dice.tscn")
const ENERGY_SCENE = preload("res://Prefabs/energy.tscn")
const SPEED_DIE_LARGER = 1.07
const SPEED_DIE_DEFAULT = 1.0
const DEFAULT_SPEED = 0.1
const SPEED_DICE_COLLISION_LAYER = 8

@export var character_stats : CHARACTERS
@onready var speed_dice_container : HBoxContainer = $SpeedDiceContainer
@onready var energy_container : HBoxContainer = $EnergyContainer
@onready var player_information : VBoxContainer = $"../../../CanvasLayer/UI/PlayerInformation"
@onready var card_display = $"../../../CanvasLayer/UI/PlayerCardDisplay"
@onready var collider = $Area2D/CollisionShape2D
@onready var battle_manager = $"../../../BattleManager"
@onready var animated_sprite = $Area2D/AnimatedSprite2D
@onready var damage_anchor = $DamageAnchor

var current_health : int
var current_stagger : int
var current_energy : int
var player_deck : Array = []

var targetting : bool
var hovering_over_speed_dice
var selected_speed_dice
var hovering_over_player
var is_currently_staggered : bool = false
var stagger_recovery_turn : int
var starting_position

func _ready() -> void:
	starting_position = position
	targetting = false
	hovering_over_player = false
	hovering_over_speed_dice = false
	current_health = character_stats.max_health
	current_stagger = character_stats.max_stagger
	current_energy = character_stats.max_energy
	player_deck = GlobalData.saved_character_data.card_deck.duplicate()
	Events.card_aim_started.connect(_on_card_aim_started)
	Events.card_aim_ended.connect(_on_card_aim_ended)
	battle_manager.against_each_other.connect(battle_animation_manager.bind("against_each_other"))
	battle_manager.back_to_normal.connect(battle_animation_manager.bind("idle"))
	battle_manager.player_defeated.connect(battle_animation_manager.bind("defeat"))
	battle_manager.connect("approaching", check_if_one_sided_approach)
	battle_manager.connect("going_backwards", check_if_one_sided_back)
	battle_manager.connect("attack_landed", check_if_hurt)
	battle_manager.connect("attack_thrown", check_what_attack_type)
	battle_manager.connect("block_triggered", check_if_blocking)
	battle_manager.connect("evade_triggered", check_if_dodging)

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
		die.hover_area.collision_layer = 8
		
		if battle_manager.turn_count > stagger_recovery_turn and is_currently_staggered:
			is_currently_staggered = false
			die.set_stagger_state(false)
			animated_sprite.play("idle")
			current_stagger = character_stats.max_stagger
		elif is_currently_staggered:
			die.set_stagger_state(true)
			animated_sprite.play("staggered")

func set_up_energy_display():
	for child in energy_container.get_children():
		energy_container.remove_child(child)
		child.queue_free()
	
	for i in range(character_stats.max_energy):
		var energy = ENERGY_SCENE.instantiate()
		energy_container.add_child(energy)
		
		energy.set_filled(i < current_energy)

func on_speed_dice_hovered(speed_dice):
	hovering_over_speed_dice = true
	if !targetting:
		speed_dice_highlight(speed_dice, true)
		emit_signal("mouse_enetered_player_area", speed_dice)

func on_speed_dice_hovered_off(speed_dice):
	hovering_over_speed_dice = false
	speed_dice_highlight(speed_dice, false)
	emit_signal("mouse_exited_player_area", speed_dice)

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
	if hovering_over_speed_dice:
		speed_dice_highlight(raycast_check_for_speed_dice(), true)
	if hovering_over_player:
		emit_signal("mouse_entered_player_character", self)

func speed_dice_selected(speed_dice):
	if !selected_speed_dice:
		speed_dice.select_highlight.visible = true
		selected_speed_dice = speed_dice
	else:
		selected_speed_dice.select_highlight.visible = false
		speed_dice.select_highlight.visible = true
		selected_speed_dice = speed_dice


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
  
func _on_area_2d_mouse_entered() -> void:
	hovering_over_player = true
	if !targetting:
		emit_signal("mouse_entered_player_character", self)

func _on_area_2d_mouse_exited() -> void:
	hovering_over_player = false
	if !targetting:
		emit_signal("mouse_exited_player_character", self)

func spend_energy_on_card(card_cost):
	max(0, current_energy - card_cost)

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
			SoundEffectManager.play_sfx("throwing_attack", "SFX",  -10.0)
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
		SoundEffectManager.play_sfx("block_hit", "SFX", -10.0)
	else:
		return

func check_if_dodging(evader):
	if evader == self:
		battle_animation_manager("evade")
		SoundEffectManager.play_sfx("back_off", "SFX", 5.0, 1.0, 4.5, 1.0)
	else:
		return

func check_if_one_sided_approach():
	if !battle_manager.is_one_sided_attack_enemy:
		battle_animation_manager("approaching")
		SoundEffectManager.play_sfx("running", "SFX", 30.0, 2.5, randf_range(0.0, 0.5), 0.5)
	else:
		return

func check_if_one_sided_back():
	if !battle_manager.is_one_sided_attack_enemy:
		battle_animation_manager("evade")
		SoundEffectManager.play_sfx("back_off", "SFX", 5.0, 1.0, 4.5, 1.0)
	else:
		return

func battle_animation_manager(animation_name : String):
	if !is_currently_staggered:
		if animated_sprite.sprite_frames.has_animation(animation_name):
			animated_sprite.play(animation_name)
	if animation_name == "hurt":
		animated_sprite.play("hurt")
