class_name Pachinko
extends Node2D


enum TweenType {
	RotatingWallA, # 回転床 A
	RotatingWallB, # 回転床 B
	RushLamp, # ラッシュ用ランプ
	RushLampFlash, # ラッシュ用ランプ点滅
}


const WALL_ROTATION_DURATION = 2.0


# Node
@export var _spawn_position_a: Node2D
@export var _spawn_position_b: Node2D
@export var _rotating_wall_a: Node2D
@export var _rotating_wall_b: Node2D
@export var _rush_holes: Node2D # Hole の親
@export var _rush_nails: Node2D # Nail の親

# UI
@export var _rush_lamps: Control # Lamp の親
@export var _rush_label_a: Label
@export var _rush_label_b: Label


# 現在ラッシュ中かどうか
var is_rush_now: bool = false
# 現在抽選中かどうか
var is_lottery_now: bool = false


var _rush_continue_count = 0 # ラッシュの継続数
var _rush_balls_count: int = 0 # ラッシュで入っている Ball の数
var _rush_balls_max = 10 # ラッシュで入れられる Ball の最大数

var _rush_probability_bottom = 24 # 確率 分母 (ランプの数)
var _rush_start_probability_top = 2 # 初当たり確率 分子
var _rush_continue_probability_top = 16 # Rush 継続率 分子

var _tweens: Dictionary = {} # { TweenType: Tween, ... } 


func _ready() -> void:
	_finish_rush()
	_refresh_rush_lamps(false)
	_start_rotating_wall()

	# Signal (Hole)
	for node in _rush_holes.get_children():
		if node is Hole:
			node.ball_entered.connect(_on_hole_ball_entered)


# 盤面上に Ball を移動する
func spawn_ball(ball: Ball) -> void:
	var spawn_posiiton = [
		_spawn_position_a,
		_spawn_position_b,
	].pick_random()
	ball.position = spawn_posiiton.position

	# 初速をつける
	var spawn_impulse = Vector2(0, randi_range(400, 500))
	ball.apply_impulse(spawn_impulse)


# ラッシュ開始の抽選を行う
func start_lottery() -> void:
	# 抽選中の場合: 何もしない
	# TODO: 保留
	if is_lottery_now:
		return
	# ラッシュ中の場合 かつ 入れられる最大数に達していない場合: 何もしない
	if is_rush_now and _rush_balls_count < _rush_balls_max:
		return

	is_lottery_now = true
	var index_list = _pick_lamp_index_list()
	await _start_rusn_lamps(index_list)
	print("[Pachinko] start_lottery _start_rusn_lamps() finished")
	var hit = index_list[2] % _rush_probability_bottom
	var top = _rush_continue_probability_top if is_rush_now else _rush_start_probability_top
	print("[Pachinko] start_lottery hit/top/bottom = %s/%s/%s" % [hit, top, _rush_probability_bottom])
	is_lottery_now = false

	if hit < top:
		_start_rush()
	else:
		_finish_rush()


# Ball が Hole に落ちたときの処理
func _on_hole_ball_entered(hole: Hole, ball: Ball) -> void:
	# 入れられる最大数に達している場合: 何もしない
	if _rush_balls_max <= _rush_balls_count:
		return

	# カウントする
	_rush_balls_count += 1
	_rush_label_b.text = "%02d/%02d" % [_rush_balls_count, _rush_balls_max]

	# (カウントの結果) 入れられる最大数に達している場合: ラッシュ装置を無効化する
	if _rush_balls_max <= _rush_balls_count:
		_disable_rush_devices()


# ラッシュを開始する (継続するときも含む)
func _start_rush() -> void:
	is_rush_now = true

	_rush_balls_count = 0
	_rush_continue_count += 1
	_refresh_rush_lamps(true)
	_enable_rush_devices()

	_rush_label_a.text = "RUSH %02d" % [_rush_continue_count]
	_rush_label_b.text = "%02d/%02d" % [_rush_balls_count, _rush_balls_max]

# ラッシュを終了する
func _finish_rush() -> void:
	is_rush_now = false

	_rush_balls_count = 0
	_rush_continue_count = 0
	_refresh_rush_lamps(false)
	_disable_rush_devices()

	_rush_label_a.text = ""
	_rush_label_b.text = ""


