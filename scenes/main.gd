class_name Main
extends Node


func _ready() -> void:
	SceneManager.initialize()
	SceneManager.title.exit_button_pressed.connect(_exit_game)
	# TODO: Config を読み込んで音量を設定する


func _exit_game() -> void:
	# TODO: 確認ウィンドウを出す？
	get_tree().quit()
