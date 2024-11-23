class_name Main
extends Node


func _ready() -> void:
	SceneManager.title.exit_button_pressed.connect(_exit_game)


func _exit_game() -> void:
	# TODO: 確認ウィンドウを出す？
	get_tree().quit()
