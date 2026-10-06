extends Control

@onready var player : MAIN_PLAYER = $"../../PlayerTeamContainer/Control/Player"
@onready var card_manager = $"../../CardManager"
@onready var battle_manager = $"../../BattleManager"
@onready var input_manager = $"../../InputManager"
@onready var text_container : VBoxContainer = $TextContainer
@onready var dialogue_panel: PanelContainer = $TextContainer/DialogueContainer
@onready var dialogue_label: RichTextLabel = $TextContainer/DialogueContainer/RichTextLabel
@onready var position_1 : Marker2D = $Position1
@onready var position_2 : Marker2D = $Position2
@onready var position_3 : Marker2D = $Position3
@onready var position_4 : Marker2D = $Position4
@onready var position_5 : Marker2D = $Position5

@export var typing_speed: float = 0.03
@export var settle_distance: float = 45.0
@export var settle_duration: float = 0.15

var dialogue_lines: Array[String] = [
	"To start, hover your mouse over yourself!",
	"Your stats are shown in the top left corner. The first line is health, which is self-explanatory, Stagger is the second line, when that reaches zero you become staggered and vulnerable. (If there is no instruction on what to do, you can left click to go onto the next line!)",
	"Underneath those two are Resistances. There are three types of damage, Slash, Pierce, and Blunt. Each resistance is shown in your stats, Ineffective damage will deal half damage, Normal will deal full damage, and Effective damage will deal double damage!", 
	"Now, above yourself there is your energy, and your speed. Your speed determines if you can intercept your enemies' attacks or not, and will be noticed more as you face faster opponents.", 
	"Underneath your speed is your energy, energy is consumed when you use a card, and if you don't have enough energy to play a card then you can forget about using it. Each turn you gain ONE energy back.", 
	"Now, hover over one of the cards in your deck.", 
	"As you can notice, the side panel has the die listed on the card, the side panel shows what each dice on your card will roll, and their types, Slash, Pierce, Blunt, Block, and Evade.", 
	"You can also hover over me. And show my stats too, hover over MY speed and see that card I've chosen to attack with and which speed I've chosen to use for said card, which will be more relevant as you climb higher and higher up", 
	"Select your speed with a left click, and then reach down and drag a card onto MY speed, this will start a clash when you begin the turn", 
	"On the top will show each card in the clash when you hover over the clashing speeds. Clashing works by rolling the die on your cards, if you get a greater value than your opponent, you win, otherwise you lose.", 
	"There are some special scenarios as well, Defense die never clash unless against an Offensive die, but don't worry, even if they don't clash, each defense die is retained until the end of the round. And Evade dice are only lost upon losing a clash; they persist until they lose a clash or the end of the round. And you and your opponent can also attack one sidedly too assuming the enemy has no attack to clash with", 
	"To begin the turn and start a clash, just press the space bar. Remember you can pause by pressing the P key during any fight."
]

var current_line_index: int = 0
var original_position: Vector2
var active_tween: Tween
var no_clicking_only_hover : bool

func _ready() -> void:
	player.connect("mouse_entered_player_character", mouse_hovered_over_player)
	battle_manager.connect("enemies_instantiated", connect_enemy_signals)
	input_manager.connect("left_mouse_button_released", check_if_card_clash)
	input_manager.connect("space_bar_pressed", turn_started)
	original_position = text_container.position
	show_line_start(0)
	await get_tree().process_frame
	for card in card_manager.get_children():
		card.connect("hovered", mouse_hovered_over_card)

func connect_enemy_signals(enemy):
	enemy.connect("mouse_entered_enemy_character", mouse_hovered_over_enemy)

func _input(event):
	if !no_clicking_only_hover:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				advance_dialogue()

func advance_dialogue() -> void:
	current_line_index += 1
	if current_line_index < dialogue_lines.size():
		show_line(current_line_index)
	else:
		dialogue_panel.visible = false

func show_line(index: int) -> void:
	dialogue_panel.visible = true
	
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		
	dialogue_label.text = dialogue_lines[index]
	dialogue_label.visible_ratio = 0.0
	
	active_tween = create_tween().set_parallel(true)
		
	if index <= 2:
		no_clicking_only_hover = false
		active_tween.tween_property(text_container, "position", position_1.position, settle_duration)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	elif index <= 4:
		no_clicking_only_hover = false
		active_tween.tween_property(text_container, "position", position_2.position, settle_duration)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	elif index == 5:
		no_clicking_only_hover = true
		active_tween.tween_property(text_container, "position", position_3.position, settle_duration)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	elif index == 6:
		no_clicking_only_hover = false
		active_tween.tween_property(text_container, "position", position_3.position, settle_duration)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	elif index == 7:
		no_clicking_only_hover = true
		active_tween.tween_property(text_container, "position", position_4.position, settle_duration)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	elif index == 9:
		no_clicking_only_hover = false
		active_tween.tween_property(text_container, "position", position_5.position, settle_duration)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	elif index == 11:
		no_clicking_only_hover = true
		active_tween.tween_property(text_container, "position", position_5.position, settle_duration)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
	var duration_to_type = dialogue_lines[index].length() * typing_speed
	active_tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration_to_type)\
		.set_trans(Tween.TRANS_LINEAR)

func show_line_start(index: int) -> void:
	dialogue_panel.visible = true
	no_clicking_only_hover = true
	
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		
	dialogue_label.text = dialogue_lines[index]
	dialogue_label.visible_ratio = 0.0
	
	text_container.modulate.a = 0.0
	text_container.position.y = original_position.y - settle_distance
	
	active_tween = create_tween().set_parallel(true)
	
	active_tween.tween_property(text_container, "modulate:a", 1.0, settle_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
	active_tween.tween_property(text_container, "position:y", original_position.y, settle_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	var duration_to_type = dialogue_lines[index].length() * typing_speed
	active_tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration_to_type)\
		.set_trans(Tween.TRANS_LINEAR)

func mouse_hovered_over_player(_player):
	if current_line_index < 1:
		advance_dialogue()

func mouse_hovered_over_card(_card):
	if current_line_index == 5:
		advance_dialogue()

func mouse_hovered_over_enemy(_enemy):
	if current_line_index == 7:
		advance_dialogue()

func check_if_card_clash():
	for speed_dice in player.speed_dice_container.get_children():
		if !speed_dice.viable_clashing_speed_dice.is_empty():
			if current_line_index == 8:
				advance_dialogue()

func turn_started():
	current_line_index = 11
	text_container.visible = false
