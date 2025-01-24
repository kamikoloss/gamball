class_name Game
extends Node2D
# TODO: Ball 移動の処理を切り分ける
# TODO: 料金所の処理を切り分ける
# TODO: Shop の処理を切り分ける


signal exited


enum GameState { GAME, COUNT_DOWN, TAX, SHOP }
enum TaxType { MONEY, BALLS }
enum TweenType { PAYOUT, TAX_COUNT_DOWN }


# Ball を発射する強さ
const IMPULSE_RATIO: float = 16
# 何秒ごとに 1 Ball を払い出すか
const PAYOUT_INTERVAL_BASE: float = 0.1

# DECK の 最小数/最大数 の 絶対値/初期値
const DECK_SIZE_MIN: int = 4
const DECK_SIZE_MIN_DEFAULT: int = 8
const DECK_SIZE_MAX: int = 16
# EXTRA の 最小数/最大数の 絶対値/初期値
const EXTRA_SIZE_MIN: int = 0
const EXTRA_SIZE_MAX: int = 16
const EXTRA_SIZE_MAX_DEFAULT: int = 8

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
@export var _pachinko: Pachinko
@export var _stack: Stack
@export var _balls_parent: Node2D
@export var _drag_shooter: DragShooter

# UI
@export var _game_ui: GameUi
@export var _products_parent: Control
@export var _bunny: Bunny


# ゲームの状態
var game_state: GameState = GameState.GAME

var turn: int = 0:
	set(value):
		turn = value
		_game_ui.refresh_turn_label(value)
var money: int = 0:
	set(value):
		money = value
		_game_ui.refresh_money_label(value)
var balls: int = 0:
	set(value):
		balls = value
		_game_ui.refresh_balls_label(value)
		# ボールがない場合: DragShoter を無効化する
		# TODO: バグる
		_drag_shooter.enabled = 0 < balls

# ビリヤード盤面上の Ball の数
var billiards_balls: int = 0:
	get:
		return _balls_parent.get_children().filter(func(ball: Ball): return ball.is_on_billiards).size()


# 次に訪れる TAX_LIST の index
var _next_tax_index: int = 0
# TAX (MONEY/BALLS) の割引後のレート
var _tax_money_rate: float = 0.0
var _tax_balls_rate: float = 0.0

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
# DECK/EXTRA の 最小/最大 数
var _deck_size_min: int = DECK_SIZE_MIN_DEFAULT
var _deck_size_max: int = DECK_SIZE_MAX
var _extra_size_min: int = EXTRA_SIZE_MIN
var _extra_size_max: int = EXTRA_SIZE_MAX_DEFAULT

# 払い出しを行う Hole
var _payout_hole: Hole
# 払い出しキューが残っている Ball level のリスト
var _payout_level_list: Array[int] = []

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

	# Signal (DragShooter)
	_drag_shooter.pressed.connect(_on_drag_shooter_pressed)
	_drag_shooter.released.connect(_on_drag_shooter_released)
	_drag_shooter.canceled.connect(_on_drag_shooter_canceled)
	# Signal (GameUi)
	_game_ui.buy_balls_button_pressed.connect(_on_buy_balls_button_pressed)
	_game_ui.sell_balls_button_pressed.connect(_on_sell_balls_button_pressed)
	_game_ui.tax_pay_button_pressed.connect(_on_tax_pay_button_pressed)
	_game_ui.shop_exit_button_pressed.connect(_on_shop_exit_button_pressed)
	_game_ui.info_button_pressed.connect(_on_info_button_pressed)
	_game_ui.options_button_pressed.connect(_on_options_button_pressed)

	# Hole
	for node in get_tree().get_nodes_in_group("hole"):
		if node is Hole:
			node.ball_entered.connect(_on_hole_ball_entered)
			if node.hole_type == Hole.HoleType.WARP_FROM and node.warp_group == Hole.WarpGroup.PAYOUT:
				_payout_hole = node
	# Product
	for node in _products_parent.get_children():
		if node is Product:
			node.hovered.connect(_on_product_hovered)
			node.pressed.connect(_on_product_pressed)

	# UI
	_game_ui.refresh_tax_table(TAX_LIST)
	_game_ui.add_log("---- Start!! ----")
	_apply_extra_ball_effects()
	_refresh_deck_extra()
	_refresh_next()
	_billiards.refresh_balls_count(billiards_balls)

	# ボール購入ボタンを1プッシュする
	_on_buy_balls_button_pressed()
	# 払い出し処理を開始する
	_start_payout()


