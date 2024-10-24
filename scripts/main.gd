class_name Main
extends Node


# PackedScene
@export var _ball_scene: PackedScene

# Node
@export var _billiards: Billiards
@export var _billiards_board: Area2D
@export var _pachinko: Pachinko
@export var _stack: Stack
@export var _balls: Node2D # Ball instances の親 Node

# UI
@export var _shop: Control
@export var _info: Control
@export var _buy_balls_button: Button
@export var _sell_balls_button: Button
@export var _shop_button: Button
@export var _info_button: Button
@export var _money_label: Label
@export var _balls_label: Label
@export var _payout_label: Label
@export var _balls_slot_deck: Control
@export var _balls_slot_extra: Control
# Arrow
@export var _arrow_center_position: Node2D
@export var _arrow: Control
@export var _arrow_square: TextureRect


var money: int = 0:
	set(value):
		money = value
		_money_label.text = str(money)
var balls: int = 0:
	set(value):
		balls = value
		_balls_label.text = str(balls)


# 現在ドラッグ中かどうか
var _is_dragging: bool
# 現在ドラッグしている座標
var _drag_position: Vector2
# 引っ張りが最大になるドラッグの距離 (px)
var _drag_length_max: float = 160
# 引っ張りで Ball が吹き飛ぶ強さ
# NOTE: _drag_length_max と反比例させる
var _impulse_ratio: float = 10

# 出現する Deck Ball level のリスト (確率込み)
var _deck_level_list: Array[int] = [0, 0, 0, 0, 0, 1, 1, 1, 2, 2]
# 出現する Extra Ball level のリスト (確率込み)
var _extra_level_list: Array[int] = [5, 6, 7, 8, 9]
# 払い出しが残っている Ball level のリスト
var _payout_level_list: Array[int] = []
# 何秒ごとに 1 Ball を払い出すか
# NOTE: Stack の排出速度を見ていい感じに調整する
var _payout_interval: float = 0.1

# Ball の購入レート
# [x, y] x money = y balls
var _buy_rate: Array[int] = [100, 25]
# Ball の売却レート
# [x, y] x balls = y money
var _sell_rate: Array[int] = [50, 100]


func _ready() -> void:
	# UI
	_shop.visible = false
	_info.visible = false
	# Arrow
	_arrow.visible = false
	_arrow_square.scale.y = 0
	# Balls Slot
	_refresh_balls_slot(_balls_slot_deck, _deck_level_list)
	_refresh_balls_slot(_balls_slot_extra, _extra_level_list)

	# Label 用に初期化する
	money = 1000
	balls = 0

	# Button に接続する
	_buy_balls_button.pressed.connect(_on_buy_balls_button_pressed)
	_sell_balls_button.pressed.connect(_on_sell_balls_button_pressed)
	_shop_button.pressed.connect(_on_shop_button_pressed)
	_info_button.pressed.connect(_on_info_button_pressed)
	# すべての Hole の signal に接続する
	var holes = get_tree().get_nodes_in_group("hole")
	for hole: Hole in holes:
		hole.ball_entered.connect(_on_hole_ball_entered)
	# ビリヤード盤面上の入力を処理する
	_billiards_board.input_event.connect(_on_billiards_board_input)

	# 貸し出しボタンを1プッシュしておく
	_on_buy_balls_button_pressed()
	# 払い出し処理を開始する
	_start_payout()


func create_new_ball(level: int = 0) -> Ball:
	var ball: RigidBody2D = _ball_scene.instantiate()
	ball.level = level
	_balls.add_child(ball)
	return ball


