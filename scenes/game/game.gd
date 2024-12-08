class_name Game
extends Node2D
# TODO: Ball 移動の処理を切り分ける
# TODO: 引っ張りの処理を切り分ける
# TODO: 料金所の処理を切り分ける
# TODO: Shop の処理を切り分ける


signal exited


enum GameState { GAME, COUNT_DOWN, TAX, SHOP }
enum TaxType { MONEY, BALLS }
enum TweenType { TAX_COUNT_DOWN }


# DECK の 最小数/最大数 の 絶対値/初期値
const DECK_SIZE_MIN: int = 4
const DECK_SIZE_MIN_DEFAULT: int = 8
const DECK_SIZE_MAX: int = 16
# EXTRA の 最小数/最大数の 絶対値/初期値
const EXTRA_SIZE_MIN: int = 0
const EXTRA_SIZE_MAX: int = 16
const EXTRA_SIZE_MAX_DEFAULT: int = 8
# Ball が発射される最低のドラッグの距離 (px)
const DRAG_LENGTH_MIN: float = 10
# 引っ張りが最大になるドラッグの距離 (px)
const DRAG_LENGTH_MAX: float = 160

# Tax (ノルマ) のリスト
# [<turn>, TaxType, <amount>]
const TAX_LIST = [
	[25, TaxType.BALLS, 50],	# Balls 50
	[50, TaxType.BALLS, 100],	# Balls 100
	[75, TaxType.MONEY, 400],	# Balls 200
	[100, TaxType.MONEY, 800],	# Balls 400
	[150, TaxType.BALLS, 800],	# Balls 800
	[200, TaxType.BALLS, 1600],	# Balls 1600
	[250, TaxType.MONEY, 3200],	# Balls 3200
	[300, TaxType.MONEY, 6400],	# Balls 6400
]

# レア度の分子の割合
const RAIRTY_WEIGHT = {
	Ball.Rarity.COMMON: 50,
	Ball.Rarity.UNCOMMON: 40,
	Ball.Rarity.RARE: 30,
	Ball.Rarity.EPIC: 20,
	Ball.Rarity.LEGENDARY: 10,
}
# DECK Ball のレア度ごとの LV
const DECK_BALL_LEVEL_RARITY = {
	Ball.Rarity.UNCOMMON: [0, 1, 2, 3],
	Ball.Rarity.RARE: [4, 5, 6, 7],
	Ball.Rarity.EPIC: [8, 9, 10, 11],
	Ball.Rarity.LEGENDARY: [12, 13, 14, 15],
}
# EXTRA Ball のレア度ごとの LV
const EXTRA_BALL_LEVEL_RARITY = {
	Ball.Rarity.UNCOMMON: [6, 7, 8, 9],
	Ball.Rarity.RARE: [2, 3, 12, 13],
	Ball.Rarity.EPIC: [4, 5, 10, 11],
	Ball.Rarity.LEGENDARY: [0, 1, 14, 15],
}


# Scenes
@export var _ball_scene: PackedScene

# Nodes
@export var _billiards: Billiards
@export var _billiards_board: Area2D
@export var _pachinko: Pachinko
@export var _stack: Stack
@export var _balls_parent: Node2D

# UI
@export var _game_ui: GameUi
@export var _products_parent: Control
@export var _bunny: Bunny


# ゲームの状態
var game_state: GameState = GameState.GAME

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

# ビリヤード盤面上の Ball の数
# TODO: pachinko も stack も カウントしてるので parent node を分けるか enum var でフィルターできるようにする
var billiards_balls: int = 0:
	get:
		return _balls_parent.get_children().filter(func(ball: Ball): return ball.is_on_billiards).size()


# 次に訪れる TAX_LIST の index
var _next_tax_index: int = 0

# 現在ドラッグ中かどうか
var _is_dragging: bool = false
# ドラッグを開始した座標
var _drag_position_from: Vector2
# 現在ドラッグしている座標
var _drag_position_to: Vector2
# 引っ張りで Ball が吹き飛ぶ強さ
# NOTE: DRAG_LENGTH_MAX と反比例させる
var _impulse_ratio: float = 10

