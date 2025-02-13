@tool
class_name GoogleSheetesDownloaderDock
extends Control


# (url: String, file_path: String)
signal download_button_pressed


@export var http_request: HTTPRequest


@export var _url_edit: LineEdit
@export var _file_path_edit: LineEdit
@export var _download_button: Button


func _ready() -> void:
	_download_button.pressed.connect(_on_donwload_button_pressed)


func _on_donwload_button_pressed() -> void:
	download_button_pressed.emit(_url_edit.text, _file_path_edit.text)