func _on_drag_shooter_pressed() -> void:
	# ビリヤード盤面上に Ball を生成する
	balls -= 1
	var ball: Ball = _deck_ball_list.pick_random()
	var new_ball = _create_new_ball(ball.level, ball.rarity, false) # 最初の出現時には有効化されていない
	new_ball.is_on_billiards = true
	_billiards.spawn_ball(new_ball)
	# 1ターン進める
	# NOTE: キャンセル時に Ball 生成をなかったことにしてもこれはなかったことにはしない
	_go_to_next_turn()

func _on_drag_shooter_released(drag_vector: Vector2) -> void:
	_billiards.shoot_ball(drag_vector * IMPULSE_RATIO)
	_billiards.refresh_balls_count(billiards_balls)

func _on_drag_shooter_canceled() -> void:
	# Ball 生成をなかったことにする
	if _billiards.rollback_spawn_ball():
		balls += 1


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
		next_amount = int(next_amount * _tax_money_rate)
		money -= next_amount
	elif next_type == TaxType.BALLS:
		next_amount = int(next_amount * _tax_balls_rate)
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
# TODO: hole_type ごとにメソッド分ける？ HoleManager 作る？
func _on_hole_ball_entered(hole: Hole, ball: Ball) -> void:
	#print("[Game] _on_hole_ball_entered(hole: %s, ball: %s)" % [ball.level, hole.hole_type])
	# Hole が無効の場合: 何もしない (通り抜ける)
	if not hole.is_enabled:
		return
	# Ball が縮小中の場合: 何もしない (通り抜ける)
	if ball.is_shrinked:
		return

	match hole.hole_type:

		Hole.HoleType.WARP_FROM:
			pass

		Hole.HoleType.WARP_TO:
			# Ball が有効化されていない場合: 消す
			if not ball.is_active:
				await ball.die()
				_billiards.refresh_balls_count(billiards_balls)
				return
			# ex: [EffectType.MONEY_UP_ON_FALL, 10]
			for effect_data in ball.effects:
				if effect_data[0] == BallEffect.EffectType.MONEY_UP_ON_FALL:
					money += effect_data[1]
					print("[Game/BallEffect] MONEY_UP_ON_FALL +%s" % [effect_data[1]])
			# 同じ GroupType の Hole に Ball をワープさせる
			ball.is_on_billiards = false
			for node in get_tree().get_nodes_in_group("hole"):
				if node is Hole:
					if node.hole_type == Hole.HoleType.WARP_FROM and node.warp_group == hole.warp_group:
						ball.warp_for_warp_to(node.global_position)
			# Hole を点滅させる
			hole.flash(1, Color.WHITE, 2)

		Hole.HoleType.EXTRA:
			# ビリヤード盤面上にランダムな Extra Ball を出現させる
			var random_ball: Ball = _extra_ball_list.pick_random()
			var new_ball = _create_new_ball(random_ball.level, random_ball.rarity)
			# ex: [EffectType.BILLIARDS_LV_UP_ON_SPAWN, 1]
			for effect_data in new_ball.effects:
				if effect_data[0] == BallEffect.EffectType.BILLIARDS_LV_UP_ON_SPAWN:
					var gain_level = effect_data[1]
					for target_ball: Ball in _balls_parent.get_children().filter(func(ball: Ball): return ball.is_on_billiards):
						target_ball.level += gain_level
						target_ball.refresh_view()
					print("[Game/BallEffect] BILLIARDS_LV_UP_ON_SPAWN +%s" % [gain_level])

			new_ball.is_on_billiards = true
			_billiards.spawn_extra_ball(new_ball)
			# パチンコのラッシュ抽選を開始する
			_pachinko.start_lottery()
			# Hole を点滅させる
			hole.flash(1, Color.GREEN, 2)

		Hole.HoleType.GAIN:
			if not ball:
				return

			if ball.is_gained:
				return
			ball.is_gained = true

			# Gain 増加系の BallEffect を確認する
			var gain_plus: int = 0 # Gain がいくつ増えるか
			var gain_times: int = 1 # Gain が何倍になるか
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
					complete_list = complete_list.filter(func(v): return v != deck_ball.level) # LV 以外に絞り込む = LV を消す
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
			if gain_plus != 0 and gain_times != 1:
				print("[Game/BallEffect] XXXX_GAIN_UP(_2) +%s, x%s" % [gain_plus, gain_times])

			# Ball を増加させてワープさせる
			var level = ball.level # NOTE: ここで控えとかないと参照できないことがある
			var amount = (hole.gain_ratio + gain_plus) * gain_times * level
			if 0 < amount:
				var tween = create_tween()
				tween.set_loops(amount)
				tween.tween_interval(1.0 / 20)
				tween.tween_callback(func():
					# TODO: すごい数になるので Ball じゃなくて画像にした方がいい？
					var new_ball: Ball = _ball_scene.instantiate()
					new_ball.level = level
					new_ball.is_shrinked = true
					_balls_parent.add_child(new_ball)
					await new_ball.warp_for_gain(hole.global_position, _payout_hole.global_position)
					_push_payout(level, 1)
					new_ball.queue_free()
				)
			# PopupScore を表示する
			var popup_text = "+%s" % [amount]
			var popup_color = Color.WHITE
			var popup_size = clamp(amount / 10, 1.0, 4.0) # TODO: const
			if amount <= 0:
				popup_text = "%s" % [amount]
				popup_color = Color.RED
			_game_ui.popup_score(hole.global_position, popup_text, popup_color, popup_size)
			# ログを出す
			var log = "(%s + %s) x %s x %s = %s" % [level, gain_plus, hole.gain_ratio, gain_times, amount]
			_game_ui.add_log(log)
			# Hole を点滅させる
			if hole.gain_ratio == 0:
				hole.flash(1, Color.RED, 2)
			else:
				hole.flash(hole.gain_ratio, Color.WHITE)

		Hole.HoleType.LOST:
			await ball.die()
			_billiards.refresh_balls_count(billiards_balls)

		Hole.HoleType.STACK:
			if ball.is_stacked:
				return
			ball.is_stacked = true
			balls += 1

	# Ball 消去処理
	var not_die_types = [Hole.HoleType.WARP_FROM, Hole.HoleType.WARP_TO]
	if not hole.hole_type in not_die_types:
		await ball.die()

	_billiards.refresh_balls_count(billiards_balls)


