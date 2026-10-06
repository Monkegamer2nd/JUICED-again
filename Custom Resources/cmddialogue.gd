class_name CmdDialogue
extends CutsceneCommand

@export var speaker: String = ""
@export_enum("left", "right") var position: String = "left"
@export_multiline var text: String = ""

@export_category("Sprite Sheet Slicing")
@export var sheet_path: Texture2D
@export var grid_columns: int = 1
@export var grid_rows: int = 1
@export var frame_x: int = 0
@export var frame_y: int = 0
@export var play_sound: AudioStream
