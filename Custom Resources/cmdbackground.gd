class_name CmdBackground
extends CutsceneCommand

@export_category("Background Slicing")
@export var sheet_path: Texture2D
@export var grid_columns: int = 1
@export var grid_rows: int = 1
@export var frame_x: int = 0
@export var frame_y: int = 0
@export var play_sound: AudioStream
