class_name Billiards
extends Node2D


@export var _spawn_position: Node2D
@export var _arrow: Control
@export var _arrow_square: TextureRect


var _current_ball: Ball


func spawn_ball(ball: Ball) -> void:
	ball.position = _spawn_position.position
	_current_ball = ball


func shoot_ball(implulse: Vector2) -> void:
	if not _current_ball:
		return
	_current_ball.apply_impulse(implulse)
