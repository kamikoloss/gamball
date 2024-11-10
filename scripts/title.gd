class_name Title
extends Node


enum TweenType { Bunny }


const BUNNY_MOVE_DURATION = 4.0
const BUNNY_POSITION_FROM = Vector2(400, -480)
const BUNNY_POSITION_TO = Vector2(400, -240)


@export var _play_button: Control
@export var _options_button: TextureButton
@export var _information_button: TextureButton
@export var _exit_button: TextureButton

@export var _bunny_texture: TextureRect


var _tweens: Dictionary = {} # { TweenType: Tween, ... } 


func _ready() -> void:
	_show_bunny()


func _show_bunny() -> void:
	_bunny_texture.self_modulate = Color.TRANSPARENT
	_bunny_texture.position = BUNNY_POSITION_FROM

	var tween = _get_tween(TweenType.Bunny)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(_bunny_texture, "self_modulate", Color.WHITE, BUNNY_MOVE_DURATION)
	tween.tween_property(_bunny_texture, "position", BUNNY_POSITION_TO, BUNNY_MOVE_DURATION)


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
