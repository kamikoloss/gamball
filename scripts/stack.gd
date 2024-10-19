class_name Stack
extends Node2D


@export var _spawn_position: Node2D


func _ready() -> void:
	pass


func spawn_ball(ball: Ball) -> void:
	ball.position = _spawn_position.position
