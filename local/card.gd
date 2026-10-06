extends Node2D
class_name CARDS

signal hovered
signal hovered_off

const SIZE = Vector2(300, 186)
const DICE = preload("res://Prefabs/dice.tscn")
const DICE_SEPERATION := 5
const DICE_SMALL_SEPERATION := 0

var targets = []
@export var card_data: CARD_DATA
@onready var skirt: CollisionShape2D = $Area2D/Skirt
@onready var resting: CollisionShape2D = $Area2D/Resting
@onready var card_art : TextureRect = $CardArt
@onready var card_name: Label = $CardArt/Move_Name
@onready var card_cost: Label = $CardArt/Card_Cost
@onready var dice_container: HBoxContainer = $CardArt/Dice_Container
@onready var card_information = $Card_Information
@onready var dice_info_container = $Card_Information/Dice_Info_Container
@onready var roll_information = $Card_Information/Roll_Container
var energy_cost
var card_type
var starting_position : Vector2
var card_information_starting_position : Vector2

func _ready() -> void:
	# All cards must be a child of CardManager or this will error
	get_parent().connect_card_signals(self)
	self.skirt.disabled = true
	card_art.texture = card_data.card_art
	card_information_starting_position = card_information.position
	energy_cost = card_data.energy_cost
	setup_labels()
	setup_dice()
	setup_dice_information()

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)

func setup_labels() -> void:
	card_name.text = card_data.id
	card_cost.text = str(card_data.energy_cost)

func setup_dice() -> void:
	for die in card_data.dice_list:
		var dice = DICE.instantiate() as DICE_UI
		dice_container.add_child(dice)
		dice.setup(die["type"])
	
	if dice_container.get_child_count() == 4:
		dice_container.add_theme_constant_override("separation", DICE_SMALL_SEPERATION)
	else:
		dice_container.add_theme_constant_override("separation", DICE_SEPERATION)
	
func setup_dice_information() -> void:
	for die in card_data.dice_list:
		var dice = DICE.instantiate() as DICE_UI
		dice_info_container.add_child(dice)
		dice.setup(die["type"])
		
		var new_label := Label.new()
		new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		new_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		new_label.custom_minimum_size = Vector2(32, 32)
		new_label.add_theme_constant_override("outline_size", 10)
		new_label.text = str(die.min_roll, " - ", die.max_roll)
		roll_information.add_child(new_label)
