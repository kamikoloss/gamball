class_name Stack
extends Node2D


@export var _spawn_position: Node2D

var _spawn_impulse: Vector2 = Vector2(0, 500)

func _ready() -> void:
	pass


func spawn_ball(ball: Ball) -> void:
	ball.position = _spawn_position.position
	ball.apply_impulse(_spawn_impulse) # 詰まらないように下方向に飛ばす