# 出現する Deck Ball のリストの初期値
var _deck_ball_list: Array[Ball] = [
	Ball.new(0, Ball.Rarity.COMMON),
	Ball.new(0, Ball.Rarity.COMMON),
	Ball.new(0, Ball.Rarity.COMMON),
	Ball.new(0, Ball.Rarity.COMMON),
	Ball.new(1, Ball.Rarity.COMMON),
	Ball.new(1, Ball.Rarity.COMMON),
	Ball.new(1, Ball.Rarity.COMMON),
	Ball.new(1, Ball.Rarity.COMMON),
]
# 出現する Extra Ball のリストの初期値
var _extra_ball_list: Array[Ball] = [
	Ball.new(2, Ball.Rarity.COMMON),
	Ball.new(3, Ball.Rarity.COMMON),
	Ball.new(4, Ball.Rarity.COMMON),
	Ball.new(5, Ball.Rarity.COMMON),
]
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

# { TweenType: Tween, ... } 
var _tweens: Dictionary = {}


func _ready() -> void:
	# 初期化 (ラベル用)
	turn = 0
	money = 1000
	balls = 0

	# Input
	_billiards_board.input_event.connect(_on_billiards_board_input)

	# Signal (GameUi)
	_game_ui.buy_balls_button_pressed.connect(_on_buy_balls_button_pressed)
	_game_ui.sell_balls_button_pressed.connect(_on_sell_balls_button_pressed)
	_game_ui.tax_pay_button_pressed.connect(_on_tax_pay_button_pressed)
	_game_ui.shop_exit_button_pressed.connect(_on_shop_exit_button_pressed)
	_game_ui.info_button_pressed.connect(_on_info_button_pressed)
	_game_ui.options_button_pressed.connect(_on_options_button_pressed)
	# Signal (Hole)
	for node in get_tree().get_nodes_in_group("hole"):
		if node is Hole:
			node.ball_entered.connect(_on_hole_ball_entered)
	# Signal (Product)
	for node in _products_parent.get_children():
		if node is Product:
			node.icon_pressed.connect(_on_product_icon_pressed)

	# UI (GameUi)
	_game_ui.refresh_balls_slot_deck(_deck_ball_list)
	_game_ui.refresh_balls_slot_extra(_extra_ball_list)
	_game_ui.refresh_deck_size(DECK_SIZE_MIN_DEFAULT, DECK_SIZE_MAX)
	_game_ui.refresh_extra_size(EXTRA_SIZE_MIN, EXTRA_SIZE_MAX_DEFAULT)
	_bunny.visible = false
	_refresh_next()
	# UI (Billiards)
	_billiards.refresh_balls_count(billiards_balls)

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

	if next_type == TaxType.MONEY:
		money -= next_amount
	elif next_type == TaxType.BALLS:
		balls -= next_amount

	_next_tax_index += 1
	_refresh_next()

	_game_ui.hide_tax_window()
	_game_ui.show_shop_window()
	game_state = GameState.SHOP


func _on_shop_exit_button_pressed() -> void:
	_refresh_next()
	_game_ui.hide_shop_window()
	_game_ui.hide_people_window()
	game_state = GameState.GAME


func _on_info_button_pressed() -> void:
	SceneManager.goto_scene(SceneManager.SceneType.INFORMATION)


func _on_options_button_pressed() -> void:
	SceneManager.goto_scene(SceneManager.SceneType.OPTIONS)


