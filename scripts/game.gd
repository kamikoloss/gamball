class_name Game
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
	[25, TaxType.Balls, 50],	# Balls 50
	[50, TaxType.Balls, 100],	# Balls 100
	[75, TaxType.Money, 400],	# Balls 200
	[100, TaxType.Money, 800],	# Balls 400
	[125, TaxType.Balls, 600],	# Balls 600
	[150, TaxType.Balls, 800],	# Balls 800
	[175, TaxType.Balls, 1000],	# Balls 1000
]


# PackedScene
@export var _ball_scene: PackedScene

# Node
@export var _billiards: Billiards
@export var _billiards_board: Area2D
@export var _pachinko: Pachinko
@export var _stack: Stack
@export var _balls: Node2D # Ball instances の親 Node
@export var _game_ui: GameUi
@export var _products: Control # Product の親
@export var _bunny: Bunny


# TODO: Autoload に置いていい気がする
var turn: int = 0:
	set(value):
		turn = value
		_game_ui.refresh_turn_label(value)
var money: int = 0:
	set(value):
		money = value
		_game_ui.refresh_money_label(value)
		_set_money_to_products()
var balls: int = 0:
	set(value):
		balls = value
		_game_ui.refresh_balls_label(value)


# 現在ドラッグ中かどうか
var _is_dragging: bool = false
# ドラッグを開始した座標
var _drag_position_from: Vector2
# 現在ドラッグしている座標
var _drag_position_to: Vector2
# 引っ張りで Ball が吹き飛ぶ強さ
# NOTE: _drag_length_max と反比例させる
var _impulse_ratio: float = 10

# 出現する Deck Ball level の初期リスト (確率込み)
var _deck_level_list: Array[int] = [0, 0, 0, 0, 0, 1, 1, 1, 2, 2]
# 出現する Extra Ball level の初期リスト (確率込み)
var _extra_level_list: Array[int] = [5, 6, 7, 8, 9]
# 払い出しキューが残っている Ball level のリスト
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
	# 初期化
	turn = 0
	money = 1000
	balls = 0

	# Input
	_billiards_board.input_event.connect(_on_billiards_board_input)

	# Signal
	_game_ui.buy_balls_button_pressed.connect(_on_buy_balls_button_pressed)
	_game_ui.sell_balls_button_pressed.connect(_on_sell_balls_button_pressed)
	_game_ui.tax_pay_button_pressed.connect(_on_tax_pay_button_pressed)
	_game_ui.shop_exit_button_pressed.connect(_on_shop_exit_button_pressed)
	_game_ui.info_button_pressed.connect(_on_info_button_pressed)
	_game_ui.people_touch_button_pressed.connect(_on_people_touch_button_pressed)

	# Signal (Hole)
	for maybe_hole in get_tree().get_nodes_in_group("hole"):
		if maybe_hole is Hole:
			maybe_hole.ball_entered.connect(_on_hole_ball_entered)
	# Signal (Product)
	for maybe_product in _products.get_children():
		if maybe_product is Product:
			maybe_product.icon_pressed.connect(_on_product_icon_pressed)

	# GameUi
	_game_ui.refresh_balls_slot_deck(_deck_level_list)
	_game_ui.refresh_balls_slot_extra(_extra_level_list)
	_refresh_next()

	# ボール購入ボタンを1プッシュする
	_on_buy_balls_button_pressed()
	# 払い出し処理を開始する
	_start_payout()


func restart_game() -> void:
	get_tree().reload_current_scene()


# 左クリックを押したとき: Billiards Board 上に限定する
# see. _on_billiards_board_input()
func _input(event: InputEvent) -> void:
	# マウスボタン
	if event is InputEventMouseButton:
		# 左クリックを離したとき
		if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_is_dragging = false

			# GameUi
			_game_ui.hide_drag_point()
			_game_ui.hide_arrow()

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
			var drag_vector = _drag_position_from - _drag_position_to
			var clamped_length =  clampf(drag_vector.length(), 0, DRAG_LENGTH_MAX)
			var deg = rad_to_deg(drag_vector.angle()) + 90
			var scale = (clamped_length / DRAG_LENGTH_MAX) * 10 # scale 10 が最大
			_game_ui.refresh_arrow(deg, scale)


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

	_game_ui.hide_tax_window()
	_game_ui.show_shop_window()


