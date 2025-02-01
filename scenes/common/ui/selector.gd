extends Control
class_name Selector


# 値を変更したとき
signal changed # (option_key)


@export var _left_button: Button
@export var _right_button: Button
@export var _value_label: Label
@export var _points_parent: Control


var disabled: bool = false:
	set(v):
		_left_button.disabled = v
		_right_button.disabled = v
		_refresh_view()
var value:
	set(v):
		value = v
		_selected_option_index = options.keys().find(value)
		_refresh_view()

var options: Dictionary = {}

var _selected_option_index: int = -1


func _ready() -> void:
	#options = { "k1": "v1", "k2": "v2", "k3": "v3" } # debug
	#value = "k2" # debug

	_left_button.pressed.connect(func(): _shift_option(-1))
	_right_button.pressed.connect(func(): _shift_option(1))

	_selected_option_index = options.keys().find(value)
	_refresh_view()


func _refresh_view() -> void:
	if options.is_empty():
		return

	# Label
	_value_label.text = options[options.keys()[_selected_option_index]]

	# Point
	var point_index: int = 0
	for point: Control in _points_parent.get_children():
		if point_index < options.size():
			if point_index == _selected_option_index:
				point.modulate = ColorPalette.PRIMARY
			else:
				point.modulate = ColorPalette.GRAY_60
		else:
			point.visible = false
		point_index += 1

	# disabled
	if disabled:
		_value_label.self_modulate = ColorPalette.GRAY_60
	else:
		_value_label.self_modulate = ColorPalette.WHITE


func _shift_option(shift: int) -> void:
	if options.is_empty():
		return

	_selected_option_index += (options.size() + shift)
	_selected_option_index %= options.size()

	_refresh_view()
	changed.emit(options.keys()[_selected_option_index])