# Ball が Hole に落ちたときの処理
# TODO: hole_type ごとにメソッド分ける？
func _on_hole_ball_entered(hole: Hole, ball: Ball) -> void:
	#print("[Game] _on_hole_ball_entered(hole: %s, ball: %s)" % [ball.level, hole.hole_type])
	match hole.hole_type:

		Hole.HoleType.BILLIARDS:
			# Ball が有効化されていない場合: 何もしない (Ball は消失する)
			if not ball.is_active:
				return
			# ex: [EffectType.MONEY_UP_ON_FALL, 10]
			for effect_data in ball.effects:
				if effect_data[0] == BallEffect.EffectType.MONEY_UP_ON_FALL:
					money += effect_data[1]
					print("[Game/BallEffect] MONEY_UP_ON_FALL +%s" % [effect_data[1]])
			# パチンコ盤面上に同じ Ball を出現させる
			var new_ball = _create_new_ball(ball.level)
			new_ball.is_on_billiards = false
			_pachinko.spawn_ball(new_ball)

		Hole.HoleType.EXTRA:
			# ビリヤード盤面上にランダムな Extra Ball を出現させる
			var random_ball: Ball = _extra_ball_list.pick_random()
			var new_ball = _create_new_ball(random_ball.level, random_ball.rarity)
			new_ball.is_on_billiards = true
			_billiards.spawn_extra_ball(new_ball)
			# パチンコのラッシュ抽選を開始する
			_pachinko.start_lottery()

		Hole.HoleType.GAIN:
			var gain_plus: int = 0
			var gain_times: int = 1
			# ex: [EffectType.BILLIARDS_COUNT_GAIN_UP, 50, 1]
			for effect_data in _get_extra_ball_effects(BallEffect.EffectType.BILLIARDS_COUNT_GAIN_UP):
				if billiards_balls <= effect_data[1]:
					gain_plus += effect_data[2]
			# ex: [EffectType.BILLIARDS_COUNT_GAIN_UP_2, 5, 2]
			for effect_data in _get_extra_ball_effects(BallEffect.EffectType.BILLIARDS_COUNT_GAIN_UP):
				if billiards_balls <= effect_data[1]:
					gain_times += effect_data[2]
			# ex: [EffectType.DECK_COMPLETE_GAIN_UP, 3, 2]
			for effect_data in _get_extra_ball_effects(BallEffect.EffectType.DECK_COMPLETE_GAIN_UP):
				var complete_list = range(effect_data[1] + 1) # 3 以下 => [0, 1, 2, 3]
				for deck_ball in _deck_ball_list:
					complete_list = complete_list.filter(func(v): return v != deck_ball.level) # LV 以外を絞り込む = LV を消す
				if complete_list.is_empty():
					gain_times += effect_data[2]
			# ex: [EffectType.DECK_COUNT_GAIN_UP, 50, 1]
			for effect_data in _get_extra_ball_effects(BallEffect.EffectType.DECK_COUNT_GAIN_UP):
				if _deck_ball_list.size() <= effect_data[1]:
					gain_plus += effect_data[2]
			# ex: [EffectType.GAIN_UP, 3, 1]
			for effect_data in _get_extra_ball_effects(BallEffect.EffectType.GAIN_UP):
				if ball.level <= effect_data[1]:
					gain_plus += effect_data[2]
			# ex: [EffectType.GAIN_UP_2, 1, 2]
			for effect_data in _get_extra_ball_effects(BallEffect.EffectType.GAIN_UP_2):
				if ball.level == effect_data[1]:
					gain_times += effect_data[2]
			# ex: [EffectType.HOLE_GAIN_UP, 1]
			for effect_data in _get_extra_ball_effects(BallEffect.EffectType.HOLE_GAIN_UP):
				gain_plus += effect_data[1]
			print("[Game/BallEffect] XXXX_GAIN_UP(_2) +%s, x%s" % [gain_plus, gain_times])

			# 払い出しリストに追加する
			var amount = (hole.gain_ratio + gain_plus) * gain_times * ball.level
			_push_payout(ball.level, amount)

		Hole.HoleType.LOST:
			# 何もしない (Ball は消失する)
			pass

		Hole.HoleType.STACK:
			# Ball の数をカウントする
			balls += 1

	_billiards.refresh_balls_count(billiards_balls)


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
				var ball: Ball = _deck_ball_list.pick_random()
				var new_ball = _create_new_ball(ball.level, ball.rarity, false) # 最初の出現時には有効化されていない
				new_ball.is_on_billiards = true
				_billiards.spawn_ball(new_ball)
				# 1ターン進める
				# Ball 生成をなかったことにしてもこれはなかったことにはしない
				_go_to_next_turn()


