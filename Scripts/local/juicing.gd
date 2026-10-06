extends Control

const MAIN_MENU = "res://Scenes/main_menu.tscn"
const JUICING_REWARDS = "res://Scenes/fruitjuiced.tscn"
const COLLECTED_FRUIT = preload("res://Prefabs/collected_fruit.tscn")
const DECK_CARDS = preload("res://Prefabs/deck_card.tscn")
const COLLISION_MASK_FRUIT = 8

@onready var button_sprites = $Button
@onready var cloud_card = $Cloud
@onready var juiced_button = $JUICEButton
@onready var juicer_top = $JuicerTop
@onready var scroll_grid_container = $ScrollContainer/GridContainer
@onready var grid_container = $Cardfromfruitcontainer/GridContainer
@onready var card_information_container = $Cardfromfruitcontainer
var button_pressed : bool = false
var fruit_selected : bool = false
var fruit_in_the_juicer : Array = []
var ghost_inventory : Dictionary = {}
var card_information_container_starting_position : Vector2
var cloud_card_starting_position : Vector2

func _ready() -> void:
	card_information_container_starting_position = card_information_container.position
	cloud_card_starting_position = cloud_card.position
	$Back.pressed.connect(back_button_pressed)
	look_at_inventory()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			left_mouse_button_clicked()

func back_button_pressed():
	GlobalData.player_inventory = ghost_inventory.duplicate(true)
	SceneTransition.change_scene(MAIN_MENU, "cloud")

func look_at_inventory():
	for item_id in GlobalData.player_inventory:
		var fruit = COLLECTED_FRUIT.instantiate()
		scroll_grid_container.add_child(fruit)
		ghost_inventory = GlobalData.player_inventory.duplicate(true)
		fruit.set_up_name_and_amount(GlobalData.player_inventory[item_id]["resource"], GlobalData.player_inventory[item_id]["quantity"])
		fruit.fruit_data = GlobalData.player_inventory[item_id]["resource"]
		fruit.hovered_over.connect(fruit_hovered_over)
		fruit.hovered_off.connect(fruit_hovered_off)

func fruit_hovered_over(fruit):
	var tween = get_tree().create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CIRC)
	tween.tween_property(card_information_container, "position", Vector2(card_information_container_starting_position.x + 300, card_information_container_starting_position.y), 0.2)
	tween.tween_property(cloud_card, "position", Vector2(cloud_card_starting_position.x + 325, cloud_card_starting_position.y), 0.2)
	for child in grid_container.get_children():
		grid_container.remove_child(child)
		child.queue_free()
	
	for card in fruit.fruit_data.card_deck:
		var cards = DECK_CARDS.instantiate()
		cards.card_data = card
		cards.custom_minimum_size = Vector2(129*0.75, 186*0.75)
		grid_container.add_child(cards)
		cards.dice_container.scale = Vector2(0.75, 0.75) 
		cards.dice_container.position = Vector2(cards.position.x, cards.starting_position.y + 105)
		cards.card_name.add_theme_font_size_override("font_size", 12)
		cards.card_cost.add_theme_font_size_override("font_size", 12)

func fruit_hovered_off(_fruit):
	var tween = get_tree().create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.tween_property(card_information_container, "position", Vector2(card_information_container_starting_position.x, card_information_container_starting_position.y), 0.15)
	tween.tween_property(cloud_card, "position", Vector2(cloud_card_starting_position.x, cloud_card_starting_position.y), 0.15)

func _on_juice_button_mouse_entered() -> void:
	button_sprites.play("hovered")

func _on_juice_button_mouse_exited() -> void:
	button_sprites.play("unhovered")

func _on_juice_button_pressed() -> void:
	if fruit_selected:
		if !button_pressed:
			SoundEffectManager.play_sfx("metal_crush", "SFX", -7.5, 1.5, 0.25)
			button_sprites.play("pressed")
			juiced_button.position = Vector2(juiced_button.position.x, juiced_button.position.y + 5)
			var tween = get_tree().create_tween()
			tween.set_ease(Tween.EASE_IN)
			tween.set_trans(Tween.TRANS_BOUNCE)
			tween.tween_property(juicer_top, "position", Vector2(juicer_top.position.x, juicer_top.position.y + 500), 0.05)
			button_pressed = true
			for fruits in fruit_in_the_juicer:
				var random_card_gained = fruits.card_deck.pick_random()
				GlobalData.card_reward_information.append(random_card_gained)
				if !GlobalData.unlocked_combat_cards.has(random_card_gained):
					GlobalData.unlocked_combat_cards.append(random_card_gained)
				else:
					continue
			SceneTransition.change_scene("res://Scenes/fruitjuiced.tscn", "fade")
		else:
			return
	else:
		return

func left_mouse_button_clicked() -> void:
	var new_fruit = raycast_check_for_fruit()
	if new_fruit != null and GlobalData.player_inventory[new_fruit.fruit_data.id]["quantity"] > 0:
		GlobalData.player_inventory[new_fruit.fruit_data.id]["quantity"] -= 1
		fruit_selected = true
		fruit_in_the_juicer.append(new_fruit.fruit_data)
		for children in scroll_grid_container.get_children():
			if children.fruit_data.id == new_fruit.fruit_data.id:
				children.set_up_name_and_amount(GlobalData.player_inventory[new_fruit.fruit_data.id]["resource"], GlobalData.player_inventory[new_fruit.fruit_data.id]["quantity"])
		var physics_box = RigidBody2D.new()
		physics_box.global_position = Vector2(randi_range($FruitSpawnPosMin.global_position.x, $FruitSpawnPosMax.global_position.x), $FruitSpawnPosMin.global_position.y)
		
		var collision_shape = CollisionShape2D.new()
		var box_shape = RectangleShape2D.new()
		box_shape.size = Vector2(128/2.0, 128/2.0) 
		collision_shape.shape = box_shape
		physics_box.add_child(collision_shape)
		
		var sprite = Sprite2D.new()
		sprite.texture = new_fruit.fruit_data.fruit_art
		sprite.scale = Vector2(0.5, 0.5)
		physics_box.add_child(sprite)
		
		var label = Label.new()
		label.text = new_fruit.fruit_data.id
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.grow_horizontal = Control.GROW_DIRECTION_BOTH
		label.grow_vertical = Control.GROW_DIRECTION_BOTH
		physics_box.add_child(label)
		label.add_theme_constant_override("outline_size", 10)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		
		add_child(physics_box)
	if new_fruit != null and GlobalData.player_inventory[new_fruit.fruit_data.id]["quantity"] <= 0:
		GlobalData.player_inventory.erase(new_fruit.fruit_data.id)
		new_fruit.queue_free()
		return
	else:
		return


func raycast_check_for_fruit():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	var results = space_state.intersect_point(parameters)
	if results.size() > 0:
		var result_collision_mask = results[0].collider.collision_mask
		if result_collision_mask == COLLISION_MASK_FRUIT:
			#card clicked
			var fruit_found = results[0].collider.get_parent()
			if fruit_found:
				return fruit_found
			else:
				return null
