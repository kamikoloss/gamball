class_name Pachinko
extends Node2D


@export var _ball_scene: PackedScene

@export var _spawn_position: Node2D
@export var _balls: Node2D


func _ready() -> void:
	pass


func spawn_ball(ball: Ball) -> void:
	ball.position = _spawn_position.position
