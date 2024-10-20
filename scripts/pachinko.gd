class_name Pachinko
extends Node2D


@export var _spawn_position_a: Node2D
@export var _spawn_position_b: Node2D
@export var _wall_a: Node2D
@export var _wall_b: Node2D


var _tween_duration: float = 2.0


func _ready() -> void:
	_start_wall_rotation()


func spawn_ball(ball: Ball) -> void:
	var randf = randf()
	if randf < 0.5:
		ball.position = _spawn_position_a.position
	else:
		ball.position = _spawn_position_b.position


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
