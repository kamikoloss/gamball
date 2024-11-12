class_name MainUi
extends Control


enum TweenType { Curtain }


const CURTAIN_FADE_DURATION: float = 2.0


@export var _curtain: Control


var _tweens: Dictionary = {} # { TweenType: Tween, ... } 


func _ready() -> void:
	_hide_curtain()


func _hide_curtain() -> void:
	_curtain.visible = true
	_curtain.modulate = Color.WHITE

	var tween = _get_tween(TweenType.Curtain)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(_curtain, "modulate", Color.TRANSPARENT, CURTAIN_FADE_DURATION)


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