func _input(event: InputEvent) -> void:
	# マウスボタンを
	if event is InputEventMouseButton:
		# 押したとき: Billiards Board 上に限定する
		if event.pressed:
			pass
		# 離したとき
		else:
			_is_dragging = false
			_arrow.visible = false
			_arrow_square.scale.y = 0
			# Ball を発射する
			var drag_vector = _arrow_center_position.position - _drag_position
			var clamped_length =  clampf(drag_vector.length(), 0, _drag_length_max)
			var impulse = drag_vector.normalized() * clamped_length
			_billiards.shoot_ball(impulse * _impulse_ratio)
	# マウス全般を
	if event is InputEventMouseMotion:
		# マウスボタンを押している間
		if _is_dragging:
			# Arrow を更新する
			_drag_position = event.position
			_refresh_arrow()


func _on_buy_balls_button_pressed() -> void:
	var money_unit = _buy_rate[0]
	var balls_unit = _buy_rate[1]
	if money < money_unit:
		return
	money -= money_unit
	_push_payout(0, balls_unit)


func _on_sell_balls_button_pressed() -> void:
	var balls_unit = _sell_rate[0]
	var money_unit = _sell_rate[1]
	if balls < balls_unit:
		return
	balls -= balls_unit
	money += money_unit


func _on_shop_button_pressed() -> void:
	_shop.visible = not _shop.visible


func _on_info_button_pressed() -> void:
	_info.visible = not _info.visible


# Ball が Hole に落ちたときの処理
func _on_hole_ball_entered(hole: Hole, ball: Ball) -> void:
	#print("[Main] ball (%s) is entered to hole. (%s)" % [ball.level, hole.hole_type])
	match hole.hole_type:
		Hole.HoleType.Billiards:
			# Pachinko 上に同じ Ball を出現させる
			var new_ball = create_new_ball(ball.level)
			_pachinko.spawn_ball(new_ball)
		Hole.HoleType.Extra:
			# Billiards 上に Extra Ball を出現させる
			var level = _extra_level_list.pick_random()
			var new_ball = create_new_ball(level)
			_billiards.spawn_extra_ball(new_ball)
		Hole.HoleType.Gain:
			# 払い出しリストに追加する
			var amount = hole.gain_ratio * ball.level
			_push_payout(ball.level, amount)
		Hole.HoleType.Lost:
			# 何もしない
			pass
		Hole.HoleType.Stack:
			# Ball の数をカウントする
			balls += 1


# ビリヤード盤面上で入力があったときの処理
func _on_billiards_board_input(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	# マウスボタンを
	if event is InputEventMouseButton:
		# 押したとき
		if event.pressed:
			if 0 < balls:
				_drag_position = _arrow_center_position.position
				_is_dragging = true
				_arrow.visible = true
				# Ball を生成する
				balls -= 1
				var level = _deck_level_list.pick_random()
				var new_ball = create_new_ball(level)
				_billiards.spawn_ball(new_ball)
		# 離したとき: _input 全般で対応する
		else:
			pass


func _start_payout() -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.tween_callback(_pop_payout).set_delay(_payout_interval)

func _push_payout(level: int, amount: int) -> void:
	for i in amount:
		_payout_level_list.push_back(level)
	_payout_label.text = str(_payout_level_list.size())

func _pop_payout() -> void:
	if _payout_level_list.is_empty():
		return
	var level = _payout_level_list.pop_front()
	var new_ball = create_new_ball(level)
	_stack.spawn_ball(new_ball)
	_payout_label.text = str(_payout_level_list.size())


func _refresh_arrow() -> void:
	var drag_vector = _arrow_center_position.position - _drag_position
	var clamped_length =  clampf(drag_vector.length(), 0, _drag_length_max)
	_arrow.rotation_degrees = rad_to_deg(drag_vector.angle()) + 90
	_arrow_square.scale.y = (clamped_length / _drag_length_max) * 10


func _refresh_balls_slot(parent_node: Node, level_list: Array[int]) -> void:
	var index = 0
	for node in parent_node.get_children():
		if node is Ball: # Label もある
			if index < level_list.size():
				node.level = level_list[index]
			else:
				node.level = -1 # 空欄
			node.refresh_view()
			index += 1
