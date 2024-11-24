class_name Billiards
extends Node2D


@export var _spawn_position: Node2D
@export var _spawn_extra_position_a: Node2D
@export var _spawn_extra_position_b: Node2D
@export var _spawn_extra_position_c: Node2D
@export var _spawn_extra_position_d: Node2D

@export var _balls_count_label: Label


var _current_ball: Ball = null


# 盤面上に Ball を移動する
func spawn_ball(ball: Ball) -> void:
	ball.position = _spawn_position.position
	ball.freeze = true
	_current_ball = ball


# spawn_ball() をなかったことにする
# そもそもなかったことにする Ball が存在しなかった場合: false を返す
func rollback_spawn_ball() -> bool:
	if _current_ball == null:
		return false
	_current_ball.queue_free()
	return true


# 盤面上に Extra Ball を移動する
func spawn_extra_ball(ball: Ball) -> void:
	var spawn_posiiton = [
		_spawn_extra_position_a,
		_spawn_extra_position_b,
		_spawn_extra_position_c,
		_spawn_extra_position_d,
	].pick_random()
	ball.position = spawn_posiiton.position

	# 初速をつける
	var spawn_impulse = Vector2(randi_range(0, 100), randi_range(0, 100))
	ball.apply_impulse(spawn_impulse)


# Ball を発射する
func shoot_ball(implulse: Vector2) -> void:
	if _current_ball == null:
		return

	AudioManager.play_se(AudioManager.SeType.BILLIARDS_SHOT)
	_current_ball.freeze = false
	_current_ball.apply_impulse(implulse)
	_current_ball = null


func refresh_balls_count(count: int) -> void:
	_balls_count_label.text = str(count)
