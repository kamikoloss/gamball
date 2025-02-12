class_name Pachinko
extends Node2D
# TODO: 機種のバリエーションを出せるようにする


enum TweenType {
	ROTATING_WALL_A, # 回転床 A
	ROTATING_WALL_B, # 回転床 B
	RUSH_LAMP, # ラッシュ用ランプ
	RUSH_LAMP_FLASH, # ラッシュ用ランプ点滅
	RUSH_LAMP_AUDIO, # ラッシュ用ランプ音
}


const WALL_ROTATION_DURATION := 2.0


@export var _rotating_wall_a: Node2D
@export var _rotating_wall_b: Node2D
@export var _rush_nails_parent: Node2D
@export var _rush_holes_parent: Node2D

@export var _rush_label: Label
@export var _rush_lamps_parent: Control


# 現在ラッシュ中かどうか
var _is_rush_now := false
# 現在抽選中かどうか
var _is_lottery_now := false

# ラッシュの抽選数 (通常時のゲーム数)
var _rush_lottery_count := 0
# ラッシュの継続数
var _rush_continue_count := 0
# ラッシュで入っている Ball の数
var _rush_balls_count := 0
# ラッシュで入れられる Ball の最大数
var _rush_balls_max := 10

# 抽選確率の分母 (ランプの数)
var _rush_probability_bottom := 24
# ラッシュ初当たり抽選確率の分子のリスト
var _rush_start_probability_top: Array[int] = [0, 12]
# ラッシュ継続抽選確率の分子のリスト
var _rush_continue_probability_top: Array = range(12) # [0, 1, ..., 11]
# 最後に抽選した分子 (ランプの位置)
var _rush_last_hit_number := -1

# { TweenType: Tween, ... } 
var _tweens := {}


func _ready() -> void:
	_rush_lottery_count = 0
	_rush_label.text = "!!!!!"

	_finish_rush(true) # 初期化なので強制的に終了する
	_refresh_rush_lamps(false)
	_start_rotating_wall()

	# Signal (Hole)
	for node in _rush_holes_parent.get_children():
		if node is Hole:
			node.ball_entered.connect(_on_rush_hole_ball_entered)


# ラッシュの抽選を開始する
func start_lottery(force: bool = false) -> void:
	if not force:
		# 抽選中の場合: 何もしない
		if _is_lottery_now:
			return
		# ラッシュ中の場合
		if _is_rush_now:
			# 入れられる最大数に達していない場合: 何もしない
			if _rush_balls_count < _rush_balls_max:
				return

	# 通常時の場合: ゲーム数をカウントする
	if not _is_rush_now:
		_rush_lottery_count += 1
		_rush_label.text = "%02d!%02d" % [_rush_lottery_count, 30]

	# 乱数を抽選する
	var index_list: Array[int] = _pick_lamp_index_list()
	var hit = index_list[2] % _rush_probability_bottom
	var top = _rush_continue_probability_top if _is_rush_now else _rush_start_probability_top
	print("[Pachinko] start_lottery hit/top/bottom: %s/%s/%s" % [hit, top, _rush_probability_bottom])

	# 初回: _pick_lamp_index_list() の初期位置をそのまま使う
	if _rush_last_hit_number < 0:
		pass
	# 2回目以降: 前回のランプの点灯位置を初期位置とする
	else:
		index_list = [_rush_last_hit_number, index_list[1], index_list[2]]
	# ランプの点灯位置を保持する
	_rush_last_hit_number = hit

	# ランプの抽選結果の点灯を開始する
	_is_lottery_now = true
	await _start_rusn_lamps(index_list)
	_is_lottery_now = false

	if hit in top:
		AudioManager.play_se(AudioManager.SeType.PACHINKO_RUSH_START)
		_start_rush()
	else:
		AudioManager.play_se(AudioManager.SeType.PACHINKO_RUSH_FINISH)
		_finish_rush()


func set_rush_start_top(level: int = 0) -> void:
	if level == 0:
		_rush_start_probability_top = [0, 12]
	elif level == 1:
		_rush_start_probability_top = [0, 12, 6]
	else:
		_rush_start_probability_top = [0, 12, 6, 18]

func set_rush_continue_top(level: int = 0) -> void:
	var clamped = clampi(level, 0, 6)
	_rush_continue_probability_top = range(12 + clamped)


# Ball が ラッシュ用 Hole に落ちたときの処理
func _on_rush_hole_ball_entered(hole: Hole, ball: Ball) -> void:
	# Ball が縮小中の場合: 何もしない
	if ball.is_shrinked:
		return

	# 入れられる最大数に達している場合: ラッシュ装置を無効化する
	if _rush_balls_max <= _rush_balls_count:
		_disable_rush_devices()
		return

	# カウントする
	_rush_balls_count += 1
	_rush_label.text = "%02d!%02d" % [_rush_balls_count, _rush_balls_max]


# ラッシュを開始する (ラッシュを継続するときも含む)
func _start_rush() -> void:
	_is_rush_now = true
	_rush_balls_count = 0
	_rush_continue_count += 1

	_refresh_rush_lamps(true)
	_enable_rush_devices()

	_rush_label.text = "%02d!%02d" % [_rush_balls_count, _rush_balls_max]