# 商品のアイコンがクリックされたときの処理
# TODO: shop 的なのに切り分ける
func _on_product_icon_pressed(product: Product) -> void:
	# Money が足りない場合: 何もしない
	if money < product.price:
		_bunny.shuffle_pose()
		_bunny.refresh_dialogue_label("お金が足りないよ～")
		return

	# Product の効果を発動する
	# TODO: マジックナンバーをなくす？
	match product.product_type:

		Product.ProductType.DECK_PACK:
			if DECK_SIZE_MAX <= _deck_ball_list.size():
				return
			for i in 3:
				if DECK_SIZE_MAX <= _deck_ball_list.size():
					continue
				var level_rarity = _pick_random_rarity(true) # COMMON 抜き
				var level = DECK_BALL_LEVEL_RARITY[level_rarity].pick_random()
				_deck_ball_list.push_back(Ball.new(level))
				print("[Game] DECK_PACK level: %s (%s)" % [level, Ball.Rarity.keys()[level_rarity]])

		Product.ProductType.DECK_CLEANER:
			# ex: [EffectType.DECK_SIZE_MIN_DOWN, 1]
			var deck_size_min = DECK_SIZE_MIN_DEFAULT
			for effect_data in _get_extra_ball_effects(BallEffect.EffectType.DECK_SIZE_MIN_DOWN):
				deck_size_min -= effect_data[1]
			deck_size_min = clampi(deck_size_min, DECK_SIZE_MIN, deck_size_min)
			_game_ui.refresh_deck_size(deck_size_min, DECK_SIZE_MAX)
			print("[Game/BallEffect] DECK_SIZE_MIN_DOWN deck_size_min: %s" % [deck_size_min])

			if _deck_ball_list.size() <= deck_size_min:
				return
			_deck_ball_list.sort_custom(func(a: Ball, b: Ball): a.level < b.level)
			_deck_ball_list.pop_front()

		Product.ProductType.EXTRA_PACK:
			# ex: [EffectType.EXTRA_SIZE_MAX_UP, 2]
			var extra_size_max = EXTRA_SIZE_MAX_DEFAULT
			for effect_data in _get_extra_ball_effects(BallEffect.EffectType.EXTRA_SIZE_MAX_UP):
				extra_size_max += effect_data[1]
			extra_size_max = clampi(extra_size_max, extra_size_max, EXTRA_SIZE_MAX)
			_game_ui.refresh_extra_size(EXTRA_SIZE_MIN, extra_size_max)
			print("[Game/BallEffect] EXTRA_SIZE_MAX_UP extra_size_max: %s" % [extra_size_max])

			if extra_size_max <= _extra_ball_list.size():
				return
			for i in 2:
				if extra_size_max <= _extra_ball_list.size():
					continue
				var level_rarity = _pick_random_rarity(true) # COMMON 抜き
				var level = EXTRA_BALL_LEVEL_RARITY[level_rarity].pick_random()
				var rarity = _pick_random_rarity()
				_extra_ball_list.push_back(Ball.new(level, rarity))
				print("[Game] EXTRA_PACK level: %s (%s), rarity: %s" % [level, Ball.Rarity.keys()[level_rarity], Ball.Rarity.keys()[rarity]])

			# ex: [EffectType.HOLE_SIZE_UP, 1]
			var hole_size = 0
			for effect_data in _get_extra_ball_effects(BallEffect.EffectType.HOLE_SIZE_UP):
				hole_size += effect_data[1]
			# ex: [EffectType.HOLE_GRAVITY_SIZE_UP, 1]
			var gravity_size = 0
			for effect_data in _get_extra_ball_effects(BallEffect.EffectType.HOLE_GRAVITY_SIZE_UP):
				gravity_size += effect_data[1]
			print("[Game/BallEffect] HOLE(_GRAVITY)_SIZE_UP hole_size: %s, gravity_size: %s" % [hole_size, gravity_size])

			for node in get_tree().get_nodes_in_group("hole"):
				if node is Hole:
					if node.hole_type == Hole.HoleType.BILLIARDS:
						node.set_hole_size(hole_size)
						node.set_gravity_size(gravity_size)

			# ex: [EffectType.PACHINKO_START_TOP_UP, 1]
			var start_level = 0
			for effect_data in _get_extra_ball_effects(BallEffect.EffectType.PACHINKO_START_TOP_UP):
				start_level += effect_data[1]
			# ex: [EffectType.PACHINKO_CONTINUE_TOP_UP, 1]
			var continue_level = 0
			for effect_data in _get_extra_ball_effects(BallEffect.EffectType.PACHINKO_CONTINUE_TOP_UP):
				continue_level += effect_data[1]
			print("[Game/BallEffect] PACHINKO_(START/CONTINUE)_TOP_UP start_level: %s, continue_level: %s" % [start_level, continue_level])
			_pachinko.set_rush_start_top(start_level)
			_pachinko.set_rush_continue_top(continue_level)

		Product.ProductType.EXTRA_CLEANER:
			if _extra_ball_list.size() == 0:
				return
			_extra_ball_list.sort_custom(func(a: Ball, b: Ball): a.level < b.level)
			_extra_ball_list.pop_front()

	# return しなかった場合: Money を減らす
	money -= product.price

	# DECK, EXTRA の見た目を更新する
	_game_ui.refresh_balls_slot_deck(_deck_ball_list)
	_game_ui.refresh_balls_slot_extra(_extra_ball_list)


# EXTRA Ball 内の特定の効果をまとめて取得する
func _get_extra_ball_effects(target_effect_type: BallEffect.EffectType) -> Array:
	var effects = []
	for ball in _extra_ball_list:
		for effect_data in ball.effects:
			if target_effect_type == effect_data[0]:
				effects.append(effect_data)
	print("[Game] _get_extra_ball_effects(%s) -> %s" % [BallEffect.EffectType.keys()[target_effect_type], effects])
	return effects