# 商品をホバーしたときの処理
func _on_product_hovered(product: Product, hover: bool) -> void:
	if money < product.price:
		product.disable()
	else:
		product.enable()
	product.refresh_view()

# 商品をクリックしたときの処理
func _on_product_pressed(product: Product) -> void:
	# Money が足りない場合: 何もしない
	if money < product.price:
		# TODO: 購入できない理由がいくつかあるときラベルを分ける？
		_bunny.shuffle_pose()
		_bunny.refresh_dialogue_label("お金が足りないよ～")
		return

	# Product の効果を発動する
	# TODO: マジックナンバーをなくす？
	match product.product_type:

		Product.ProductType.DECK_PACK:
			if _deck_size_max <= _deck_ball_list.size():
				return
			for i in 2:
				if _deck_size_max <= _deck_ball_list.size():
					continue
				var level_rarity = _pick_random_rarity(true) # COMMON 抜き
				var level = DECK_BALL_LEVEL_RARITY[level_rarity].pick_random()
				_deck_ball_list.push_back(Ball.new(level))
				print("[Game] DECK_PACK level: %s (%s)" % [level, Ball.Rarity.keys()[level_rarity]])

		Product.ProductType.DECK_CLEANER:
			if _deck_ball_list.size() <= _deck_size_min:
				return
			_deck_ball_list.sort_custom(func(a: Ball, b: Ball): return a.level < b.level)
			_deck_ball_list.pop_front()

		Product.ProductType.EXTRA_PACK:
			if _extra_size_max <= _extra_ball_list.size():
				return
				# TODO: あふれるとき注意出す？
			for i in 2:
				if _extra_size_max <= _extra_ball_list.size():
					continue
				var level_rarity = _pick_random_rarity(true) # COMMON 抜き
				var level = EXTRA_BALL_LEVEL_RARITY[level_rarity].pick_random()
				var rarity = _pick_random_rarity()
				_extra_ball_list.push_back(Ball.new(level, rarity))
				print("[Game] EXTRA_PACK level: %s (%s), rarity: %s" % [level, Ball.Rarity.keys()[level_rarity], Ball.Rarity.keys()[rarity]])
			_apply_extra_ball_effects()

		Product.ProductType.EXTRA_CLEANER:
			if _extra_ball_list.size() == 0:
				return
			_extra_ball_list.sort_custom(func(a: Ball, b: Ball): return a.level < b.level)
			var popped_ball: Ball = _extra_ball_list.pop_front()
			# ex: [EffectType.MONEY_UP_ON_BREAK, 2]
			var money_times = 1
			for effect_data in popped_ball.effects:
				if effect_data[0] == BallEffect.EffectType.MONEY_UP_ON_BREAK:
					money_times *= effect_data[1]
				print("[Game/BallEffect] MONEY_UP_ON_BREAK x%s" % [money_times])
			if 1 < money_times:
				money *= money_times

	# return しなかった場合: Money を減らす
	money -= product.price
	# Money が減ったのでホバー時処理をやり直す
	_on_product_hovered(product, true)

	# DECK/EXTRA の見た目を更新する
	_refresh_deck_extra()


