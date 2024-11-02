class_name Main
extends Node


enum TaxType { Money, Balls }


# DECK の最大数
const DECK_MAX_SIZE: int = 16
# EXTRA の最大数
const EXTRA_MAX_SIZE: int = 16
# Ball が発射される最低のドラッグの距離 (px)
const DRAG_LENGTH_MIN: float = 10
# 引っ張りが最大になるドラッグの距離 (px)
const DRAG_LENGTH_MAX: float = 160

# Tax (ノルマ) のリスト
# [<turn>, TaxType, <amount>]
const TAX_LIST = [
	[25, TaxType.Balls, 50],
	[50, TaxType.Balls, 100],
	[75, TaxType.Money, 400], # Balls 200
	[100, TaxType.Money, 800], # Balls 400
	[125, TaxType.Balls, 600],
	[150, TaxType.Balls, 800],
	[175, TaxType.Money, 2000], # Balls 1000
]
# ゲームクリアになる Turn
const CLEAR_TURN: int = 200

# TODO: UI
const UI_POSITION_BOTTOM_FROM: Vector2 = Vector2(0, 720)
const UI_POSITION_BOTTOM_TO: Vector2 = Vector2(0, -720)
const UI_POSITION_RIGHT_FROM: Vector2 = Vector2(1280, 0)
const UI_POSITION_RIGHT_TO: Vector2 = Vector2(720, 0)
const UI_POSITION_TO: Vector2 = Vector2(0, 0)
const UI_MOVE_DURATION: float = 1.0


# PackedScene
@export var _ball_scene: PackedScene

# Node
@export var _billiards: Billiards
@export var _billiards_board: Area2D
@export var _pachinko: Pachinko
@export var _stack: Stack
@export var _balls: Node2D # Ball instances の親 Node

# TODO: クラス分ける
# UI Main
@export var _buy_balls_button: Button
@export var _sell_balls_button: Button
@export var _shop_button: Button
@export var _info_button: Button
@export var _turn_label: Label
@export var _money_label: Label
@export var _balls_label: Label
@export var _payout_label: Label
@export var _next_turn_label: Label
@export var _next_type_label: Label
@export var _next_amount_label: Label
@export var _balls_slot_deck: Control
@export var _balls_slot_extra: Control
# UI Main Arrow
@export var _arrow: Control
@export var _arrow_square: TextureRect
@export var _drag_point: TextureRect
# UI Tax
@export var _ui_tax: Control
@export var _tax_pay_button: TextureButton
# UI Shop
@export var _ui_shop: Control
@export var _products: Control
@export var _shop_exit_button: TextureButton
# UI People
@export var _ui_people: Control


# TODO: Autoload に置いていい気がする
var turn: int = 0:
	set(value):
		turn = value
		_turn_label.text = str(turn)
		_refresh_next()
var money: int = 0:
	set(value):
		money = value
		_money_label.text = str(money)
		_set_money_to_products()
var balls: int = 0:
	set(value):
		balls = value
		_balls_label.text = str(balls)


# 現在ドラッグ中かどうか
var _is_dragging: bool = false
# ドラッグを開始した座標
var _drag_position_from: Vector2
# 現在ドラッグしている座標
var _drag_position_to: Vector2
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

# 次に訪れる Tax
var _next_tax_index = 0



func _ready() -> void:
	# UI
	_refresh_balls_slot_deck()
	_refresh_balls_slot_extra()
	# Arrow
	_arrow.visible = false
	_arrow_square.scale.y = 0
	_drag_point.visible = false

	# Label 用に初期化する
	turn = 0
	money = 1000
	balls = 0

	# Button に接続する
	_buy_balls_button.pressed.connect(_on_buy_balls_button_pressed)
	_sell_balls_button.pressed.connect(_on_sell_balls_button_pressed)
	_tax_pay_button.pressed.connect(_on_tax_pay_button_pressed)
	_shop_exit_button.pressed.connect(_on_shop_exit_button_pressed)
	_info_button.pressed.connect(_on_info_button_pressed)
	# すべての Hole の signal に接続する
	var holes = get_tree().get_nodes_in_group("hole")
	for hole: Hole in holes:
		hole.ball_entered.connect(_on_hole_ball_entered)
	# ビリヤード盤面上の入力を処理する
	_billiards_board.input_event.connect(_on_billiards_board_input)

	# すべての Product の signal に接続する
	for maybe_product in _products.get_children():
		if maybe_product is Product:
			maybe_product.icon_pressed.connect(_on_product_icon_pressed)

	# ボール購入ボタンを1プッシュする
	_on_buy_balls_button_pressed()
	# 払い出し処理を開始する
	_start_payout()


# Ball instance を作成する
func create_new_ball(level: int = 0, is_active = true) -> Ball:
	var ball: Ball = _ball_scene.instantiate()
	ball.level = level
	ball.is_active = is_active
	_balls.add_child(ball)
	return ball


