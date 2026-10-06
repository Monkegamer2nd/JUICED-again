extends TextureRect
class_name AnimatedTextureRect

var atlas_res: AtlasTexture
var frame_height: float = 250.0
var frames_per_second: float = 1.0

var current_frame: int = 0
var time_passed: float = 0.0

func _ready() -> void:
	if texture is AtlasTexture:
		atlas_res = texture
		frame_height = atlas_res.region.size.y
		set_process(true)
	elif texture and not texture is AtlasTexture:
		setup_atlas(texture, texture.get_width(), texture.get_height() / 2.0)
	else:
		set_process(false)

func setup_atlas(sheet_texture: Texture2D, width_per_frame: float, height_per_frame: float, fps: float = 5.0) -> void:
	frame_height = height_per_frame
	frames_per_second = fps
	
	atlas_res = AtlasTexture.new()
	atlas_res.atlas = sheet_texture
	atlas_res.region = Rect2(0, 0, width_per_frame, height_per_frame)
	
	texture = atlas_res

func _process(delta: float) -> void:
	if not atlas_res:
		return
	
	time_passed += delta
	var time_per_frame = 1.0 / frames_per_second
	
	if time_passed >= time_per_frame:
		time_passed = 0.0
		current_frame = 1 - current_frame
		atlas_res.region = Rect2(0, current_frame * frame_height, atlas_res.region.size.x, frame_height)
