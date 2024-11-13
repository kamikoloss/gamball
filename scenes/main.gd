class_name Main
extends Node


enum TweenType { CurtainShow, CurtainHide }
enum SceneType { Title, Game }


const CURTAIN_FADE_DURATION: float = 1.0


@export var _game_scene: PackedScene

@export var _title: Title
@export var _options: Options
@export var _camera: Camera2D
@export var _curtain: Control


var _is_loading_now: bool = false
var _current_scene_type: SceneType = SceneType.Title
var _game: Game
var _tweens: Dictionary = {}


func _ready() -> void:
	_curtain.visible = true
	_hide_curtain(0.5) # 最初はゆっくり非表示にする

	# Title
	_title.play_button_pressed.connect(func():_load_scene(SceneType.Game))
	_title.information_button_pressed.connect(func(): print("TODO"))
	_title.options_button_pressed.connect(func(): _goto_options())
	_title.exit_button_pressed.connect(func(): get_tree().quit())


func _load_scene(scene_type: SceneType) -> void:
	print("[Main] _load_scene(%s)" % [SceneType.keys()[scene_type]])
	
	if _is_loading_now:
		return
	_is_loading_now = true

	# 目隠しを表示する (表示が完了するまで待つ)
	await _show_curtain()

	# シーンを読み込む
	if scene_type == SceneType.Title:
		# ロード済みなので表示を切り替えるだけ
		_title.visible = true
		if _game:
			_game.queue_free()
	elif scene_type == SceneType.Game:
		_title.visible = false
		_game = _game_scene.instantiate()
		add_child(_game)

	# 目隠しを非表示にする
	_current_scene_type = scene_type
	await _hide_curtain()
	_is_loading_now = false


func _goto_default() -> void:
	if _is_loading_now:
		return
	_is_loading_now = true
	await _show_curtain()
	_camera.position = Vector2.ZERO
	await _hide_curtain()
	_is_loading_now = false

func _goto_options() -> void:
	if _is_loading_now:
		return
	_is_loading_now = true
	await _show_curtain()
	_camera.position = _options.position
	await _hide_curtain()
	_is_loading_now = false


func _show_curtain(speed_ratio: float = 1.0) -> void:
	_curtain.modulate = Color.TRANSPARENT
	var tween = _get_tween(TweenType.CurtainShow)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(_curtain, "modulate", Color.WHITE, CURTAIN_FADE_DURATION / speed_ratio)
	await tween.finished

func _hide_curtain(speed_ratio: float = 1.0) -> void:
	_curtain.modulate = Color.WHITE
	var tween = _get_tween(TweenType.CurtainHide)
	tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.tween_property(_curtain, "modulate", Color.TRANSPARENT, CURTAIN_FADE_DURATION / speed_ratio)
	await tween.finished


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
