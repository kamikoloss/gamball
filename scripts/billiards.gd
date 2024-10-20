class_name Billiards
extends Node2D


@export var _spawn_position: Node2D


var _current_ball: Ball = null


func spawn_ball(ball: Ball) -> void:
	ball.position = _spawn_position.position
	ball.freeze = true
	_current_ball = ball


func shoot_ball(implulse: Vector2) -> void:
	if _current_ball == null:
		return
	_current_ball.freeze = false
	_current_ball.apply_impulse(implulse)
	_current_ball = null
