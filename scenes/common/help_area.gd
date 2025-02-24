class_name HelpArea
extends Control


# ホバーしたとき
signal hovered # (help_area: HelpArea, hovered: bool)
# クリックしたとき
signal pressed # (help_area: HelpArea)


enum ShapeType { SQUARE, SQUARE_ROUNDED, CIRCLE }


const SHOW_DURATION := 0.2


@export var shape_type: ShapeType
@export var key: String


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

var _target_panel: Control


func _ready() -> void:
	# shape_type を元に対象の Control を決定する
	match shape_type:
		ShapeType.SQUARE:
			_target_panel = _panel_square
		ShapeType.SQUARE_ROUNDED:
			_target_panel = _panel_square_rounded
		ShapeType.CIRCLE:
			_target_panel = _panel_circle

	_target_panel.mouse_entered.connect(func(): _hovered = true)
	_target_panel.mouse_exited.connect(func(): _hovered = false)
	_target_panel.gui_input.connect(_on_panel_gui_input)

	_panel_square.visible = false
	_panel_square_rounded.visible = false
	_panel_circle.visible = false
	_target_panel.visible = true
	_target_panel.modulate = Color.TRANSPARENT


func _on_panel_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			pressed.emit(self)


func _refresh_view() -> void:
	if _hovered:
		_tween.tween_property(_target_panel, "modulate", Color.WHITE, SHOW_DURATION)
	else:
		_tween.tween_property(_target_panel, "modulate", Color.TRANSPARENT, SHOW_DURATION)