# ラッシュ装置を有効化する
func _enable_rush_devices() -> void:
	for node in _rush_holes.get_children():
		if node is Hole:
			node.enable()
	for node in _rush_nails.get_children():
		if node is Nail:
			node.enable()

# ラッシュ装置を無効化する
func _disable_rush_devices() -> void:
	for node in _rush_holes.get_children():
		if node is Hole:
			node.disable()
	for node in _rush_nails.get_children():
		if node is Nail:
			node.disable()


## 分母を元にランプ点灯用の番号を抽選する
## @returns [ 点灯の初期位置, 周回点灯Aの終了位置, 周回点灯Bの終了位置 ]  
func _pick_lamp_index_list() -> Array[int]:
	var size = _rush_probability_bottom

	var index_from = randi_range(0, size)
	var index_to_1 = index_from + size * randi_range(1, 2) + randi_range(0, size) # size * 1-3
	var index_to_2 = index_to_1 + size * randi_range(0, 1) + randi_range(0, size) # size * 1-2

	var index_list: Array[int] = [index_from, index_to_1, index_to_2]
	print("[Pachinko] _pick_lamp_index_list %s" % [index_list])
	return index_list


# ランプの抽選結果の点灯を開始する
func _start_rusn_lamps(index_list: Array[int]) -> void:
	var size = _rush_probability_bottom
	var duration = 0.0
	var tween = _get_tween(TweenType.RushLamp)
	tween.set_parallel(true)

	# 最初の早い周回点灯
	duration = (index_list[1] - index_list[0]) * 0.04
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_method(func(v): _enable_rush_lamp(v % size), index_list[0], index_list[1], duration)

	# 止まる前のゆっくり点灯 (だんだん遅くなる)
	tween.chain()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	duration = (index_list[2] - index_list[1]) * 0.2
	tween.tween_method(func(v): _enable_rush_lamp(v % size), index_list[1], index_list[2], duration)

	# 止まったあとの点滅
	tween.chain()
	tween.tween_callback(func(): _flash_lamp(index_list[2] % size))

	await tween.finished

# NOTE: set_loops は chain で切れないので Tween を分ける
func _flash_lamp(index: int) -> void:
	var tween2 = _get_tween(TweenType.RushLampFlash)
	tween2.set_loops(5)
	tween2.tween_callback(func(): _enable_rush_lamp(index))
	tween2.tween_interval(0.1)
	tween2.tween_callback(func(): _disable_rush_lamps())
	tween2.tween_interval(0.1)
	await tween2.finished


# ランプの色を初期化する
func _refresh_rush_lamps(is_rush: bool) -> void:
	var count = 0
	var top = _rush_continue_probability_top if is_rush else _rush_start_probability_top
	for node in _rush_lamps.get_children():
		if node is Lamp:
			if count < top:
				node.set_light_colors(Lamp.LightColor.GREEN_ON, Lamp.LightColor.GREEN_OFF)
			else:
				node.set_light_colors(Lamp.LightColor.DEFAULT_ON, Lamp.LightColor.DEFAULT_OFF)
		count += 1

# 特定のランプを点灯させる
func _enable_rush_lamp(index: int) -> void:
	var count = 0
	for maybe_lamp in _rush_lamps.get_children():
		if maybe_lamp is Lamp:
			if count == index:
				maybe_lamp.enable()
			else:
				maybe_lamp.disable()
		count += 1

# すべてのランプを消灯する
func _disable_rush_lamps() -> void:
	for maybe_lamp in _rush_lamps.get_children():
		if maybe_lamp is Lamp:
			maybe_lamp.disable()


# 回転床の動作を開始する
func _start_rotating_wall() -> void:
	var wall_settings = [
		{ "type": TweenType.RotatingWallA, "obj": _rotating_wall_a, "deg1": 60, "deg2": 0 },
		{ "type": TweenType.RotatingWallB, "obj": _rotating_wall_b, "deg1": 0, "deg2": -60 },
	]
	for setting in wall_settings:
		var tween = _get_tween(setting["type"])
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.set_loops()
		tween.tween_property(setting["obj"], "rotation_degrees", setting["deg1"], WALL_ROTATION_DURATION)
		tween.tween_property(setting["obj"], "rotation_degrees", setting["deg2"], WALL_ROTATION_DURATION)


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
