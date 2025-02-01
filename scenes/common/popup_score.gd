class_name PopupScore
extends Control
# TODO: Manager に管理させる


const MOVE_SPEED_FROM := 320.0 # 初速度 (px/s)
const MOVE_SPEED_TO := 40.0 # 終端速度 (px/s)
const PHASE_1_DURATION := 0.4 # 飛び上がって減速していく秒数
const PHASE_2_DURATION := 0.8 # 等速で移動する秒数
const PHASE_3_DURATION := 0.4 # 等速で消えていく秒数

const FONT_SIZE_BASE := 32
const OUTLINE_SIZE_BASE := 8


@export var _label: Label


var _move_speed := MOVE_SPEED_FROM


func _ready() -> void:
	#popup(Vector2(640, 360), "+9999") # debug
	pass


func _process(delta: float) -> void:
	position.y -= _move_speed * delta


func set_font_color(color: Color) -> void:
	_label.self_modulate = color


func set_font_size(ratio: float) -> void:
	_label.add_theme_font_size_override("font_size", FONT_SIZE_BASE * ratio)
	_label.add_theme_constant_override("outline_size", OUTLINE_SIZE_BASE * ratio)


func popup(from: Vector2, text: String) -> void:
	#print("[PopupScore] position: %s, text: %s" % [from, text])
	position = from
	modulate = Color.TRANSPARENT
	_label.text = text

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	# 飛び上がる
	tween.tween_property(self, "modulate", Color.WHITE, PHASE_1_DURATION)
	tween.tween_method(func(v): _move_speed = v, MOVE_SPEED_FROM, MOVE_SPEED_TO, PHASE_1_DURATION)
	# 等速で移動する
	tween.chain()
	tween.tween_interval(PHASE_2_DURATION)
	# 等速で消えていく
	tween.chain()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, PHASE_3_DURATION)
	# 消える
	tween.chain()
	tween.tween_callback(queue_free)
