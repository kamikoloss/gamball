class_name Stack
extends Node2D


@export var _spawn_position: Node2D

func _ready() -> void:
	pass


func spawn_ball(ball: Ball) -> void:
	ball.position = _spawn_position.position
	# 詰まらないように下方向の初速をつける
	var spawn_impulse = Vector2(0, randi_range(400, 500))
	ball.apply_impulse(spawn_impulse) 
