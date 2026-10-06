extends Camera2D

@export var smooth_speed: float = 5.0
@export var zoom_speed: float = 0.15
@export var min_zoom: float = 0.6
@export var max_zoom: float = 2.0

var target_position: Vector2
var target_zoom: Vector2
var is_dragging: bool = false

func _ready() -> void:
	target_position = position
	target_zoom = zoom

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_zoom = (target_zoom + Vector2(zoom_speed, zoom_speed)).clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_zoom = (target_zoom - Vector2(zoom_speed, zoom_speed)).clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

	elif event is InputEventMouseMotion and is_dragging:
		target_position -= event.relative / zoom.x

func _process(delta: float) -> void:
	target_position.x = clamp(target_position.x, limit_left, limit_right)
	target_position.y = clamp(target_position.y, limit_top, limit_bottom)
	position = position.lerp(target_position, smooth_speed * delta)
	zoom = zoom.lerp(target_zoom, smooth_speed * delta)
