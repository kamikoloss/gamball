class_name PopupScore
extends Control


const POPUP_DURATION: float = 1.0
const POPUP_DISTANCE: Vector2 = Vector2(0, -40)
const STOP_DURATION: float = 0.4
const DIE_DURATION: float = 0.4


@export var _label: Label


var _position_from: Vector2 = self.position


func _ready() -> void:
	#self.position = Vector2(640, 360) # debug
	_position_from = self.position
	#popup("+9999") # debug


func popup(text: String) -> void:
	_label.text = text
	self.modulate = Color.TRANSPARENT

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	# 飛び上がる
	tween.tween_property(self, "modulate", Color.WHITE, POPUP_DURATION)
	tween.tween_property(self, "position", _position_from + POPUP_DISTANCE, POPUP_DURATION)
	# 静止する
	tween.chain()
	tween.tween_interval(STOP_DURATION)
	# 消えていく
	tween.chain()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, DIE_DURATION)
	# 消える
	tween.chain()
	tween.tween_callback(queue_free)
