class_name Selector
extends Control


# 値を変更したとき
signal changed # (value)


@export var _left_button: Button
@export var _right_button: Button
@export var _value_label: Label
@export var _points_parent: Control


var value:
	set(v):
		if value != v:
			value = v
			_refresh_view()
			changed.emit(value)
var disabled := false:
	set(v):
		_left_button.disabled = v
		_right_button.disabled = v
		_refresh_view()

# 設定項目 { <Value>: <ラベル文字列>, ... } 
var options := {}


var _selected_option_index := -1:
	get():
		return options.keys().find(value)


func _ready() -> void:
	#options = { "v1": "value1", "v2": "value2", "v3": "value3" } # debug
	#value = "v2" # debug

	_left_button.pressed.connect(func(): _shift_option(-1))
	_right_button.pressed.connect(func(): _shift_option(1))

	_refresh_view()


func _refresh_view() -> void:
	if options.is_empty():
		return

	# Label
	_value_label.text = options[value]

	# Point
	var point_index := 0
	for point: Control in _points_parent.get_children():
		point.visible = point_index < options.size()
		if point_index == _selected_option_index:
			point.modulate = ColorPalette.PRIMARY
		else:
			point.modulate = ColorPalette.GRAY_60
		point_index += 1

	# disabled
	if disabled:
		_value_label.self_modulate = ColorPalette.GRAY_60
	else:
		_value_label.self_modulate = ColorPalette.WHITE


func _shift_option(shift: int) -> void:
	if options.is_empty():
		return

	var index = (_selected_option_index + shift) % options.size()
	value = options.keys()[index]