# EXTRA Ball の効果をまとめて反映する
func _apply_extra_ball_effects() -> void:
	# ex: [EffectType.DECK_SIZE_MIN_DOWN, 1]
	var new_deck_size_min = DECK_SIZE_MIN_DEFAULT
	for effect_data in _get_extra_ball_effects(BallEffect.EffectType.DECK_SIZE_MIN_DOWN):
		new_deck_size_min -= effect_data[1]
	_deck_size_min = clampi(new_deck_size_min, DECK_SIZE_MIN, new_deck_size_min)
	print("[Game/BallEffect] DECK_SIZE_MIN_DOWN _deck_size_min: %s" % [_deck_size_min])

	# ex: [EffectType.EXTRA_SIZE_MAX_UP, 2]
	var new_extra_size_max = EXTRA_SIZE_MAX_DEFAULT
	for effect_data in _get_extra_ball_effects(BallEffect.EffectType.EXTRA_SIZE_MAX_UP):
		new_extra_size_max += effect_data[1]
	_extra_size_max = clampi(new_extra_size_max, new_extra_size_max, EXTRA_SIZE_MAX)
	print("[Game/BallEffect] EXTRA_SIZE_MAX_UP _extra_size_max: %s" % [_extra_size_max])

	# ex: [EffectType.HOLE_SIZE_UP, 1]
	var hole_size_level = 0
	for effect_data in _get_extra_ball_effects(BallEffect.EffectType.HOLE_SIZE_UP):
		hole_size_level += effect_data[1]
	# ex: [EffectType.HOLE_GRAVITY_SIZE_UP, 1]
	var gravity_size_level = 0
	for effect_data in _get_extra_ball_effects(BallEffect.EffectType.HOLE_GRAVITY_SIZE_UP):
		gravity_size_level += effect_data[1]
	for node in get_tree().get_nodes_in_group("hole"):
		if node is Hole:
			if node.hole_type == Hole.HoleType.WARP_TO:
				node.set_hole_size(hole_size_level)
				node.set_gravity_size(gravity_size_level)
	print("[Game/BallEffect] HOLE(_GRAVITY)_SIZE_UP hole_size_level: %s, gravity_size_level: %s" % [hole_size_level, gravity_size_level])

	# ex: [EffectType.PACHINKO_START_TOP_UP, 1]
	var start_level = 0
	for effect_data in _get_extra_ball_effects(BallEffect.EffectType.PACHINKO_START_TOP_UP):
		start_level += effect_data[1]
	_pachinko.set_rush_start_top(start_level)
	# ex: [EffectType.PACHINKO_CONTINUE_TOP_UP, 1]
	var continue_level = 0
	for effect_data in _get_extra_ball_effects(BallEffect.EffectType.PACHINKO_CONTINUE_TOP_UP):
		continue_level += effect_data[1]
	_pachinko.set_rush_continue_top(continue_level)
	print("[Game/BallEffect] PACHINKO_(START/CONTINUE)_TOP_UP start_level: %s, continue_level: %s" % [start_level, continue_level])

	# ex. [EffectType.TAX_MONEY_DOWN, 10]
	var tax_money_off_per: int = 0
	for effect_data in _get_extra_ball_effects(BallEffect.EffectType.TAX_MONEY_DOWN):
		tax_money_off_per += effect_data[1]
	_tax_money_rate = 1 - clampi(tax_money_off_per, 0, 50) / 100.0 # TODO: const
	# ex. [EffectType.TAX_BALLS_DOWN, 10]
	var tax_balls_off_per: int = 0
	for effect_data in _get_extra_ball_effects(BallEffect.EffectType.TAX_BALLS_DOWN):
		tax_balls_off_per += effect_data[1]
	_tax_balls_rate = 1 - clampi(tax_balls_off_per, 0, 50) / 100.0 # TODO: const
	print("[Game/BallEffect] TAX_(MONEY/BALLS)_DOWN _tax_money_rate: %s, _tax_balls_rate" % [_tax_money_rate, _tax_balls_rate])

	_refresh_deck_extra()
	_refresh_next()