func _on_shop_exit_button_pressed() -> void:
	_refresh_next()
	_game_ui.hide_shop_window()
	_game_ui.hide_people_window()


func _on_info_button_pressed() -> void:
	pass


func _on_people_touch_button_pressed() -> void:
	_bunny.shuffle_pose()
	# TODO: JSON に逃がす
	var dialogue_list = [
		"GAMBALL は近未来のバーチャルハイリスクハイリターンギャンブルだよ！",
		"ゲームを続けたいなら定期的にプレイ料を払ってね。真ん中の下らへんに出てるやつ。",
		"ビリヤードポケットに入った玉はパチンコ盤面上に出現するよ。",
		"水色の??玉が他の玉にぶつかる前にビリヤードポケットに落ちるとなくなるから気をつけてね！",
	]
	_game_ui.refresh_dialogue_label(dialogue_list.pick_random())


# Ball が Hole に落ちたときの処理
func _on_hole_ball_entered(hole: Hole, ball: Ball) -> void:
	#print("[Main] ball (%s) is entered to hole. (%s)" % [ball.level, hole.hole_type])
	match hole.hole_type:
		Hole.HoleType.Billiards:
			# Ball が有効化されていない場合: 何もしない (Ball は消失する)
			if not ball.is_active:
				return
			# パチンコ盤面上に同じ Ball を出現させる
			var new_ball = _create_new_ball(ball.level)
			_pachinko.spawn_ball(new_ball)
		Hole.HoleType.Extra:
			# ビリヤード盤面上にランダムな Extra Ball を出現させる
			var level = _extra_level_list.pick_random()
			var new_ball = _create_new_ball(level)
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
				_is_dragging = true
				_drag_position_from = event.position
				_drag_position_to = Vector2.ZERO

				# GameUi
				_game_ui.show_drag_point(_drag_position_from)
				_game_ui.show_arrow()

				# ビリヤード盤面上に Ball を生成する
				balls -= 1
				var level = _deck_level_list.pick_random()
				var new_ball = _create_new_ball(level, false) # 最初の出現時には有効化されていない
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
	_game_ui.refresh_balls_slot_deck(_deck_level_list)
	_game_ui.refresh_balls_slot_extra(_extra_level_list)


# Ball instance を作成する
func _create_new_ball(level: int = 0, is_active = true) -> Ball:
	var ball: Ball = _ball_scene.instantiate()
	ball.level = level
	ball.is_active = is_active
	_balls.add_child(ball)
	return ball


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


# Payout のループを開始する
func _start_payout() -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.tween_callback(_pop_payout).set_delay(_payout_interval)

# 払い出しキューに追加する
func _push_payout(level: int, amount: int) -> void:
	for i in amount:
		_payout_level_list.push_back(level)
	_game_ui.refresh_payout_label(_payout_level_list.size())

# 払い出しキューを実行する
func _pop_payout() -> void:
	if _payout_level_list.is_empty():
		return
	var level = _payout_level_list.pop_front()
	var new_ball = _create_new_ball(level)
	_stack.spawn_ball(new_ball)
	_game_ui.refresh_payout_label(_payout_level_list.size())


# Next 関連の見た目を更新する
func _refresh_next() -> void:
	if _next_tax_index < TAX_LIST.size():
		var turn = TAX_LIST[_next_tax_index][0]
		var type = TAX_LIST[_next_tax_index][1]
		var amount = TAX_LIST[_next_tax_index][2]
		_game_ui.refresh_next(turn, type, amount)
	else:
		_game_ui.refresh_next_clear()

# 1ターン進める
func _go_to_next_turn() -> void:
	turn += 1

	if _next_tax_index < TAX_LIST.size():
		if turn == TAX_LIST[_next_tax_index][0]:
			_game_ui.show_tax_window()
			_game_ui.show_people_window() # 連動


# TODO: Autoload にしたらいらなくなる
func _set_money_to_products() -> void:
	for maybe_product in _products.get_children():
		if maybe_product is Product:
			maybe_product.main_money = money
