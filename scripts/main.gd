class_name Main
extends Node


var money: int = 0:
	set(value):
		money = value
		_money_label.text = str(money)
var balls: int = 0:
	set(value):
		balls = value
		_balls_label.text = str(balls)


# PackedScenes
@export var _ball_scene: PackedScene
# Nodes
@export var _billiards: Billiards
@export var _pachinko: Pachinko
@export var _stack: Stack
@export var _balls: Node2D
# UI
@export var _money_label: Label
@export var _balls_label: Label


func _ready() -> void:
	# Label 用に初期化する
	money = 0
	balls = 0

	# すべての Hole の signal に接続する
	var holes = get_tree().get_nodes_in_group("hole")
	for hole: Hole in holes:
		hole.ball_entered.connect(_on_hole_ball_entered)


func create_ball(level: int = 0) -> Ball:
	var ball: RigidBody2D = _ball_scene.instantiate()
	ball.level = level
	_balls.add_child(ball)
	return ball


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_ENTER:
				var ball = create_ball()
				_billiards.spawn_ball(ball)
			KEY_SPACE:
				# debug
				var force_x = randf_range(-1, 1) * 1000
				var force_y = -1 * 1000
				var impulse = Vector2(force_x, force_y)
				_billiards.shoot_ball(impulse)


# Ball が Hole に落ちたときの処理
func _on_hole_ball_entered(hole: Hole, ball: Ball) -> void:
	print("[Main] ball (%s) is entered to hole. (%s)" % [ball.level, hole.hole_type])

	match hole.hole_type:
		# Billiards
		Hole.HoleType.Billiards:
			# Pachinko 上に出現させる
			var new_ball = create_ball(ball.level)
			_pachinko.spawn_ball(new_ball)
		# Pachinko
		Hole.HoleType.Pachinko:
			# Stack 上に出現させる
			for i in range(hole.gain_ratio):
				var new_ball = create_ball(ball.level)
				_stack.spawn_ball(new_ball)
		# Stack
		Hole.HoleType.Stack:
			# Ball の数をカウントする
			balls += (ball.level + 1)
		# Lost: 何もしない
		Hole.HoleType.Lost:
			pass
