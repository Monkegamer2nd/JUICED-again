extends CanvasLayer

const CLOUD_WOOSH = preload("res://Sounds/SoundEffects/another whoosh.wav")

@onready var cloud: TextureRect = $CloudTransition
@onready var fade: ColorRect = $FadeTransition
@onready var shield: ColorRect = $InputShield
var current_level_id : String = "Tutorial Level"
var current_floor_level : int = -1
var reward_amount : int = 5
var previous_scene = "res://Scenes/main_menu.tscn"
var next_cutscene_data: CutsceneData = null
var next_scene_after_cutscene: String = ""

func _ready() -> void:
	cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shield.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.modulate.a = 0.0


func change_scene(target_scene_path: String, style: String = "fade") -> void:
	var screen_size = get_viewport().get_visible_rect().size
	
	if style == "cloud":
		shield.mouse_filter = Control.MOUSE_FILTER_STOP
		cloud.size = screen_size
		cloud.position.y = -screen_size.y
		var player = AudioStreamPlayer.new()
		player.stream = CLOUD_WOOSH
		player.bus = "SFX" 
		player.pitch_scale = 1.0
		player.volume_db = 0.0
		get_tree().root.add_child(player)
		player.play(0.5)
		player.finished.connect(player.queue_free)
		
		var tween_out = create_tween()
		tween_out.tween_property(cloud, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		await tween_out.finished
		
	elif style == "fade":
		fade.mouse_filter = Control.MOUSE_FILTER_STOP
		
		var tween = create_tween()
		tween.tween_property(fade, "modulate:a", 1.0, 0.4)
		await tween.finished
	
	get_tree().change_scene_to_file(target_scene_path)
	await get_tree().process_frame
	
	if style == "cloud":
		var tween = create_tween()
		tween.tween_property(cloud, "position:y", screen_size.y, 0.5).set_trans(Tween.TRANS_CUBIC)
		await tween.finished
		shield.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	elif style == "fade":
		var tween = create_tween()
		tween.tween_property(fade, "modulate:a", 0.0, 0.4)
		await tween.finished
		fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
