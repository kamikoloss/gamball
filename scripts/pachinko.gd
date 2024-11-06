class_name Pachinko
extends Node2D


# ラッシュ用ランプが消灯したとき
signal rush_lamps_turned_off


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
@export var _rush_devices: Node2D

# UI
@export var _rush_lamps: Control
@export var _rush_label_a: Label
@export var _rush_label_b: Label


# { TweenType: Tween, ... } 
var _tweens: Dictionary = {}

var _rush_probability_bottom = 24 # 確率 分母 (ランプの数)
var _rush_start_probability_top = 2 # 初当たり確率 分子
var _rush_continue_probability_top = 16 # Rush 継続率 分子


func _ready() -> void:
	disable_rush_devices()
	disable_rush_lamps()
	_start_rotating_wall()


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


# ラッシュ装置を有効化する
func enable_rush_devices() -> void:
	for device in _rush_devices.get_children():
		if device is Hole:
			device.enable()
		elif device is Nail:
			device.enable()

# ラッシュ装置を無効化する
func disable_rush_devices() -> void:
	for device in _rush_devices.get_children():
		if device is Hole:
			device.disable()
		elif device is Nail:
			device.disable()
	_rush_label_a.text = ""
	_rush_label_b.text = ""


## 分母を元にランプ点灯用の番号を抽選する
## @returns [ 点灯の初期位置, 周回点灯Aの終了位置, 周回点灯Bの終了位置 ]  
func pick_lamp_index_list() -> Array[int]:
	var size = _rush_probability_bottom

	var index_from = randi_range(0, size)
	var index_to_1 = index_from + size * randi_range(1, 2) + randi_range(0, size) # size * 1-3
	var index_to_2 = index_to_1 + size * randi_range(0, 1) + randi_range(0, size) # size * 1-2

	return [index_from, index_to_1, index_to_2]


# ランプの抽選結果の点灯を開始する
func start_rusn_lamps(index_list: Array[int]) -> void:
	var size = _rush_probability_bottom
	var duration = 0.0
	var tween = _get_tween(TweenType.RushLamp)
	tween.set_parallel(true)

	# 最初の早い周回点灯
	duration = (index_list[1] - index_list[0]) * 0.04
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_method(func(v): enable_rush_lamp(v % size), index_list[0], index_list[1], duration)

	# 止まる前のゆっくり点灯 (だんだん遅くなる)
	tween.chain()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	duration = (index_list[2] - index_list[1]) * 0.2
	tween.tween_method(func(v): enable_rush_lamp(v % size), index_list[1], index_list[2], duration)

	# 止まったあとの点滅
	tween.chain()
	tween.tween_callback(func(): _flash_lamp(index_list[2] % size))

func _flash_lamp(index: int) -> void:
	# NOTE: set_loops は chain で切れないので Tween を分ける
	var tween2 = _get_tween(TweenType.RushLampFlash)
	tween2.set_loops(5)
	tween2.tween_callback(func(): enable_rush_lamp(index))
	tween2.tween_interval(0.1)
	tween2.tween_callback(func(): disable_rush_lamps())
	tween2.tween_interval(0.1)
	tween2.finished.connect(func():
		rush_lamps_turned_off.emit()
		print("[Pachinko] rush_lamps_turned_off")
	)


# 特定のランプを点灯させる
func enable_rush_lamp(index: int) -> void:
	var count = 0
	for maybe_lamp in _rush_lamps.get_children():
		if maybe_lamp is Lamp:
			if count == index:
				maybe_lamp.enable()
			else:
				maybe_lamp.disable()
		count += 1


# すべてのランプを消灯する
func disable_rush_lamps() -> void:
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
