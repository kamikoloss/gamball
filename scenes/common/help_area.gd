class_name HelpArea
extends Control


# ホバーしたとき
signal hovered # (self, <bool>)
# クリックしたとき
#signal pressed # (self)


enum ShapeType { SQUARE, SQUARE_ROUNDED, CIRCLE }


const SHOW_DURATION := 0.2


@export var shape_type: ShapeType
@export var translation_key: String
@export var related_object: Node


@export var _panel_square: Control
@export var _panel_square_rounded: Control
@export var _panel_circle: Control


var disabled := false:
	set(v):
		disabled = v
		if disabled:
			_panel_square.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_panel_square_rounded.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_panel_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			_panel_square.mouse_filter = Control.MOUSE_FILTER_STOP
			_panel_square_rounded.mouse_filter = Control.MOUSE_FILTER_STOP
			_panel_circle.mouse_filter = Control.MOUSE_FILTER_STOP


var _target_panel: Control

# 現在ホバーしているかどうか
var _hovered := false:
	set(v):
		_hovered = v
		_refresh_view()
		hovered.emit(self, _hovered)
var _tween: Tween:
	get():
		if _tween:
			_tween.kill()
		return create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)


func _ready() -> void:
	match shape_type:
		ShapeType.SQUARE:
			_target_panel = _panel_square
		ShapeType.SQUARE_ROUNDED:
			_target_panel = _panel_square_rounded
		ShapeType.CIRCLE:
			_target_panel = _panel_circle
	_target_panel.visible = true

	_target_panel.mouse_entered.connect(func(): _hovered = true)
	_target_panel.mouse_exited.connect(func(): _hovered = false)
	_refresh_view()


func _refresh_view() -> void:
	if _hovered:
		_tween.tween_property(_target_panel, "modulate", Color.WHITE, SHOW_DURATION)
	else:
		_tween.tween_property(_target_panel, "modulate", Color.TRANSPARENT, SHOW_DURATION)
