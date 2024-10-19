class_name Billiards
extends Node2D


@export var _ball_scene: PackedScene

@export var _start_point: Node2D
@export var _balls: Node2D


var _current_ball: RigidBody2D


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass



func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_ENTER:
				_spawn_ball()
			KEY_SPACE:
				_shoot_ball()


func _spawn_ball() -> void:
	var ball: RigidBody2D = _ball_scene.instantiate()
	ball.position = _start_point.position
	_balls.add_child(ball)
	_current_ball = ball


func _shoot_ball() -> void:
	if not _current_ball:
		return
	var force_x = randf_range(-1, 1) * 50000
	var force_y = -1 * 50000
	_current_ball.apply_force(Vector2(force_x, force_y))
