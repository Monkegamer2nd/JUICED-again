extends VBoxContainer

@onready var health : Label = $Health
@onready var stagger : Label = $Stagger
@onready var slash_resistance = $SlashResistance
@onready var pierce_resistance = $PierceResistance
@onready var blunt_resistance = $BluntResistance

var starting_position

func _ready() -> void:
	starting_position = self.position

func set_the_information(max_health, current_health, max_stagger, current_stagger, current_slash_resistance, current_pierce_resistance, current_blunt_resistance):
	health.text = str(current_health, "/", max_health)
	stagger.text = str(current_stagger, "/", max_stagger)
	slash_resistance.text = "Slash Resistance: " + current_slash_resistance
	pierce_resistance.text = "Pierce Resistance: " + current_pierce_resistance
	blunt_resistance.text = "Blunt Resistance: " + current_blunt_resistance