# Ball instance を作成する
func _create_new_ball(level: int = 0, rarity: Ball.Rarity = Ball.Rarity.COMMON, is_active = true) -> Ball:
	var ball: Ball = _ball_scene.instantiate()
	ball.level = level
	ball.rarity = rarity
	ball.is_active = is_active
	_balls_parent.add_child(ball)
	_billiards.refresh_balls_count(billiards_balls)
	return ball


# 重み付きのレア度を抽選する
# exclude_common: COMMON 抜きの抽選を行う (Ball LV 用)
func _pick_random_rarity(exclude_common: bool = false) -> Ball.Rarity:
	var rarity_weight = RAIRTY_WEIGHT.duplicate()
	# ex: [EffectType.RARITY_TOP_UP, Ball.Rarity.RARE]
	for effect_data in _get_extra_ball_effects(BallEffect.EffectType.RARITY_TOP_UP):
		rarity_weight[effect_data[1]] += RAIRTY_WEIGHT[effect_data[1]]
	# ex: [EffectType.RARITY_TOP_DOWN, Ball.Rarity.COMMON]
	for effect_data in _get_extra_ball_effects(BallEffect.EffectType.RARITY_TOP_DOWN):
		var rarity_top_down = rarity_weight[effect_data[1]] - RAIRTY_WEIGHT[effect_data[1]] / 2
		rarity_weight[effect_data[1]] = clampi(rarity_top_down, 0, rarity_top_down)
	print("[Game/BallEffect] RARITY_TOP_UP(/DOWN) rarity_weight: %s" % [rarity_weight])

	# 抽選の分母 (合計)
	var rarity_weight_total = 0
	for rarity in RAIRTY_WEIGHT.keys():
		if exclude_common and rarity == Ball.Rarity.COMMON:
			continue
		else:
			rarity_weight_total += RAIRTY_WEIGHT[rarity]

	# 分母内の整数を抽選する
	var random = randi_range(0, rarity_weight_total)

	# 抽選した整数に対応するレア度を決定する
	var rarity_check = 0
	var random_rarity = Ball.Rarity.COMMON
	for rarity in RAIRTY_WEIGHT.keys():
		if exclude_common and rarity == Ball.Rarity.COMMON:
			continue
		else:
			random_rarity = rarity
			rarity_check += RAIRTY_WEIGHT[rarity]
			if random < rarity_check:
				break

	return random_rarity


# 払い出しキューの実行ループを開始する
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

	# 延長料支払いターンを超えている場合: カウントダウンを表示する
	var in_next_tax_turn = _next_tax_index < TAX_LIST.size() and TAX_LIST[_next_tax_index][0] < turn
	if in_next_tax_turn and game_state == GameState.GAME:
		_start_tax_count_down()


# Tax Window 表示までのカウントダウンを開始する
func _start_tax_count_down() -> void:
	game_state = GameState.COUNT_DOWN

	# バニーを表示する
	_bunny.visible = true
	_bunny.disable_touch() # バニーのタッチを無効にする
	_game_ui.show_people_window()
	_bunny.refresh_dialogue_label("延長のお時間で～す")

	# カウントダウンを開始する
	var tween = _get_tween(TweenType.TAX_COUNT_DOWN)
	tween.tween_interval(2.0)
	tween.tween_callback(func(): _bunny.refresh_dialogue_label("さ～～ん"))
	tween.tween_callback(func(): _bunny.shuffle_pose())
	tween.tween_interval(1.0)
	tween.tween_callback(func(): _bunny.refresh_dialogue_label("に～～い"))
	tween.tween_callback(func(): _bunny.shuffle_pose())
	tween.tween_interval(1.0)
	tween.tween_callback(func(): _bunny.refresh_dialogue_label("い～～ち"))
	tween.tween_callback(func(): _bunny.shuffle_pose())
	tween.tween_interval(1.0)
	# Tax Window を表示する
	tween.tween_callback(func(): _game_ui.show_tax_window())
	tween.tween_callback(func(): _bunny.refresh_dialogue_label("ゲームを続けたいなら延長料を払ってね～。\n真ん中の下らへんに出てるやつ。"))
	tween.tween_callback(func(): _bunny.shuffle_pose())
	tween.tween_callback(func(): _bunny.enable_touch()) # バニーのタッチを有効に戻す

	await tween.finished
	game_state = GameState.TAX


# Product に MONEY を伝達する
# TODO: Product ホバー時に値段もらってそこで比較する
func _set_money_to_products() -> void:
	for node in _products_parent.get_children():
		if node is Product:
			node.main_money = money


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
