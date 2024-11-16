class_name TitleButton
extends TextureButton


enum TweenType { HOVER }


@export var _font_size: int = 128
@export var _label_text: String = "SAMPLE"

@export var _hover_texture: TextureRect
@export var _label_1: Label
@export var _label_2: Label


var _size_x: float = 0

# { TweenType: Tween, ... } 
var _tweens: Dictionary = {}


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	_hover_texture.size.x = 0

	_label_1.text = _label_text
	_label_1.add_theme_font_size_override("font_size", _font_size)
	_label_2.text = _label_text
	_label_2.add_theme_font_size_override("font_size", _font_size)

	_size_x = size.x


func _on_mouse_entered() -> void:
	_hover_texture.size.x = 0
	var tween = _get_tween(TweenType.HOVER)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(_hover_texture, "size:x", _size_x, 0.2)

func _on_mouse_exited() -> void:
	_hover_texture.size.x = _size_x
	var tween = _get_tween(TweenType.HOVER)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(_hover_texture, "size:x", 0, 0.8) # ゆっくり戻る


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
