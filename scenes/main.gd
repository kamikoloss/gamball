class_name Main
extends Node


enum TweenType { CURTAIN_SHOW, CURTAIN_HIDE }
enum SceneType { TITLE, GAME, INFORMATION, OPTIONS }


const CURTAIN_FADE_DURATION: float = 1.0


@export var _game_scene: PackedScene

@export var _camera: Camera2D
@export var _curtain: Control

@export var _title: Title
@export var _information: Information
@export var _options: Options


var _is_loading_now: bool = false
var _current_scene_type: SceneType = SceneType.TITLE
var _game: Game
var _tweens: Dictionary = {}


func _ready() -> void:
	_curtain.visible = true
	_hide_curtain(0.5) # 最初はゆっくり非表示にする

	# Title
	_title.play_button_pressed.connect(func():_goto_scene(SceneType.GAME))
	_title.information_button_pressed.connect(func(): _goto_scene(SceneType.INFORMATION))
	_title.options_button_pressed.connect(func(): _goto_scene(SceneType.OPTIONS))
	_title.exit_button_pressed.connect(_exit_game)


func _goto_scene(scene_type: SceneType) -> void:
	print("[Main] _load_scene(%s)" % [SceneType.keys()[scene_type]])
	
	if _is_loading_now:
		return
	_is_loading_now = true

	# 目隠しを表示する (表示が完了するまで待つ)
	await _show_curtain(2)

	# シーンを読み込む
	var loaded_scene_types = [SceneType.TITLE, SceneType.INFORMATION, SceneType.OPTIONS]
	if scene_type in loaded_scene_types:
		_title.visible = true
		_information.visible = true
		_options.visible = true
		if _game:
			_game.queue_free()
	else:
		match scene_type:
			SceneType.GAME:
				_title.visible = false
				_information.visible = false
				_options.visible = false
				_game = _game_scene.instantiate()
				add_child(_game)

	# カメラを移動する
	var zero_position_scene_types = [SceneType.TITLE, SceneType.GAME]
	if scene_type in zero_position_scene_types:
		_camera.position = Vector2.ZERO
	else:
		match scene_type:
			SceneType.INFORMATION:
				_camera.position = _information.position
			SceneType.OPTIONS:
				_camera.position = _options.position

	_current_scene_type = scene_type
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


func _exit_game() -> void:
	# TODO: 確認ウィンドウを出す？
	get_tree().quit()


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
