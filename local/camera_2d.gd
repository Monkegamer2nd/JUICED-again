extends Camera2D

@export var follow_strength := 0.06
@export var follow_speed := 5.0

var starting_position : Vector2

func _ready() -> void:
	starting_position = position

func _process(delta: float) -> void:
	var screen_center = get_viewport_rect().size / 2
	var mouse_pos = get_viewport().get_mouse_position()
	
	var mouse_offset = mouse_pos - screen_center
	var target_position = starting_position + mouse_offset * follow_strength
	
	position = position.lerp(target_position, follow_speed * delta)
