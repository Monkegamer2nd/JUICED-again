extends Label

func _ready() -> void:
	grow_horizontal = GrowDirection.GROW_DIRECTION_BOTH
	grow_vertical = GrowDirection.GROW_DIRECTION_BOTH

func setup(amount: int, text_color: Color, world_position: Vector2) -> void:
	text = str(amount)
	modulate = text_color
	global_position = world_position
	var random_x = randf_range(-30, 30)
	var target_position = global_position + Vector2(random_x, -60)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", target_position, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	scale = Vector2(0.5, 0.5)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.15)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_delay(0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.3)
	tween.chain().tween_callback(queue_free)
