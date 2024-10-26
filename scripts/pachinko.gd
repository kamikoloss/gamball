class_name Pachinko
extends Node2D


# Node
@export var _spawn_position_a: Node2D
@export var _spawn_position_b: Node2D
@export var _wall_a: Node2D
@export var _wall_b: Node2D
@export var _rush_devices: Node2D

# UI
@export var _rush_lamps: Control
@export var _rush_label_a: Label
@export var _rush_label_b: Label


var _tween_duration: float = 2.0


func _ready() -> void:
	disable_rush_devices()
	_start_wall_rotation()


# ボールを生成する
func spawn_ball(ball: Ball) -> void:
	var spawn_posiiton = [
		_spawn_position_a,
		_spawn_position_b,
	].pick_random()
	ball.position = spawn_posiiton.position

	# 初速をつける
	var spawn_impulse = Vector2(0, randi_range(400, 500))
	ball.apply_impulse(spawn_impulse)


# ラッシュを装置を有効化する
func enable_rush_devices() -> void:
	for device in _rush_devices.get_children():
		if device is Hole:
			device.enable()
		elif device is Nail:
			device.enable()

# ラッシュ装置を無効化する
func disable_rush_devices() -> void:
	for device in _rush_devices.get_children():
		if device is Hole:
			device.disable()
		elif device is Nail:
			device.disable()
	_rush_label_a.text = ""
	_rush_label_b.text = ""


# 回転床の動作を開始する
func _start_wall_rotation() -> void:
	var wall_settings = [
		{ "obj": _wall_a, "deg1": 60, "deg2": 0 },
		{ "obj": _wall_b, "deg1": 0, "deg2": -60 },
	]
	for setting in wall_settings:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.set_loops()
		tween.tween_property(setting["obj"], "rotation_degrees", setting["deg1"], _tween_duration)
		tween.chain()
		tween.tween_property(setting["obj"], "rotation_degrees", setting["deg2"], _tween_duration)
