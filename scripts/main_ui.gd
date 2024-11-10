class_name MainUi
extends Control


@export var _game_main_button: Button
@export var _game_config_button: Button
@export var _game_info_button: Button


func _ready() -> void:
	_game_main_button.pressed.connect(func(): CameraManager.show_main())
	_game_config_button.pressed.connect(func(): CameraManager.show_config())
	_game_info_button.pressed.connect(func(): CameraManager.show_info())
