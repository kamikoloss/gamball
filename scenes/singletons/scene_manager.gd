#class_name SceneManager
extends Node


enum TweenType { CURTAIN_SHOW, CURTAIN_HIDE }
enum SceneType { TITLE, GAME, INFORMATION, OPTIONS }


const CURTAIN_FADE_DURATION: = 1.0


@export var title: Title
@export var information: Information
@export var options: Options
@export var effects_crt: Control


@export var _curtain: Control
@export var _version_label: Label


var _is_loading_now := false
var _current_scene_type := SceneType.TITLE
var _back_scene_type := SceneType.TITLE
var _game: Game

var _tweens := {}


# TODO: title, information, options のインスタンス化をここでやる


func _ready() -> void:
	print("[SceneManager] ready.")

	title.visible = false
	information.visible = false
	options.visible = false

	title.play_button_pressed.connect(func(): goto_scene(SceneType.GAME))
	title.information_button_pressed.connect(func(): goto_scene(SceneType.INFORMATION))
	title.options_button_pressed.connect(func(): goto_scene(SceneType.OPTIONS))
	information.exit_button_pressed.connect(func(): goto_scene(_back_scene_type))
	options.exit_button_pressed.connect(_on_options_exit)

	_refresh_version_label()


# 初期化処理
# Main シーンから呼ぶ想定
func initialize() -> void:
	print("[SceneManager] initialized.")

	title.visible = true
	information.visible = false
	options.visible = false

	# 目隠し
	_curtain.visible = true
	_hide_curtain(0.5) # 最初はゆっくり非表示にする


func goto_scene(scene_type: SceneType) -> void:
	print("[SceneManager] goto_scene(%s)" % [SceneType.keys()[scene_type]])

	if _is_loading_now:
		return
	_is_loading_now = true

	# 目隠しを表示する (表示が完了するまで待つ)
	await _show_curtain(2)

	# シーンを読み込む
	if scene_type == SceneType.GAME:
		if not _game:
			_game = load("res://scenes/game/game2.tscn").instantiate()
			_game.initialize()
			add_child(_game)

	# シーンの 表示/非表示を切り替える
	var scenes = {
		SceneType.TITLE: title,
		SceneType.GAME: _game,
		SceneType.INFORMATION: information,
		SceneType.OPTIONS: options,
	}
	for scene_key in scenes.keys():
		var visible = scene_type == scene_key
		if scenes[scene_key]:
			scenes[scene_key].visible = visible

	# ステータスを変更する
	_current_scene_type = scene_type
	if scene_type in [SceneType.TITLE, SceneType.GAME]:
		_back_scene_type = scene_type
	_is_loading_now = false

	# 目隠しを非表示にする
	await _hide_curtain()


func _show_curtain(speed_ratio: float = 1.0) -> void:
	_curtain.modulate = Color.TRANSPARENT
	var tween = _get_tween(TweenType.CURTAIN_SHOW)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(_curtain, "modulate", Color.WHITE, CURTAIN_FADE_DURATION / speed_ratio)
	await tween.finished

func _hide_curtain(speed_ratio: float = 1.0) -> void:
	_curtain.modulate = Color.WHITE
	var tween = _get_tween(TweenType.CURTAIN_HIDE)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(_curtain, "modulate", Color.TRANSPARENT, CURTAIN_FADE_DURATION / speed_ratio)
	await tween.finished


func _refresh_version_label() -> void:
	var version = ProjectSettings.get_setting("application/config/version")
	_version_label.text = version
	print("[SceneManager] version: %s" % [version])


func _on_options_exit() -> void:
	goto_scene(_back_scene_type)
	SaveManager.save_config()


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
