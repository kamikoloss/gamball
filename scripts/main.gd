class_name Main
extends Node


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


var money: int = 0:
	set(value):
		money = value
		_money_label.text = str(money)
var balls: int = 0:
	set(value):
		balls = value
		_balls_label.text = str(balls)


# 出現する Ball の level のリスト (確率込み)
var _level_list: Array[int] = [0, 0, 0, 0, 0, 1, 1, 1, 2, 2]
# 払い出しが残っている Ball の level のリスト
var _payout_list: Array[int] = []
# 何秒ごとに 1 Ball を払い出すか
var _payout_interval: float = 0.05


func _ready() -> void:
	# Label 用に初期化する
	money = 0
	balls = 0

	# すべての Hole の signal に接続する
	var holes = get_tree().get_nodes_in_group("hole")
	for hole: Hole in holes:
		hole.ball_entered.connect(_on_hole_ball_entered)

	# 払いだし処理を開始する
	_start_payout()



func create_new_ball(level: int = 0) -> Ball:
	var ball: RigidBody2D = _ball_scene.instantiate()
	ball.level = level
	_balls.add_child(ball)
	return ball


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_ENTER:
				var level = _level_list.pick_random()
				var new_ball = create_new_ball(level)
				_billiards.spawn_ball(new_ball)
			KEY_SPACE:
				# debug
				var force_x = randf_range(-1, 1) * 1000
				var force_y = -1 * 1000
				var impulse = Vector2(force_x, force_y)
				_billiards.shoot_ball(impulse)


# Ball が Hole に落ちたときの処理
func _on_hole_ball_entered(hole: Hole, ball: Ball) -> void:
	#print("[Main] ball (%s) is entered to hole. (%s)" % [ball.level, hole.hole_type])

	match hole.hole_type:
		# Billiards
		Hole.HoleType.Billiards:
			# Pachinko 上に出現させる
			var new_ball = create_new_ball(ball.level)
			_pachinko.spawn_ball(new_ball)
		# Pachinko
		Hole.HoleType.Pachinko:
			# 払い出しリストに追加する
			var amount = hole.gain_ratio * ball.level
			for i in range(amount):
				_payout_list.push_back(ball.level)
		# Stack
		Hole.HoleType.Stack:
			# Ball の数をカウントする
			balls += 1
		# Lost: 何もしない
		Hole.HoleType.Lost:
			pass


func _start_payout() -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.tween_callback(_payout).set_delay(_payout_interval)

func _payout() -> void:
	if _payout_list.is_empty():
		return
	var level = _payout_list.pop_front()
	var new_ball = create_new_ball(level)
	_stack.spawn_ball(new_ball)
