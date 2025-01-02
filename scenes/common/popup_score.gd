class_name PopupScore
extends Control


const POPUP_DURATION: float = 1.0
const POPUP_DISTANCE: Vector2 = Vector2(0, -40)
const STOP_DURATION: float = 0.4
const DIE_DURATION: float = 0.4


@export var _label: Label


func _ready() -> void:
	#popup(Vector2(640, 360), "+9999") # debug
	pass


func popup(from: Vector2, text: String) -> void:
	print("[PopupScore] position: %s, text: %s" % [from, text])
	self.position = from
	self.modulate = Color.TRANSPARENT
	_label.text = text

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	# 飛び上がる
	tween.tween_property(self, "modulate", Color.WHITE, POPUP_DURATION)
	tween.tween_property(self, "position", position + POPUP_DISTANCE, POPUP_DURATION)
	# 静止する
	tween.chain()
	tween.tween_interval(STOP_DURATION)
	# 消えていく
	tween.chain()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, DIE_DURATION)
	# 消える
	tween.chain()
	tween.tween_callback(queue_free)
