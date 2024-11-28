class_name Main
extends Node


func _ready() -> void:
	SceneManager.initialize()
	SceneManager.title.exit_button_pressed.connect(_exit_game)

	# TODO: Config を読み込む
	AudioManager.initialize()
	AudioManager.set_volume(AudioManager.BusType.MASTER, 8)
	AudioManager.set_volume(AudioManager.BusType.BGM, 8)
	AudioManager.set_volume(AudioManager.BusType.SE, 8)


func _exit_game() -> void:
	# TODO: 確認ウィンドウを出す？
	get_tree().quit()
