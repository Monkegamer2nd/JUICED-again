extends TextureRect
class_name CARD_DISPLAY

const SIZE = Vector2(300, 186)
const DICE = preload("res://Prefabs/dice.tscn")
const DICE_SEPERATION := 5
const DICE_SMALL_SEPERATION := 0

@onready var card_name: Label = $Move_Name
@onready var card_cost: Label = $Card_Cost
@onready var dice_container: HBoxContainer = $Dice_Container
@onready var dice_information_container = $Card_Information/Dice_Info_Container
@onready var roll_information = $Card_Information/Roll_Container
var card_type
var starting_position : Vector2

func _ready() -> void:
	starting_position = position

func setup_labels(card_data) -> void:
	self.texture = card_data.card_art
	card_name.text = card_data.id
	card_cost.text = str(card_data.energy_cost)

func setup_dice(card_data) -> void:
	for child in dice_container.get_children():
		dice_container.remove_child(child)
		child.queue_free()
	
	for die in card_data.dice_list:
		var dice = DICE.instantiate() as DICE_UI
		dice_container.add_child(dice)
		dice.setup(die["type"])
	
	if dice_container.get_child_count() == 4:
		dice_container.add_theme_constant_override("separation", DICE_SMALL_SEPERATION)
	else:
		dice_container.add_theme_constant_override("separation", DICE_SEPERATION)

func clear_information() -> void:
	card_name.text = ""
	card_cost.text = ""
	for child in dice_container.get_children():
		child.queue_free()

func setup_dice_information(card_data) -> void:
	for child in dice_information_container.get_children():
		child.queue_free()
	for child in roll_information.get_children():
		child.queue_free()
	
	for die in card_data.dice_list:
		var dice = DICE.instantiate() as DICE_UI
		dice_information_container.add_child(dice)
		dice.setup(die["type"])
		
		var new_label := Label.new()
		new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		new_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		new_label.custom_minimum_size = Vector2(32, 32)
		new_label.add_theme_constant_override("outline_size", 10)
		new_label.text = str(die.min_roll, " - ", die.max_roll)
		roll_information.add_child(new_label)
