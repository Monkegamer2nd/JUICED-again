extends Line2D

var start_position : Control
var end_position : Control
var outline_line : Line2D
var global_start = Vector2(0, 0)
var global_end = Vector2(0,0)

@onready var arrow_sprite = $Arrow
@onready var arrow_outline = $ArrowOutline

@export var outline_thickness : float = 6.0
@export var outline_color: Color = Color.BLACK
@export var curve_height: float
@export var line_segments: int = 15

func _ready() -> void:
	arrow_sprite.visible = false
	arrow_outline.visible = false

func setup(from_node : Control, to_node : Control):
	start_position = from_node
	end_position = to_node
	
	outline_line = Line2D.new()
	outline_line.width = width + outline_thickness
	outline_line.default_color = outline_color
	outline_line.joint_mode = joint_mode
	outline_line.begin_cap_mode = Line2D.LINE_CAP_BOX
	outline_line.end_cap_mode = Line2D.LINE_CAP_BOX
	outline_line.z_index = self.z_index - 2
	outline_line.width_curve = self.width_curve
	
	add_child(outline_line)
	move_child(outline_line, 0)

func _process(_delta: float) -> void:
	if start_position == null or end_position == null:
			return
		
	if is_instance_valid(start_position) and is_instance_valid(end_position):
		clear_points()
		if is_instance_valid(outline_line):
			outline_line.clear_points()
		
		global_position = Vector2.ZERO
		if is_instance_valid(outline_line):
			outline_line.global_position = Vector2.ZERO
		
		var start_size_offset = start_position.size.x / 2 if start_position.size.x > 0 else 20.0
		var end_size_offset = end_position.size.x / 2 if end_position.size.x > 0 else 20.0
		
		global_start = Vector2(start_position.global_position.x + start_size_offset, start_position.global_position.y + 5.0)
		global_end = Vector2(end_position.global_position.x + end_size_offset, end_position.global_position.y + 5.0)
		
		var mid_point = (global_start + global_end) / 2
		var p1 = mid_point + Vector2(0, curve_height)
		
		for i in range(line_segments + 1):
			var t = float(i) / float(line_segments)
			var curve_point = (1 - t) * (1 - t) * global_start + 2 * (1 - t) * t * p1 + t * t * global_end
			
			add_point(curve_point)
			if is_instance_valid(outline_line):
				outline_line.add_point(curve_point)
		
		if self.points.size() >= 2:
			arrow_sprite.visible = true
			arrow_outline.visible = true
			arrow_sprite.global_position = global_end
			arrow_outline.global_position = global_end
			var end_point = self.points[-1]
			var previous_point = self.points[-2]
			var dir = (end_point - previous_point).normalized()
			arrow_sprite.rotation = dir.angle()
			arrow_outline.rotation = dir.angle()
			arrow_outline.z_index = 2
			arrow_sprite.z_index = 2
	else:
		queue_free()
