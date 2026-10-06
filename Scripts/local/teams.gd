extends Control

const MAIN_MENU = "res://Scenes/main_menu.tscn"
const DECK_CARDS = preload("res://Prefabs/deck_card.tscn")
const COLLISION_MASK_CARD_INVENTORY = 16
const COLLISION_MASK_CARD = 4
const DEFAULT_SPEED = 0.1

@onready var deck_container = $DeckContainer
@onready var inventory = $ScrollContainer/GridContainer
@onready var player_health = $CharacterSheet/Health
@onready var player_stagger = $CharacterSheet/Stagger
@onready var player_slash_resistance = $CharacterSheet/SlashResistance
@onready var player_pierce_resistance = $CharacterSheet/PierceResistance
@onready var player_blunt_resistance = $CharacterSheet/BluntResistance
@onready var cards_display = $CardsDisplay

func _ready() -> void:
	$Back.pressed.connect(back_button_pressed)
	var slash_resistance_value = GlobalData.saved_character_data.Resistance.keys()[GlobalData.saved_character_data.slash_resistance]
	var pierce_resistance_value = GlobalData.saved_character_data.Resistance.keys()[GlobalData.saved_character_data.pierce_resistance]
	var blunt_resistance_value = GlobalData.saved_character_data.Resistance.keys()[GlobalData.saved_character_data.blunt_resistance]
	for card_item in GlobalData.saved_character_data.card_deck:
		var card_instance = DECK_CARDS.instantiate()
		card_instance.card_data = card_item
		card_instance.custom_minimum_size = Vector2(129*0.75, 186*0.75)
		deck_container.add_child(card_instance)
		card_instance.dice_container.scale = Vector2(0.75, 0.75) 
		card_instance.dice_container.position = Vector2(card_instance.position.x, card_instance.starting_position.y + 105)
		card_instance.card_name.add_theme_font_size_override("font_size", 12)
		card_instance.card_cost.add_theme_font_size_override("font_size", 9.5)
		card_instance.gui_input.connect(_on_deck_card_gui_input.bind(card_instance))
	for card_item in GlobalData.unlocked_combat_cards:
		var card_instance = DECK_CARDS.instantiate()
		card_instance.card_data = card_item
		card_instance.custom_minimum_size = Vector2(129*0.75, 186*0.75)
		inventory.add_child(card_instance)
		var card_area = card_instance.get_node("Area2D") 
		card_area.set_collision_layer_value(16, true)
		card_area.set_collision_layer_value(1, false)
		card_area.set_collision_mask_value(16, true)
		card_area.set_collision_mask_value(1, false)
		card_instance.dice_container.scale = Vector2(0.75, 0.75) 
		card_instance.dice_container.position = Vector2(card_instance.position.x, card_instance.starting_position.y + 105)
		card_instance.card_name.add_theme_font_size_override("font_size", 12)
		card_instance.card_cost.add_theme_font_size_override("font_size", 9.5)
		card_instance.gui_input.connect(_on_inventory_card_gui_input.bind(card_instance))
		card_instance.mouse_entered.connect(_on_card_mouse_entered.bind(card_instance))
	player_health.text = str("Max Health: ", GlobalData.saved_character_data.max_health)
	player_stagger.text = str("Max Stagger: ", GlobalData.saved_character_data.max_stagger)
	player_slash_resistance.text = "Slash Resistance: " + slash_resistance_value
	player_pierce_resistance.text = "Pierce Resistance: " + pierce_resistance_value
	player_blunt_resistance.text = "Blunt Resistance: " + blunt_resistance_value

func back_button_pressed():
	if !deck_container.get_child_count() <= 0:
		SceneTransition.change_scene(MAIN_MENU, "cloud")

func _on_inventory_card_gui_input(event: InputEvent, card_found: Control):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if deck_container.get_child_count() < 9:
				GlobalData.saved_character_data.card_deck.append(card_found.card_data)
				
				var card_instance = DECK_CARDS.instantiate()
				card_instance.card_data = card_found.card_data
				card_instance.custom_minimum_size = Vector2(129*0.75, 186*0.75)
				deck_container.add_child(card_instance)
				card_instance.dice_container.scale = Vector2(0.75, 0.75) 
				card_instance.dice_container.position = Vector2(card_instance.position.x, card_instance.starting_position.y + 105)
				card_instance.card_name.add_theme_font_size_override("font_size", 12)
				card_instance.card_cost.add_theme_font_size_override("font_size", 9.5)
				card_instance.gui_input.connect(_on_deck_card_gui_input.bind(card_instance))

func _on_deck_card_gui_input(event: InputEvent, card_found: Control) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var deck_array = GlobalData.saved_character_data.card_deck
		var deck_index = deck_array.find(card_found.card_data)
		
		if deck_index != -1:
			deck_array.remove_at(deck_index)
			card_found.queue_free()   

func raycast_check_for_card_right():
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
				return card_found
			else:
				return null

func _on_card_mouse_entered(hovered_card):
	cards_display.get_child(0).setup_labels(hovered_card.card_data)
	cards_display.get_child(0).setup_dice(hovered_card.card_data)
	cards_display.get_child(0).setup_dice_information(hovered_card.card_data)
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(cards_display, "position", Vector2(cards_display.position.x, cards_display.get_child(0).starting_position.y + 100), DEFAULT_SPEED)
