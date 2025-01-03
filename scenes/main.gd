class_name Main
extends Node
# ゲーム起動時に最初に呼ばれるシーン


# ゲーム起動時にだけ必要な Singletons の初期化処理はここで実行する
# 例: BGM はゲーム起動時にだけ鳴る -> AudioManager.initialize() 経由で鳴らす
func _ready() -> void:
	SceneManager.initialize()
	SceneManager.title.exit_button_pressed.connect(_exit_game)

	AudioManager.initialize()


func _exit_game() -> void:
	# TODO: 確認ウィンドウを出す？
	get_tree().quit()
