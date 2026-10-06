extends TextureRect

const DICE = preload("res://Prefabs/dice.tscn")
const DICE_SEPERATION := 5
const DICE_SMALL_SEPERATION := 0

@onready var card_name: Label = $Move_Name
@onready var card_cost: Label = $Card_Cost
@onready var dice_container: HBoxContainer = $Dice_Container
var dice_data = null 
var card_data = null
var energy_cost
var starting_position

func _ready() -> void:
	starting_position = position
	energy_cost = card_data.energy_cost
	setup_labels()
	setup_dice()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	pass

func _on_mouse_exited() -> void:
	pass

func set_dice(new_dice) -> void:
	dice_data = new_dice

func setup_labels():
	self.texture = card_data.card_art
	card_name.text = card_data.id
	card_cost.text = str(card_data.energy_cost)

func setup_dice():
	for die in card_data.dice_list:
		var dice = DICE.instantiate() as DICE_UI
		dice_container.add_child(dice)
		dice.setup(die["type"])
	
	if dice_container.get_child_count() == 4:
		dice_container.add_theme_constant_override("separation", DICE_SMALL_SEPERATION)
	else:
		dice_container.add_theme_constant_override("separation", DICE_SEPERATION)
