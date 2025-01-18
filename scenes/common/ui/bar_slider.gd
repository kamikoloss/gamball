extends Control
class_name BarSlider


# スライダーの値が変わったとき
signal changed # (value: int)


@export var value: int = 0:
	set(v):
		value = v
		_refresh_view()


@export var _min_value: int = 0
@export var _max_value: int = 10
@export var _step: int = 1

@export var _bar: ProgressBar
@export var _slider: HSlider


func _ready() -> void:
	_bar.min_value = _min_value
	_bar.max_value = _max_value
	_bar.step = _step
	_slider.min_value = _min_value
	_slider.max_value = _max_value
	_slider.step = _step

	_slider.value_changed.connect(_on_slider_value_changed)

	_refresh_view()


func _refresh_view() -> void:
	_bar.value = value
	_slider.value = value


func _on_slider_value_changed(value: float) -> void:
	var value_int = int(value)
	self.value = value_int
	_refresh_view()
	changed.emit(value_int)
