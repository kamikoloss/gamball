extends Control
class_name Selector


# 値を変更したとき
signal changed # (option_key)


@export var _left_button: Button
@export var _right_button: Button
@export var _value_label: Label
@export var _points_parent: Control


var value:
	set(v):
		value = v
		_selected_option_index = _option_keys.find(value)
		_refresh_view()
var options: Dictionary = {}:
	set(v):
		options = v
		_option_keys = options.keys()


var _option_keys: Array = []
var _selected_option_index: int = 0


func _ready() -> void:
	#options = { "k1": "v1", "k2": "v2", "k3": "v3" } # Debug
	#value = "k2" # Debug

	_left_button.pressed.connect(func(): _shift_option(-1))
	_right_button.pressed.connect(func(): _shift_option(1))

	_selected_option_index = _option_keys.find(value)
	_refresh_view()


func _refresh_view() -> void:
	if options.is_empty():
		return

	# Label
	_value_label.text = options[_option_keys[_selected_option_index]]

	# Point
	var point_index: int = 0
	for point: Control in _points_parent.get_children():
		if point_index < _option_keys.size():
			if point_index == _selected_option_index:
				point.modulate = ColorPalette.PRIMARY
			else:
				point.modulate = ColorPalette.GRAY_40
		else:
			point.visible = false
		point_index += 1


func _shift_option(shift: int) -> void:
	if options.is_empty():
		return

	_selected_option_index += (_option_keys.size() + shift)
	_selected_option_index %= _option_keys.size()
	_refresh_view()
	changed.emit(_option_keys[_selected_option_index])
