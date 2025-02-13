class_name BarSlider
extends Control


# 値を変更したとき
signal changed # (value: int)


@export var value := 0:
	set(v):
		if value != v:
			value = v
			_refresh_view()
			changed.emit(value)


@export var _min_value := 0
@export var _max_value := 10
@export var _step := 1

@export var _bar: ProgressBar
@export var _slider: HSlider


func _ready() -> void:
	_slider.value_changed.connect(func(v): value = int(v))

	_bar.min_value = _min_value
	_bar.max_value = _max_value
	_bar.step = _step
	_slider.min_value = _min_value
	_slider.max_value = _max_value
	_slider.step = _step

	_refresh_view()


func _refresh_view() -> void:
	_bar.value = value
	_slider.value = value
