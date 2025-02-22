class_name Game
extends Node2D
# TODO: 料金所の処理を切り分ける
# TODO: Shop の処理を切り分ける


signal exited


enum GameState { GAME, COUNT_DOWN, TAX, SHOP }
enum ComboState { IDLE, CONTINUE, COOLTIME }
enum TweenType { COMBO, TAX_COUNT_DOWN }


# Ball を発射する強さ
const IMPULSE_RATIO : = 16.0

# DECK の 最小数/最大数 の 絶対値/初期値
const DECK_SIZE_MIN := 2
const DECK_SIZE_MIN_DEFAULT = 5
const DECK_SIZE_MAX := 9
# EXTRA の 最小数/最大数の 絶対値/初期値
const EXTRA_SIZE_MIN := 2
const EXTRA_SIZE_MAX := 9
const EXTRA_SIZE_MAX_DEFAULT := 5

# Tax のリスト
# [ <turn>, <amount> ]
const TAX_LIST := [
	[25, 50], [50, 100], [75, 200], [100, 400],
	[150, 800], [200, 1600],
	[250, 3200], [300, 6400],
]

# レア度の割合
const RAIRTY_WEIGHT := {
	Ball.Rarity.COMMON: 50,
	Ball.Rarity.UNCOMMON: 40,
	Ball.Rarity.RARE: 30,
	Ball.Rarity.EPIC: 20,
	Ball.Rarity.LEGENDARY: 10,
}
# DECK Ball の番号の排出率
const DECK_BALL_NUMBER_RARITY := {
	Ball.Rarity.UNCOMMON: [0, 1, 2, 3],
	Ball.Rarity.RARE: [4, 5, 6, 7],
	Ball.Rarity.EPIC: [8, 9, 10, 11],
	Ball.Rarity.LEGENDARY: [12, 13, 14, 15],
}
# EXTRA Ball の番号の排出率
const EXTRA_BALL_NUMBER_RARITY := {
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
@export var _balls_parent: Node2D
@export var _drag_shooter: DragShooter
@export var _stack_wall_bottom: StaticBody2D

# UI
@export var _game_ui: GameUi


# 経過ターン数
var _turn := 0:
	set(v):
		_turn = v
		_game_ui.update_turn_label(_turn)
# 所持ボール数
var _balls := 0:
	set(v):
		# ボールの個数が 0 から回復したとき: DragShooter を有効化する
		if _balls <= 0 and 0 < v:
			_drag_shooter.disabled = false
		_balls = v
		_game_ui.update_balls_label(_balls)
# ゲームの状態
var _game_state := GameState.GAME:
	set(v):
		if _game_state != v:
			_game_state = v
			_on_change_game_state(v)
			print("[Game] _game_state changed to %s" % [GameState.keys()[v]])
# コンボの状態
var _combo_state := ComboState.IDLE:
	set(v):
		if _combo_state != v:
			_combo_state = v
			#print("[Game] _combo_state changed to %s" % [ComboState.keys()[v]])
# ビリヤード盤面上の Ball の数
var _billiards_balls_count := 0:
	get:
		return _balls_parent.get_children().filter(func(ball: Ball): return ball.is_on_billiards).size()

# 次に訪れる TAX_LIST の index
var _next_tax_index := 0
# 延長料の割引後のレート
var _tax_rate := 0.0
# アイテム価格の割引後のレート
var _product_price_rate := 0.0

# DECK/EXTRA
var _deck_ball_list: Array[Ball] = []
var _extra_ball_list: Array[Ball] = []
# DECK/EXTRA の 最小/最大 数
var _deck_size_min := DECK_SIZE_MIN_DEFAULT
var _deck_size_max := DECK_SIZE_MAX
var _extra_size_min := EXTRA_SIZE_MIN
var _extra_size_max := EXTRA_SIZE_MAX_DEFAULT

# 払い出しを行う Hole
var _payout_hole: Hole
# { TweenType: Tween, ... } 
var _tweens := {}


func _ready() -> void:
	print("[Game] ready.")

	# Signal (DragShooter)
	_drag_shooter.pressed.connect(_on_drag_shooter_pressed)
	_drag_shooter.released.connect(_on_drag_shooter_released)
	_drag_shooter.canceled.connect(_on_drag_shooter_canceled)
	# Signal (GameUi)
	_game_ui.info_button_pressed.connect(_on_info_button_pressed)
	_game_ui.options_button_pressed.connect(_on_options_button_pressed)
	_game_ui.tax_pay_button_pressed.connect(_on_tax_pay_button_pressed)
	_game_ui.shop_exit_button_pressed.connect(_on_shop_exit_button_pressed)
	_game_ui.product_hovered.connect(_on_product_hovered)
	_game_ui.product_pressed.connect(_on_product_pressed)

	# Hole
	for node in get_tree().get_nodes_in_group("hole"):
		if node is Hole:
			node.ball_entered.connect(_on_hole_ball_entered)
			if node.hole_type == Hole.HoleType.WARP_FROM and node.warp_group == Hole.WarpGroup.PAYOUT:
				_payout_hole = node

	# UI
	_game_ui.combo_bar_progress = 0.0
	_game_ui.add_log("---- Start!! ----")
	_apply_extra_ball_effects()
	_refresh_deck_extra()
	_refresh_next()
	_billiards.update_balls_count(_billiards_balls_count)


func initialize() -> void:
	print("[Game] initialized.")
	_turn = SaveManager.game_run.turn
	_balls = SaveManager.game_run.balls
	_deck_ball_list = SaveManager.game_run.deck
	_extra_ball_list = SaveManager.game_run.extra
	var billiards_balls := SaveManager.game_run.billiards

	# 新規ゲーム用
	if _turn < 0:
		_turn = 0
		_balls = 100
		var deck_numbers := [0, 0, 0, 1, 1]
		var extra_numbers := [1, 2, 3]
		var billiards_numbers_postions := {
			1: [280, 380],
			8: [260, 360], 2: [300, 360],
			7: [240, 340], 9: [280, 340], 3: [320, 340],
			6: [260, 320], 4: [300, 320],
			5: [280, 300],
		}
		for number in deck_numbers:
			var ball := Ball.new(number, Ball.Rarity.COMMON)
			_deck_ball_list.append(ball)
		for number in extra_numbers:
			var ball := Ball.new(number, Ball.Rarity.COMMON)
			_extra_ball_list.append(ball)
		for number in billiards_numbers_postions.keys():
			var ball := Ball.new(number, Ball.Rarity.COMMON)
			var pos = billiards_numbers_postions[number]
			ball.global_position = Vector2(pos[0], pos[1])
			billiards_balls.append(ball)

	for ball_data: Ball in billiards_balls:
		var ball: Ball = _ball_scene.instantiate()
		ball.number = ball_data.number
		ball.rarity = ball_data.rarity
		ball.is_active = ball_data.is_active
		ball.is_on_billiards = true
		ball.global_position = ball_data.global_position
		_balls_parent.add_child(ball)
	_billiards.update_balls_count(_billiards_balls_count)


func _save_run() -> void:
	var billiards_balls: Array[Ball]
	for ball: Ball in _balls_parent.get_children():
		billiards_balls.append(ball)
	SaveManager.game_run.turn = _turn
	SaveManager.game_run.balls = _balls
	SaveManager.game_run.deck = _deck_ball_list
	SaveManager.game_run.extra = _extra_ball_list
	SaveManager.game_run.billiards = billiards_balls
	SaveManager.save_game()


func _on_change_game_state(state: GameState) -> void:
	match state:
		GameState.GAME:
			_game_ui.hide_shop_window()
			_game_ui.change_target_bubble(false)
			await _game_ui.change_bunny_size(false)
			_game_ui.set_dialogue(tr("bunny_move_finished"))
		GameState.COUNT_DOWN:
			_game_ui.change_target_bubble(true)
			await _game_ui.change_bunny_size(true)
			await _game_ui.count_down()
			_game_state = GameState.TAX # カウントダウンが終わったら自動で TAX まで移行する
		GameState.TAX:
			_game_ui.show_tax_window()
			_game_ui.set_dialogue_with_bunny(tr("bunny_tax_start"))
		GameState.SHOP:
			_game_ui.hide_tax_window()
			_game_ui.show_shop_window()
			_game_ui.set_dialogue_with_bunny(tr("bunny_shop_start"))


func _on_drag_shooter_pressed() -> void:
	if _deck_ball_list.is_empty():
		return
	# ビリヤード盤面上に Ball を生成する
	_balls -= 1
	var ball: Ball = _deck_ball_list.pick_random()
	var new_ball: Ball = _create_new_ball(ball.number, ball.rarity, false) # 最初の出現時には有効化されていない
	new_ball.is_on_billiards = true
	_billiards.spawn_ball(new_ball)
	# 1ターン進める
	# NOTE: キャンセル時に Ball 生成をなかったことにしてもこれはなかったことにはしない
	_turn += 1
	# 延長料支払いターンを超えている場合: カウントダウンを表示する
	var in_next_tax_turn = _next_tax_index < TAX_LIST.size() and TAX_LIST[_next_tax_index][0] <= _turn
	if in_next_tax_turn and _game_state == GameState.GAME:
		_game_state = GameState.COUNT_DOWN

func _on_drag_shooter_released(drag_vector: Vector2) -> void:
	_billiards.shoot_ball(drag_vector * IMPULSE_RATIO)
	_billiards.update_balls_count(_billiards_balls_count)
	# 発射した結果ボールがなくなった場合: 発射できなくする
	if _balls <= 0:
		_drag_shooter.disabled = true

func _on_drag_shooter_canceled() -> void:
	# Ball 生成をなかったことにする
	if _billiards.rollback_spawn_ball():
		_balls += 1


func _on_info_button_pressed() -> void:
	SceneManager.goto_scene(SceneManager.SceneType.INFORMATION)

func _on_options_button_pressed() -> void:
	SceneManager.goto_scene(SceneManager.SceneType.OPTIONS)


func _on_tax_pay_button_pressed() -> void:
	# Tax のフェーズを移行する
	var next_turn = TAX_LIST[_next_tax_index][0]
	var next_amount = TAX_LIST[_next_tax_index][1]
	_balls -= int(next_amount * _tax_rate)
	_next_tax_index += 1
	_refresh_next()
	_game_state = GameState.SHOP


func _on_shop_exit_button_pressed() -> void:
	_refresh_next()
	_game_state = GameState.GAME


# Ball が Hole に落ちたときの処理
# TODO: hole_type ごとにメソッド分ける？ HoleManager 作る？
func _on_hole_ball_entered(hole: Hole, ball: Ball) -> void:
	#print("[Game] _on_hole_ball_entered(hole: %s, ball: %s)" % [ball.number, hole.hole_type])
	if not hole or not ball:
		return
	# Hole が無効の場合: 何もしない (通り抜ける)
	if hole.disabled:
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
				_billiards.update_balls_count(_billiards_balls_count)
				return
			# ex: [Type.BALLS_UP_FALL, 10]
			for effect_data in ball.effects:
				if effect_data[0] == BallEffect.Type.BALLS_UP_FALL:
					_balls += effect_data[1]
					print("[Game/BallEffect] BALLS_UP_FALL +%s" % [effect_data[1]])
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
			var new_ball = _create_new_ball(random_ball.number, random_ball.rarity)
			# ex: [Type.NUMBER_UP_SPAWN, 1]
			for effect_data in new_ball.effects:
				if effect_data[0] == BallEffect.Type.NUMBER_UP_SPAWN:
					var gain_number = effect_data[1]
					for target_ball: Ball in _balls_parent.get_children().filter(func(ball: Ball): return ball.is_on_billiards):
						target_ball.number += gain_number
						target_ball.refresh_view()
					print("[Game/BallEffect] NUMBER_UP_SPAWN +%s" % [gain_number])

			new_ball.is_on_billiards = true
			_billiards.spawn_extra_ball(new_ball)
			# パチンコのラッシュ抽選を開始する
			_pachinko.start_lottery()
			# Hole を点滅させる
			hole.flash(1, Color.GREEN, 2)

		Hole.HoleType.GAIN:
			if ball.is_gained:
				return
			ball.is_gained = true

			# Gain 増加系の BallEffect を確認する
			var gain_plus: int = 0 # Gain がいくつ増えるか
			var gain_times: int = 1 # Gain が何倍になるか
			# ex: [Type.GAIN_UP_BL_COUNT, 50, 1]
			for effect_data in _get_extra_ball_effects(BallEffect.Type.GAIN_UP_BL_COUNT):
				if _billiards_balls_count <= effect_data[1]:
					gain_plus += effect_data[2]
			# ex: [Type.GAIN_UP_BL_COUNT_2, 5, 2]
			for effect_data in _get_extra_ball_effects(BallEffect.Type.GAIN_UP_BL_COUNT):
				if _billiards_balls_count <= effect_data[1]:
					gain_times += effect_data[2]
			# ex: [Type.GAIN_UP_DECK_COMPLETE, 3, 2]
			for effect_data in _get_extra_ball_effects(BallEffect.Type.GAIN_UP_DECK_COMPLETE):
				var complete_list = range(effect_data[1] + 1) # 3 以下 => [0, 1, 2, 3]
				for deck_ball in _deck_ball_list:
					complete_list = complete_list.filter(func(v): return v != deck_ball.number) # LV 以外に絞り込む = LV を消す
				if complete_list.is_empty():
					gain_times += effect_data[2]
			# ex: [Type.GAIN_UP_DECK_COUNT, 50, 1]
			for effect_data in _get_extra_ball_effects(BallEffect.Type.GAIN_UP_DECK_COUNT):
				if _deck_ball_list.size() <= effect_data[1]:
					gain_plus += effect_data[2]
			# ex: [Type.GAIN_UP, 3, 1]
			for effect_data in _get_extra_ball_effects(BallEffect.Type.GAIN_UP_BALL_NUMBER):
				if ball.number <= effect_data[1]:
					gain_plus += effect_data[2]
			# ex: [Type.GAIN_UP_BALL_NUMBER_2, 1, 2]
			for effect_data in _get_extra_ball_effects(BallEffect.Type.GAIN_UP_BALL_NUMBER_2):
				if ball.number == effect_data[1]:
					gain_times += effect_data[2]
			# ex: [Type.GAIN_UP_HOLE, 1]
			for effect_data in _get_extra_ball_effects(BallEffect.Type.GAIN_UP_HOLE):
				gain_plus += effect_data[1]
			if gain_plus != 0 and gain_times != 1:
				print("[Game/BallEffect] XXXX_GAIN_UP(_2) +%s, x%s" % [gain_plus, gain_times])

			# Ball を増加させてワープさせる
			var level = ball.number # NOTE: ここで控えとかないと参照できないことがある
			var amount = level * (hole.gain_ratio + gain_plus) * gain_times
			if 0 < amount:
				var tween = create_tween()
				tween.set_loops(amount)
				tween.tween_interval(1.0 / 10) # TODO: const
				tween.tween_callback(func():
					var new_ball: Ball = _ball_scene.instantiate()
					new_ball.number = level
					_balls_parent.add_child(new_ball)
					await new_ball.warp_for_gain(hole.global_position, _payout_hole.global_position)
					_balls += 1
					_start_combo()
					new_ball.queue_free() # TODO: バラまくなら死なさなくていい
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
			var log = "%s x (%s + %s) x %s = %s" % [level, hole.gain_ratio, gain_plus, gain_times, amount]
			_game_ui.add_log(log)
			# Hole を点滅させる
			if hole.gain_ratio == 0:
				hole.flash(1, Color.RED, 2)
			else:
				hole.flash(hole.gain_ratio, Color.WHITE)

		Hole.HoleType.LOST:
			await ball.die()
			_billiards.update_balls_count(_billiards_balls_count)


	# Ball 消去処理
	var not_die_types = [Hole.HoleType.WARP_FROM, Hole.HoleType.WARP_TO]
	if not hole.hole_type in not_die_types:
		await ball.die()

	_billiards.update_balls_count(_billiards_balls_count)


# 商品をホバーしたときの処理
func _on_product_hovered(product: Product, hover: bool) -> void:
	#print("[Game] _on_product_hovered(%s, %s)" % [product, hover])
	product.disabled = _balls < product.price


# 商品をクリックしたときの処理
func _on_product_pressed(product: Product) -> void:
	#print("[Game] _on_product_pressed(%s)" % [product])
	# BALLS が足りない場合: 何もしない
	if _balls < product.price:
		# TODO: 購入できない理由がいくつかあるときラベルを分ける？
		_game_ui.set_dialogue_with_bunny(tr("bunny_no_money"))
		return

	# Product の効果を発動する
	# TODO: マジックナンバーをなくす？
	match product.type:

		Product.Type.DECK_PACK:
			if _deck_size_max <= _deck_ball_list.size():
				return
			for i in 2:
				if _deck_size_max <= _deck_ball_list.size():
					continue
				var number_rarity = _pick_random_rarity(true) # COMMON 抜き
				var number = DECK_BALL_NUMBER_RARITY[number_rarity].pick_random()
				_deck_ball_list.push_back(Ball.new(number))
				print("[Game] DECK_PACK level: %s (%s)" % [number, Ball.Rarity.keys()[number_rarity]])

		Product.Type.DECK_CLEANER:
			if _deck_ball_list.size() <= _deck_size_min:
				return
			#_deck_ball_list.sort_custom(func(a: Ball, b: Ball): return a.level < b.level)
			_deck_ball_list.pop_front()

		Product.Type.EXTRA_PACK:
			if _extra_size_max <= _extra_ball_list.size():
				return
				# TODO: あふれるとき注意出す？
			for i in 2:
				if _extra_size_max <= _extra_ball_list.size():
					continue
				var number_rarity = _pick_random_rarity(true) # COMMON 抜き
				var number = EXTRA_BALL_NUMBER_RARITY[number_rarity].number_rarity()
				var rarity = _pick_random_rarity()
				_extra_ball_list.push_back(Ball.new(number, rarity))
				print("[Game] EXTRA_PACK level: %s (%s), rarity: %s" % [number, Ball.Rarity.keys()[number_rarity], Ball.Rarity.keys()[rarity]])
			_apply_extra_ball_effects()

		Product.Type.EXTRA_CLEANER:
			if _extra_ball_list.size() == 0:
				return
			var popped_ball: Ball = _extra_ball_list.pop_front()
			# ex: [Type.BALLS_UP_BREAK, 2]
			var balls_times = 1
			for effect_data in popped_ball.effects:
				if effect_data[0] == BallEffect.Type.BALLS_UP_BREAK:
					balls_times *= effect_data[1]
				print("[Game/BallEffect] BALLS_UP_BREAK x%s" % [balls_times])
			if 1 < balls_times:
				_balls *= balls_times

	# return しなかった場合: Balls を減らす
	_balls -= product.price
	# Balls が減ったのでホバー時処理をやり直す
	_on_product_hovered(product, true)
	# DECK/EXTRA の見た目を更新する
	_refresh_deck_extra()


# EXTRA Ball の効果をまとめて反映する
func _apply_extra_ball_effects() -> void:
	# ex: [Type.DECK_SIZE_MIN_DOWN, 1]
	var new_deck_size_min := DECK_SIZE_MIN_DEFAULT
	for effect_data in _get_extra_ball_effects(BallEffect.Type.DECK_SIZE_MIN_DOWN):
		new_deck_size_min -= effect_data[1]
	_deck_size_min = clampi(new_deck_size_min, DECK_SIZE_MIN, new_deck_size_min)
	print("[Game/BallEffect] DECK_SIZE_MIN_DOWN _deck_size_min: %s" % [_deck_size_min])
	# ex: [Type.EXTRA_SIZE_MAX_UP, 2]
	var new_extra_size_max := EXTRA_SIZE_MAX_DEFAULT
	for effect_data in _get_extra_ball_effects(BallEffect.Type.EXTRA_SIZE_MAX_UP):
		new_extra_size_max += effect_data[1]
	_extra_size_max = clampi(new_extra_size_max, new_extra_size_max, EXTRA_SIZE_MAX)
	print("[Game/BallEffect] EXTRA_SIZE_MAX_UP _extra_size_max: %s" % [_extra_size_max])

	# ex: [Type.HOLE_SIZE_UP, 1]
	var hole_size_level := 0
	for effect_data in _get_extra_ball_effects(BallEffect.Type.HOLE_SIZE_UP):
		hole_size_level += effect_data[1]
	print("[Game/BallEffect] HOLE_SIZE_UP hole_size_level: %s" % [hole_size_level])
	# ex: [Type.HOLE_GRAVITY_SIZE_UP, 1]
	var gravity_size_level := 0
	for effect_data in _get_extra_ball_effects(BallEffect.Type.HOLE_GRAVITY_SIZE_UP):
		gravity_size_level += effect_data[1]
	for node in get_tree().get_nodes_in_group("hole"):
		if node is Hole:
			if node.hole_type == Hole.HoleType.WARP_TO:
				node.set_hole_size(hole_size_level)
				node.set_gravity_size(gravity_size_level)
	print("[Game/BallEffect] HOLE_GRAVITY_SIZE_UP gravity_size_level: %s" % [gravity_size_level])

	# ex: [Type.PC_START_TOP_UP, 1]
	var start_level := 0
	for effect_data in _get_extra_ball_effects(BallEffect.Type.PC_START_TOP_UP):
		start_level += effect_data[1]
	_pachinko.set_rush_start_top(start_level)
	print("[Game/BallEffect] PACHINKO_START_TOP_UP start_level: %s" % [start_level])
	# ex: [Type.PC_CONTINUE_TOP_UP, 1]
	var continue_level := 0
	for effect_data in _get_extra_ball_effects(BallEffect.Type.PC_CONTINUE_TOP_UP):
		continue_level += effect_data[1]
	_pachinko.set_rush_continue_top(continue_level)
	print("[Game/BallEffect] PACHINKO_CONTINUE_TOP_UP continue_level: %s" % [continue_level])

	# ex. [Type.TAX_DOWN, 10]
	var tax_off_per := 0
	for effect_data in _get_extra_ball_effects(BallEffect.Type.TAX_DOWN):
		tax_off_per += effect_data[1]
	_tax_rate = 1 - clampi(tax_off_per, 0, 50) / 100.0 # TODO: const
	print("[Game/BallEffect] TAX_DOWN _tax_rate: %s" % [_tax_rate])
	# ex. [Type.PRODUCT_PRICE_DOWN, 10]
	var product_price_off_per := 0
	for effect_data in _get_extra_ball_effects(BallEffect.Type.PRODUCT_PRICE_DOWN):
		product_price_off_per += effect_data[1]
	_product_price_rate = 1 - clampi(product_price_off_per, 0, 50) / 100.0 # TODO: const
	print("[Game/BallEffect] PRODUCT_PRICE_DOWN _product_price_rate: %s" % [_product_price_rate])

	_refresh_deck_extra()
	_refresh_next()


# EXTRA Ball 内の特定の効果をまとめて取得する
func _get_extra_ball_effects(target_effect_type: BallEffect.Type) -> Array:
	var effects = []
	for ball in _extra_ball_list:
		for effect_data in ball.effects:
			if target_effect_type == effect_data[0]:
				effects.append(effect_data)
	#print("[Game] _get_extra_ball_effects(%s) -> %s" % [BallEffect.Type.keys()[target_effect_type], effects])
	return effects


# Ball instance を作成する
# TODO: init を充実させたらこれはいらない
func _create_new_ball(number: int = 0, rarity: Ball.Rarity = Ball.Rarity.COMMON, is_active = true) -> Ball:
	var ball: Ball = _ball_scene.instantiate()
	ball.number = number
	ball.rarity = rarity
	ball.is_active = is_active
	_balls_parent.add_child(ball)
	_billiards.update_balls_count(_billiards_balls_count)
	return ball


# 重み付きのレア度を抽選する
# exclude_common: COMMON 抜きの抽選を行う (Ball LV 用)
func _pick_random_rarity(exclude_common: bool = false) -> Ball.Rarity:
	var rarity_weight = RAIRTY_WEIGHT.duplicate()
	# ex: [Type.RARITY_TOP_UP, Ball.Rarity.RARE]
	for effect_data in _get_extra_ball_effects(BallEffect.Type.RARITY_TOP_UP):
		rarity_weight[effect_data[1]] += RAIRTY_WEIGHT[effect_data[1]]
	# ex: [Type.RARITY_TOP_DOWN, Ball.Rarity.COMMON]
	for effect_data in _get_extra_ball_effects(BallEffect.Type.RARITY_TOP_DOWN):
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


# コンボを開始 (継続) する
func _start_combo() -> void:
	if not _stack_wall_bottom:
		return
	if _combo_state == ComboState.COOLTIME:
		return
	var tween = _get_tween(TweenType.COMBO)
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(func(): _combo_state = ComboState.CONTINUE)
	tween.tween_method(func(v): _game_ui.combo_bar_progress = v, 1.0, 0.0, 3.0)
	tween.tween_callback(func(): _combo_state = ComboState.COOLTIME)
	tween.tween_callback(func(): _stack_wall_bottom.set_collision_layer_value(Collision.Layer.WALL_STACK, false))
	tween.tween_interval(3.0)
	tween.tween_callback(func(): _stack_wall_bottom.set_collision_layer_value(Collision.Layer.WALL_STACK, true))
	tween.tween_callback(func(): _combo_state = ComboState.IDLE)


# DECK/EXTRA の見た目を更新する
func _refresh_deck_extra() -> void:
	_game_ui.update_deck_balls(_deck_ball_list, _deck_size_min, _deck_size_max)
	_game_ui.update_deck_slots(DECK_SIZE_MIN_DEFAULT - _deck_size_min)
	_game_ui.update_extra_balls(_extra_ball_list, _extra_size_min, _extra_size_max)
	_game_ui.update_extra_slots(_extra_size_max - EXTRA_SIZE_MAX_DEFAULT)


# Next 関連の見た目を更新する
func _refresh_next() -> void:
	if _next_tax_index < TAX_LIST.size():
		var turn = TAX_LIST[_next_tax_index][0]
		var amount = TAX_LIST[_next_tax_index][1]
		amount = int(amount * _tax_rate)
		_game_ui.update_next(turn, amount)
	else:
		_game_ui.update_next_clear()


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
