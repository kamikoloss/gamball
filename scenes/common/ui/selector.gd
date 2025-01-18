extends Control
class_name Selector


# 値を変更したとき
signal changed # (option_key: String)


@export var _left_button: Button
@export var _right_button: Button
@export var _value_label: Label
@export var _lamps_parent: Control


var options: Dictionary = {}:
	set(value):
		options = value
		_option_keys.assign(options.keys())
var default_option_key: String = ""


var _option_keys: Array[String] = []
var _selected_option_index: int = 0


func _ready() -> void:
	#options = { "k1": "v1", "k2": "v2", "k3": "v3" } # Debug
	#default_option_key = "k2" # Debug

	_left_button.pressed.connect(func(): _shift_option(-1))
	_right_button.pressed.connect(func(): _shift_option(1))

	_selected_option_index = _option_keys.find(default_option_key)
	_refresh_view()


func _refresh_view() -> void:
	if _option_keys.is_empty():
		return

	# Label
	_value_label.text = options[_option_keys[_selected_option_index]]

	# Lamp
	var lamp_index: int = 0
	for lamp in _lamps_parent.get_children():
		if lamp is Lamp:
			if lamp_index < _option_keys.size():
				if lamp_index == _selected_option_index:
					lamp.enable()
				else:
					lamp.disable()
			else:
				lamp.visible = false
			lamp_index += 1


func _set_option(option_key: String) -> void:
	_selected_option_index = _option_keys.find(option_key)
	_refresh_view()


func _shift_option(shift: int) -> void:
	if _option_keys.is_empty():
		return

	_selected_option_index += (_option_keys.size() + shift)
	_selected_option_index %= _option_keys.size()
	_refresh_view()
	changed.emit(_option_keys[_selected_option_index])