# 左クリックを押したとき: Billiards Board 上に限定する
# see. _on_billiards_board_input()
func _input(event: InputEvent) -> void:
	# マウスボタン
	if event is InputEventMouseButton:
		# 左クリックを離したとき
		if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# ドラッグ関連
			_is_dragging = false
			# Arrow
			_arrow.visible = false
			_arrow_square.scale.y = 0
			_drag_point.visible = false

			# ドラッグの距離を算出して丸める
			var drag_vector = Vector2.ZERO
			var clamped_length = 0
			if _drag_position_to != Vector2.ZERO:
				drag_vector = _drag_position_from - _drag_position_to
				clamped_length = clampf(drag_vector.length(), 0, DRAG_LENGTH_MAX)

			# ドラッグの距離が充分な場合: Ball を発射する
			if DRAG_LENGTH_MIN < clamped_length:
				var impulse = drag_vector.normalized() * clamped_length
				_billiards.shoot_ball(impulse * _impulse_ratio)
			# ドラッグの距離が充分でない場合: Ball 生成をなかったことにする
			else:
				var rollback = _billiards.rollback_spawn_ball()
				if rollback:
					balls += 1

	# マウス動作
	if event is InputEventMouseMotion:
		# ドラッグしている間
		if _is_dragging:
			_drag_position_to = event.position
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



func _on_tax_pay_button_pressed() -> void:
	var next_turn = TAX_LIST[_next_tax_index][0]
	var next_type = TAX_LIST[_next_tax_index][1]
	var next_amount = TAX_LIST[_next_tax_index][2]

	if next_type == TaxType.Money:
		money -= next_amount
	elif next_type == TaxType.Balls:
		balls -= next_amount

	_next_tax_index += 1
	_refresh_next()
	_hide_tax_window()
	_show_shop_window()


func _on_shop_exit_button_pressed() -> void:
	_hide_shop_window()


func _on_info_button_pressed() -> void:
	pass


# Ball が Hole に落ちたときの処理
func _on_hole_ball_entered(hole: Hole, ball: Ball) -> void:
	#print("[Main] ball (%s) is entered to hole. (%s)" % [ball.level, hole.hole_type])
	match hole.hole_type:
		Hole.HoleType.Billiards:
			# Ball が有効化されていない場合: 何もしない (Ball は消失する)
			if not ball.is_active:
				return
			# パチンコ盤面上に同じ Ball を出現させる
			var new_ball = create_new_ball(ball.level)
			_pachinko.spawn_ball(new_ball)
		Hole.HoleType.Extra:
			# ビリヤード盤面上にランダムな Extra Ball を出現させる
			var level = _extra_level_list.pick_random()
			var new_ball = create_new_ball(level)
			_billiards.spawn_extra_ball(new_ball)
		Hole.HoleType.Gain:
			# 払い出しリストに追加する
			var amount = hole.gain_ratio * ball.level
			_push_payout(ball.level, amount)
		Hole.HoleType.Lost:
			# 何もしない (Ball は消失する)
			pass
		Hole.HoleType.Stack:
			# Ball の数をカウントする
			balls += 1