# EXTRA Ball 内の特定の効果をまとめて取得する
func _get_extra_ball_effects(target_effect_type: BallEffect.EffectType) -> Array:
	var effects = []
	for ball in _extra_ball_list:
		for effect_data in ball.effects:
			if target_effect_type == effect_data[0]:
				effects.append(effect_data)
	#print("[Game] _get_extra_ball_effects(%s) -> %s" % [BallEffect.EffectType.keys()[target_effect_type], effects])
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
func _start_payout(payout_speed_ratio: float = 1.0) -> void:
	var delay = PAYOUT_INTERVAL_BASE / payout_speed_ratio
	var tween = _get_tween(TweenType.PAYOUT)
	tween.set_loops()
	tween.tween_callback(_pop_payout).set_delay(delay)

# 払い出しキューを実行する
func _pop_payout() -> void:
	if _payout_level_list.is_empty():
		return
	var level = _payout_level_list.pop_front()
	var new_ball = _create_new_ball(level)
	new_ball.position = _payout_hole.position
	new_ball.apply_impulse(Vector2(0, randi_range(400, 500))) 
	_game_ui.refresh_payout_label(_payout_level_list.size())

# 払い出しキューに追加する
func _push_payout(level: int, amount: int) -> void:
	for i in amount:
		_payout_level_list.push_back(level)
	_game_ui.refresh_payout_label(_payout_level_list.size())

	var payout_size = _payout_level_list.size()
	if payout_size < 100:
		_start_payout(1.0)
	elif payout_size < 1000:
		_start_payout(2.0)
	elif payout_size < 10000:
		_start_payout(3.0)
	else:
		_start_payout(4.0)


# DECK/EXTRA の見た目を更新する
func _refresh_deck_extra() -> void:
	_game_ui.refresh_deck_balls(_deck_ball_list, _deck_size_min, _deck_size_max)
	_game_ui.refresh_deck_slots(_deck_size_min, _deck_size_max)
	_game_ui.refresh_extra_balls(_extra_ball_list, _extra_size_min, _extra_size_max)
	_game_ui.refresh_extra_slots(_extra_size_min, _extra_size_max)


# Next 関連の見た目を更新する
func _refresh_next() -> void:
	if _next_tax_index < TAX_LIST.size():
		var turn = TAX_LIST[_next_tax_index][0]
		var type = TAX_LIST[_next_tax_index][1]
		var amount = TAX_LIST[_next_tax_index][2]
		if type == TaxType.MONEY:
			amount = int(amount * _tax_money_rate)
		elif type == TaxType.BALLS:
			amount = int(amount * _tax_balls_rate)
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

	_bunny.visible = true
	_game_ui.show_people_window()
	await _bunny.countdown()
	_game_ui.show_tax_window()

	game_state = GameState.TAX


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