# ラッシュを終了する
func _finish_rush(force: bool = false) -> void:
	if not force:
		# 通常時の場合: 何もしない
		if not _is_rush_now:
			return

	_is_rush_now = false
	_rush_lottery_count = 0
	_rush_balls_count = 0
	_rush_continue_count = 0

	_refresh_rush_lamps(false)
	_disable_rush_devices()

	_rush_label.text = "%02d!%02d" % [_rush_lottery_count, 30] # TODO


# ラッシュ装置を有効化する
func _enable_rush_devices() -> void:
	for node in _rush_holes_parent.get_children():
		if node is Hole:
			node.disabled = false
	for node in _rush_nails_parent.get_children():
		if node is Nail:
			node.disabled = false

# ラッシュ装置を無効化する
func _disable_rush_devices() -> void:
	for node in _rush_holes_parent.get_children():
		if node is Hole:
			node.disabled = true
	for node in _rush_nails_parent.get_children():
		if node is Nail:
			node.disabled = true


# 分母を元にランプ点灯用の番号を抽選する
# @returns [ 点灯の初期位置, 周回点灯Aの終了位置, 周回点灯Bの終了位置 ]  
func _pick_lamp_index_list() -> Array[int]:
	var size = _rush_probability_bottom

	var index_from = randi_range(0, size)
	var index_to_1 = index_from + size * randi_range(1, 2) + randi_range(0, size) # size * 1-3
	var index_to_2 = index_to_1 + size * randi_range(0, 1) + randi_range(0, size) # size * 1-2

	var index_list: Array[int] = [index_from, index_to_1, index_to_2]
	#print("[Pachinko] _pick_lamp_index_list() index_list: %s" % [index_list])
	return index_list


# ランプの抽選結果の点灯を開始する
func _start_rusn_lamps(index_list: Array[int]) -> void:
	var size = _rush_probability_bottom
	var duration = 0.0
	var tween = _get_tween(TweenType.RUSH_LAMP)
	tween.set_parallel(true)

	# 最初の早い周回点灯
	duration = (index_list[1] - index_list[0]) * 0.04
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_method(func(v): _enable_rush_lamp(v % size), index_list[0], index_list[1], duration)
	tween.tween_callback(func(): _start_lamp_se_loop(0.2, AudioManager.SeType.PACHINKO_LAMP_OFF))

	# 止まる前のゆっくり点灯 (だんだん遅くなる)
	tween.chain()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	duration = (index_list[2] - index_list[1]) * 0.2
	tween.tween_method(func(v): _enable_rush_lamp(v % size), index_list[1], index_list[2], duration)
	tween.tween_callback(func(): _start_lamp_se_loop(0.4, AudioManager.SeType.PACHINKO_LAMP_ON))

	# 止まったあとの点滅
	tween.chain()
	tween.tween_callback(func(): _flash_lamp(index_list[2] % size))
	tween.tween_callback(func(): _stop_lamp_se_loop())
	await tween.finished

# NOTE: set_loops は chain で切れないので Tween を分けている
func _flash_lamp(index: int) -> void:
	var tween2 = _get_tween(TweenType.RUSH_LAMP_FLASH)
	tween2.set_loops(4)
	tween2.tween_callback(func(): _disable_rush_lamps())
	tween2.tween_interval(0.1)
	tween2.tween_callback(func(): _enable_rush_lamp(index))
	tween2.tween_interval(0.1)
	await tween2.finished

func _start_lamp_se_loop(interval: float, type: AudioManager.SeType) -> void:
	var tween = _get_tween(TweenType.RUSH_LAMP_AUDIO)
	tween.set_loops()
	tween.tween_callback(func(): AudioManager.play_se(type))
	tween.tween_interval(interval)

func _stop_lamp_se_loop() -> void:
	# 取得時に kill するので止まる
	var tween = _get_tween(TweenType.RUSH_LAMP_AUDIO)


# ランプの色を更新する
func _refresh_rush_lamps(is_rush: bool) -> void:
	var count = 0
	var top = _rush_continue_probability_top if is_rush else _rush_start_probability_top
	for node in _rush_lamps_parent.get_children():
		if node is Lamp:
			if count in top:
				node.set_light_colors(Lamp.LightColor.GREEN_ON, Lamp.LightColor.GREEN_OFF)
			else:
				node.set_light_colors(Lamp.LightColor.DEFAULT_ON, Lamp.LightColor.DEFAULT_OFF)
		count += 1

# 特定のランプを点灯させる
func _enable_rush_lamp(index: int) -> void:
	var count = 0
	for node in _rush_lamps_parent.get_children():
		if node is Lamp:
			node.disabled = count != index
		count += 1

# すべてのランプを消灯する
func _disable_rush_lamps() -> void:
	for node in _rush_lamps_parent.get_children():
		if node is Lamp:
			node.disabled = true


# 回転床の動作を開始する
func _start_rotating_wall() -> void:
	var wall_settings = [
		[TweenType.ROTATING_WALL_A, _rotating_wall_a, 60, 0],
		[TweenType.ROTATING_WALL_B, _rotating_wall_b, 0, -60],
	]
	for setting in wall_settings:
		var tween = _get_tween(setting[0])
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.set_loops()
		tween.tween_property(setting[1], "rotation_degrees", setting[2], WALL_ROTATION_DURATION)
		tween.tween_property(setting[1], "rotation_degrees", setting[3], WALL_ROTATION_DURATION)


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