# ビリヤード盤面上で入力があったときの処理
func _on_billiards_board_input(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	# マウスボタン
	if event is InputEventMouseButton:
		# 左クリックを押したとき
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if 0 < balls:
				# ドラッグ関連
				_is_dragging = true
				_drag_position_from = event.position
				_drag_position_to = Vector2.ZERO
				# Arrow
				_arrow.visible = true
				_drag_point.visible = true
				_drag_point.position = _drag_position_from
				# ビリヤード盤面上に Ball を生成する
				balls -= 1
				var level = _deck_level_list.pick_random()
				var new_ball = create_new_ball(level, false) # 最初の出現時には有効化されていない
				_billiards.spawn_ball(new_ball)
				# 1ターン進める
				# Ball 生成をなかったことにしてもこれはなかったことにはしない
				_go_to_next_turn()


# 商品のアイコンがクリックされたときの処理
func _on_product_icon_pressed(product: Product) -> void:
	# Money が足りない場合: 何もしない
	if money < product.price:
		print("[Main] no money!")
		return

	var ball_level_rarity = {
		Ball.Rarity.Common: [0, 1, 2, 3],
		Ball.Rarity.Rare: [4, 5, 6, 7],
		Ball.Rarity.Epic: [8, 9, 10, 11],
		Ball.Rarity.Legendary: [12, 13, 14, 15],
	}

	# Product の効果を発動する
	# TODO: マジックナンバーをなくす？
	# TODO: 実行できない場合 return する
	match product.product_type:
		Product.ProductType.DeckPack:
			for i in 3:
				if _deck_level_list.size() < DECK_MAX_SIZE:
					var random_rarity = _pick_random_rarity()
					var level = ball_level_rarity[random_rarity].pick_random()
					_deck_level_list.push_back(level)
					print("[Main] random_rarity: %s, level: %s" % [random_rarity, level])
		Product.ProductType.DeckPack2:
			return
		Product.ProductType.DeckCleaner:
			if 1 < _deck_level_list.size():
				_deck_level_list.sort()
				_deck_level_list.pop_front()
		Product.ProductType.ExtraPack:
			for i in 2:
				if _extra_level_list.size() < EXTRA_MAX_SIZE:
					var random_rarity = _pick_random_rarity()
					var level = ball_level_rarity[random_rarity].pick_random()
					_extra_level_list.push_back(level)
					print("[Main] random_rarity: %s, level: %s" % [random_rarity, level])
		Product.ProductType.ExtraPack2:
			return
		Product.ProductType.ExtraCleaner:
			if 1 < _extra_level_list.size():
				_extra_level_list.sort()
				_extra_level_list.pop_front()

	# return しなかった場合: Money を減らす
	money -= product.price

	# DECK, EXTRA の見た目を更新する
	_refresh_balls_slot_deck()
	_refresh_balls_slot_extra()


# 重み付きのレア度を抽選する
func _pick_random_rarity() -> Ball.Rarity:
	# レア度の分子の割合
	var rarity_weight = {
		Ball.Rarity.Common: 40,
		Ball.Rarity.Rare: 30,
		Ball.Rarity.Epic: 20,
		Ball.Rarity.Legendary: 10,
	}
	# 抽選の分母 (合計)
	var rarity_weight_total = 0
	for rarity in rarity_weight.keys():
		# TODO: 重み変更効果を実装するならここ
		rarity_weight_total += rarity_weight[rarity]

	# 分母内の整数を抽選する
	var random = randi_range(0, rarity_weight_total)

	# 抽選した整数に対応するレア度を決定する
	var rarity_check = 0
	var random_rarity = Ball.Rarity.Common
	for rarity in rarity_weight.keys():
		random_rarity = rarity
		rarity_check += rarity_weight[rarity]
		if random < rarity_check:
			break

	return random_rarity


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
	var drag_vector = _drag_position_from - _drag_position_to
	var clamped_length =  clampf(drag_vector.length(), 0, DRAG_LENGTH_MAX)
	_arrow.rotation_degrees = rad_to_deg(drag_vector.angle()) + 90
	_arrow_square.scale.y = (clamped_length / DRAG_LENGTH_MAX) * 10 # scale 10 が最大


func _refresh_balls_slot_deck() -> void:
	_refresh_balls_slot(_balls_slot_deck, _deck_level_list)

func _refresh_balls_slot_extra() -> void:
	_refresh_balls_slot(_balls_slot_extra, _extra_level_list)

func _refresh_balls_slot(parent_node: Node, level_list: Array[int]) -> void:
	var index = 0
	for node in parent_node.get_children():
		if node is Ball: # Label もある
			if index < level_list.size():
				node.level = level_list[index]
			else:
				node.level = Ball.BALL_LEVEL_EMPTY_SLOT
			node.refresh_view()
			index += 1


func _refresh_next() -> void:
	# クリアしたとき
	if CLEAR_TURN <= turn:
		_next_turn_label.text = ""
		_next_type_label.text = ""
		_next_amount_label.text = "CLEAR!!"
		return

	var next_turn = TAX_LIST[_next_tax_index][0]
	var next_type = TAX_LIST[_next_tax_index][1]
	var next_type_text = "￥" if next_type == TaxType.Money else "●"
	var next_amount = TAX_LIST[_next_tax_index][2]

	_next_turn_label.text = str(next_turn)
	_next_type_label.text = next_type_text
	_next_amount_label.text = "-%s" % [next_amount]


# 1ターン進める
func _go_to_next_turn() -> void:
	turn += 1

	if CLEAR_TURN <= turn:
		return
	if turn == TAX_LIST[_next_tax_index][0]:
		_show_tax_window()


func _show_tax_window() -> void:
	_show_people_window()
	_ui_tax.visible = true
	_ui_tax.position = UI_POSITION_BOTTOM_FROM
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_ui_tax, "position", UI_POSITION_TO, UI_MOVE_DURATION)

func _hide_tax_window() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_ui_tax, "position", UI_POSITION_BOTTOM_TO, UI_MOVE_DURATION)


func _show_shop_window() -> void:
	_ui_shop.visible = true
	_ui_shop.position = UI_POSITION_BOTTOM_FROM
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_ui_shop, "position", UI_POSITION_TO, UI_MOVE_DURATION)

func _hide_shop_window() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_ui_shop, "position", UI_POSITION_BOTTOM_TO, UI_MOVE_DURATION)
	_hide_people_window()


func _show_people_window() -> void:
	_ui_people.visible = true
	_ui_people.position = UI_POSITION_RIGHT_FROM
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_ui_people, "position", UI_POSITION_TO, UI_MOVE_DURATION)

func _hide_people_window() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_ui_people, "position", UI_POSITION_RIGHT_TO, UI_MOVE_DURATION)


# TODO: Autoload にしたらいらなくなる
func _set_money_to_products() -> void:
	for maybe_product in _products.get_children():
		if maybe_product is Product:
			maybe_product.main_money = money
