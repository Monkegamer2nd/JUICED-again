class_name CutsceneUI
extends Control

signal cutscene_finished

var current_commands: Array[CutsceneCommand] = []
var current_index: int = 0
var current_tween
@onready var background_node: TextureRect = $Background
@onready var left_actor: HBoxContainer = $LeftActor
@onready var right_actor: HBoxContainer = $RightActor
@onready var speaker_label: Label = $SpeakerName
@onready var dialogue: RichTextLabel = $DialogueBox/Dialogue
var is_left: bool

func set_background_from_sheet_resource(cmd: CmdBackground) -> void:
	if not background_node:
		return
		
	if cmd and cmd.sheet_path is AtlasTexture:
		var new_atlas = cmd.sheet_path.duplicate() as AtlasTexture
		if "frame_x" in cmd and "frame_y" in cmd:
			var pos_x = cmd.sheet_path.region.position.x
			var pos_y = cmd.sheet_path.region.position.y
			new_atlas.region = Rect2(pos_x, pos_y, cmd.sheet_path.region.size.x, cmd.sheet_path.region.size.x)
		elif "region" in cmd:
			new_atlas.region = cmd.region
		if "play_sound" in cmd:
			var player = AudioStreamPlayer.new()
			player.stream = cmd.play_sound
			player.bus = "SFX" 
			player.pitch_scale = 1.0
			player.volume_db = -15
			get_tree().root.add_child(player)
			player.play()
			player.finished.connect(player.queue_free)
			
		background_node.texture = new_atlas


func change_background_frame(frame_x: int, frame_y: int, frame_width: float, frame_height: float) -> void:
	if not background_node or not (background_node.texture is AtlasTexture):
		return
		
	var pos_x = frame_x * frame_width
	var pos_y = frame_y * frame_height
	background_node.texture.region = Rect2(pos_x, pos_y, frame_width, frame_height)


func update_actor_from_resource(cmd: CmdDialogue, highlight_active: bool = true) -> void:
	var active_modulate = Color.WHITE
	var inactive_modulate = Color(0.5, 0.5, 0.5, 1.0)
	
	left_actor.modulate = inactive_modulate if highlight_active else Color.WHITE
	right_actor.modulate = inactive_modulate if highlight_active else Color.WHITE
	
	is_left = cmd.position.to_lower() == "left"
	var target_actor = left_actor if is_left else right_actor
	
	if cmd.sheet_path is AtlasTexture:
		var texture_node = _get_or_create_texture_rect(target_actor)
		if texture_node:
			_apply_spritesheet_to_node(texture_node, cmd.sheet_path, cmd)
		if highlight_active:
			target_actor.modulate = active_modulate
		if "play_sound" in cmd:
			var player = AudioStreamPlayer.new()
			player.stream = cmd.play_sound
			player.bus = "SFX" 
			player.pitch_scale = 1.0
			player.volume_db = -5
			get_tree().root.add_child(player)
			player.play()
			player.finished.connect(player.queue_free)

func _apply_spritesheet_to_node(node: TextureRect, atlas_texture: AtlasTexture, cmd: CmdDialogue) -> void:
	var new_atlas = atlas_texture.duplicate() as AtlasTexture
	if "frame_x" in cmd and "frame_y":
		var pos_x = cmd.sheet_path.region.position.x
		var pos_y = cmd.sheet_path.region.position.y
		new_atlas.region = Rect2(pos_x, pos_y, cmd.sheet_path.region.size.x, cmd.sheet_path.region.size.x)
		
	node.texture = new_atlas

func _get_or_create_texture_rect(container: HBoxContainer) -> TextureRect:
	if not container:
		return null
	for child in container.get_children():
		if child is TextureRect:
			return child
	var new_rect = TextureRect.new()
	if is_left:
		new_rect.flip_h = false
	elif !is_left:
		new_rect.flip_h = true
	new_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	new_rect.stretch_mode = TextureRect.STRETCH_SCALE
	container.add_child(new_rect)
	return new_rect

func update_speaker_label_side(side: String, speaker_name: String) -> void:
	if not speaker_label:
		return
	if speaker_name.strip_edges() == "":
		speaker_label.visible = false
		return
		
	speaker_label.visible = true
	if side.to_lower() == "left":
		speaker_label.position.x = 155
		speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	elif side.to_lower() == "right":
		speaker_label.position.x = 735
		speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func display_text(speaker_name: String, text_content: String) -> void:
	if speaker_label:
		speaker_label.text = speaker_name
		
	if dialogue:
		dialogue.text = text_content
		dialogue.visible_ratio = 0.0
		if current_tween and current_tween.is_valid():
			current_tween.kill()
		current_tween = create_tween()
		var duration = max(0.2, text_content.length() * 0.02)
		current_tween.tween_property(dialogue, "visible_ratio", 1.0, duration)

func _ready():
	if SceneTransition.next_cutscene_data:
		play_cutscene(SceneTransition.next_cutscene_data)
	else:
		end_cutscene()

func _input(event):
	if event.is_action_pressed("ui_accept") and not event.is_echo(): 
		current_index += 1
		execute_commands_loop()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			current_index += 1
			execute_commands_loop()

func play_cutscene(data: CutsceneData):
	if not data or data.commands.is_empty():
		end_cutscene()
		return

	current_commands = data.commands
	current_index = 0
	
	if has_node("SkipButton"):
		$SkipButton.pressed.connect(_on_cutscene_skipped)
	
	execute_commands_loop()

func _on_cutscene_skipped():
	end_cutscene()

func execute_commands_loop():
	while current_index < current_commands.size():
		var cmd = current_commands[current_index]
		
		if not cmd:
			current_index += 1
			continue
		
		if cmd is CmdBackground:
			self.set_background_from_sheet_resource(cmd)
			current_index += 1 
			
		elif cmd is CmdDialogue:
			self.update_actor_from_resource(cmd, true)
			self.update_speaker_label_side(cmd.position, cmd.speaker)
			self.display_text(cmd.speaker, cmd.text)
			return 
			
		else:
			current_index += 1
			
	end_cutscene()

func end_cutscene():
	cutscene_finished.emit()
	# 5. Instead of queue_freeing a UI layer, transition to your next gameplay scene!
	if SceneTransition.next_scene_after_cutscene != "":
		SceneTransition.change_scene(SceneTransition.next_scene_after_cutscene, "fade")
