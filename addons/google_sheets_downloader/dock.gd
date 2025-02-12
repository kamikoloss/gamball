@tool
class_name GoogleSheetesDownloaderDock
extends Control


# (id: String, gid: String, file_path: String)
signal download_button_pressed


@export var http_request: HTTPRequest


@export var _id_edit: LineEdit #"16a2xelqXRadMEHmGxsouNhut7MArpOgXknMEdnjLcuU"
@export var _gid_edit: LineEdit #"1795548261"
@export var _file_path_edit: LineEdit #"res://resources/translations/tr.csv"
@export var _download_button: Button


func _ready() -> void:
	_download_button.pressed.connect(_on_donwload_button_pressed)


func _on_donwload_button_pressed() -> void:
	download_button_pressed.emit(_id_edit.text, _gid_edit.text, _file_path_edit.text)
