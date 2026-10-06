extends TextureRect

signal hovered_over
signal hovered_off

@onready var fruit_name : Label = $FruitName
@onready var amount : Label = $Amount
@onready var collider : CollisionShape2D = $Area2D/CollisionShape2D
var fruit_data : Resource


func set_up_name_and_amount(name_of_fruit, amount_value):
	self.texture = name_of_fruit.fruit_art
	fruit_name.text = name_of_fruit.id
	amount.text = str(amount_value)


func _on_mouse_entered() -> void:
	emit_signal("hovered_over", self)

func _on_mouse_exited() -> void:
	emit_signal("hovered_off", self)
