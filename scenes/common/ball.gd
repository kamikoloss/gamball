class_name Ball
extends RigidBody2D


# HelpArea ホバー時
signal help_area_hovered # (help_area: HelpArea, hovered: bool)
# HelpArea クリック時
signal help_area_pressed # (help_area: HelpArea)


# ボールのレア度
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
# ボールのプール 名称表示に使用される
enum Pool { A }
# Tween
enum TweenType { TRAIL, SHRINK, HIDE, WARP, WARP_CURVE }


# Tween
const WARP_DURATION := 1.0
const SHRINK_DURATION := 1.0
const SHRINK_SCALE := Vector2(0.6, 0.6)
const HIDE_DURATION := 1.0

# 残像の頂点数
const TRAIL_MAX_LENGTH := 5
# 残像の頂点の更新インターバル (秒)
const TRAIL_INTERVAL := 1.0 / 30.0

# 特殊なボール番号
const BALL_NUMBER_OPTIONAL_SLOT := -1 # 空きスロット用
const BALL_NUMBER_DISABLED_SLOT := -2 # 使用不可スロット用


# 展示用かどうか
@export var is_display := false
#
@export var help_area: HelpArea


# 見た目部分をまとめる親
@export var _view_parent: Node2D
@export var _view_slot: Control
@export var _view_main: Control
# ボールの本体部分
@export var _body_texture: TextureRect
@export var _inner_texture: TextureRect
@export var _inner_line_texture: TextureRect
@export var _stripe_top_texture: TextureRect
@export var _stripe_bottom_texture: TextureRect
# ボールが有効化されるまで全体を覆う部分
@export var _inactive_texture: TextureRect
# ボール番号
@export var _number_label: Label

# 残像
@export var _trail_line: Line2D
# Hole 用の当たり判定
@export var _hole_area: Area2D


# ボールがビリヤード盤面上にあるかどうか
var is_on_billiards := false:
	set(v):
		is_on_billiards = v
		# ビリヤード盤面上にあるときは DragShooter 用に HelpArea の入力をスルーする
		help_area.disabled = not is_on_billiards
# 他のボールにぶつかって有効化されたかどうか
var is_active := true
# Gain に触れたかどうか
var is_gained := false
# 現在ワープ中かどうか
var is_warping := false
# 現在縮小中かどうか
var is_shrinked := false

# ボール番号
var number := 0
# ボールのレア度
var rarity := Rarity.COMMON
# ボールのプール
var pool := Pool.A
# ボールの効果
# NOTE: 効果移譲とかありそうなので配列で持つ
# [ [ <BallEffect.Type>, param1, (param2) ], ... ]
var effects := []


# 残像の頂点座標
var _trail_points : = []
# 残像の太さ (保持用)
var _trail_default_width := 0.0

var _tweens := {}


func _init(number: int = 0, rarity: Rarity = Rarity.COMMON) -> void:
	self.number = number
	self.rarity = rarity
	_init_effects()


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	help_area.hovered.connect(func(n, h): help_area_hovered.emit(n, h))
	help_area.pressed.connect(func(n): help_area_pressed.emit(n))

	if not is_display:
		# 残像の頂点の記録を開始する
		var tween = _get_tween(TweenType.TRAIL)
		tween.set_loops()
		tween.tween_interval(TRAIL_INTERVAL)
		tween.tween_callback(_refresh_trail_points)
		# 残像の太さを保持しておく
		_trail_default_width = _trail_line.width

	refresh_view()
	refresh_physics()
	_init_effects()


# 自身の見た目を更新する
func refresh_view() -> void:
	# スロットの場合
	if number < 0:
		_view_slot.visible = true
		_view_main.visible = false
		return
	_view_slot.visible = false
	_view_main.visible = true

	# 本体色
	var rarity_color = ColorPalette.BALL_RARITY_COLORS[rarity]
	_body_texture.self_modulate = rarity_color
	_inner_texture.self_modulate = rarity_color
	# レア度による本体色の変化
	if rarity == Rarity.COMMON:
		_inner_line_texture.self_modulate = ColorPalette.GRAY_60
		_stripe_top_texture.self_modulate = ColorPalette.GRAY_60
		_stripe_bottom_texture.self_modulate = ColorPalette.GRAY_60
		_number_label.self_modulate = ColorPalette.GRAY_60
	else:
		_inner_line_texture.self_modulate = ColorPalette.WHITE
		_stripe_top_texture.self_modulate = ColorPalette.WHITE
		_stripe_bottom_texture.self_modulate = ColorPalette.WHITE
		_number_label.self_modulate = ColorPalette.WHITE
	# ストライプ
	var show_stripe := 8 <= number
	_stripe_top_texture.visible = show_stripe
	_stripe_bottom_texture.visible = show_stripe

	# 残像色: 有効でない場合は固定する
	var trail_color = _body_texture.self_modulate
	if not is_active:
		trail_color = ColorPalette.WHITE
	var gradient = Gradient.new()
	gradient.set_color(0, Color(trail_color, 0.5))
	gradient.set_color(1, Color(trail_color, 0))
	_trail_line.gradient = gradient

	# ボール番号
	if is_active:
		_number_label.text = str(number)
	else:
		_number_label.text = "??"
		_number_label.self_modulate = ColorPalette.BLACK

	# 有効化されている場合: 無効テクスチャを非表示にする
	_inactive_texture.visible = not is_active

	# 縮小している場合: 本体色のみ表示する
	_inner_texture.visible = not is_shrinked
	_inner_line_texture.visible = not is_shrinked
	_stripe_top_texture.visible = _stripe_top_texture.visible and not is_shrinked
	_stripe_bottom_texture.visible = _stripe_top_texture.visible and not is_shrinked
	_number_label.visible = not is_shrinked


# 自身の物理判定を更新する
func refresh_physics() -> void:
	freeze = is_display

	if is_display:
		collision_layer = 0
		collision_mask = 0


# ワープする (WARP_TO 用)
func warp_for_warp_to(to: Vector2) -> void:
	set_collision_layer_value(Collision.Layer.BASE, false) # 他のボールと衝突しない
	set_collision_mask_value(Collision.Layer.WALL_HOLE, true) # WALL_HOLE 内で跳ね返る

	await _enable_shrink()
	await _warp(to)

	set_collision_layer_value(Collision.Layer.BASE, true) # 他のボールと衝突する
	set_collision_mask_value(Collision.Layer.WALL_HOLE, false) # WALL_HOLE を通り抜ける

	# TODO: await の前におかないとボールが勢いよく出てしまうのでここに書いている
	# できれば _disable_shrink() が終わってからボールを射出したい
	linear_velocity = Vector2.ZERO

	await _disable_shrink()


# ワープする (GAIN 用)
func warp_for_gain(from: Vector2, to: Vector2) -> void:
	# 即座に縮小する (縮小状態から開始する)
	_view_parent.scale = SHRINK_SCALE
	_trail_line.width = _trail_default_width * SHRINK_SCALE.x
	is_shrinked = true
	refresh_view()

	position = from
	await _warp(to)

	# バラケさせる
	var spawn_impulse = Vector2(randi_range(0, 100), randi_range(0, 100))
	apply_impulse(spawn_impulse)

	# 即座に拡大する
	_view_parent.scale = Vector2.ONE
	_trail_line.width = _trail_default_width
	is_shrinked = false
	refresh_view()

	is_shrinked = true
	# 他のボールおよび WALL_STACK にのみ衝突するようにする
	set_collision_layer_value(Collision.Layer.BASE, false)
	set_collision_mask_value(Collision.Layer.BASE, false)
	set_collision_layer_value(Collision.Layer.WALL_STACK, true)
	set_collision_mask_value(Collision.Layer.WALL_STACK, true)


# 消える
func die() -> void:
	set_collision_layer_value(Collision.Layer.BASE, false)
	set_collision_mask_value(Collision.Layer.BASE, false)
	set_collision_mask_value(Collision.Layer.WALL_HOLE, true)
	await _enable_shrink(true)
	queue_free()


# Rigidbody2D.body_entered
func _on_body_entered(body: Node) -> void:
	# 他の Ball にぶつかったとき
	if body is Ball:
		# 有効化されていない場合: 有効化する
		if not is_active:
			is_active = true
			refresh_view()


func _warp(to: Vector2) -> void:
	# ワープの途中で WARP_TO に乗ったときにワープしないようにする
	if is_warping:
		return
	is_warping = true

	# 座標移動
	var tween_warp = _get_tween(TweenType.WARP)
	tween_warp.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween_warp.tween_property(self, "position", to, WARP_DURATION)

	# カーブを描く
	var tween_warp_curve = _get_tween(TweenType.WARP_CURVE)
	var view_from = _view_parent.position
	var view_to = view_from + Vector2(randi_range(-320, 320), 0)
	tween_warp_curve.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween_warp_curve.tween_property(_view_parent, "position", view_to, WARP_DURATION / 4.0)
	tween_warp_curve.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween_warp_curve.tween_property(_view_parent, "position", view_from, WARP_DURATION / 2.0)

	await tween_warp.finished
	is_warping = false


# 自身の見た目を徐々に縮小する
func _enable_shrink(hide: bool = false) -> void:
	is_shrinked = true
	refresh_view()
	var tween = _get_tween(TweenType.SHRINK)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.set_parallel()
	tween.tween_property(_view_parent, "scale", SHRINK_SCALE, SHRINK_DURATION)
	tween.tween_property(_trail_line, "width", _trail_default_width * SHRINK_SCALE.x, SHRINK_DURATION)
	if hide:
		tween.tween_property(_view_parent, "modulate", Color.TRANSPARENT, HIDE_DURATION)
		tween.tween_property(_trail_line, "modulate", Color.TRANSPARENT, HIDE_DURATION)
	await tween.finished

# 自身の見た目を徐々に拡大する (元に戻す)
func _disable_shrink(hide: bool = false) -> void:
	is_shrinked = false
	refresh_view()
	var tween = _get_tween(TweenType.SHRINK)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.set_parallel()
	tween.tween_property(_view_parent, "scale", Vector2.ONE, SHRINK_DURATION / 2)
	tween.tween_property(_trail_line, "width", _trail_default_width, SHRINK_DURATION / 2)
	if hide:
		tween.tween_property(_view_parent, "modulate", Color.WHITE, HIDE_DURATION / 2)
		tween.tween_property(_trail_line, "modulate", Color.WHITE, HIDE_DURATION / 2)
	await tween.finished


func _init_effects() -> void:
	if effects.is_empty():
		return
	if rarity == Rarity.COMMON:
		return

	var effects_data := {
		Pool.A: BallEffect.EFFECTS_POOL_A,
	}
	effects.append(effects_data[pool][number][rarity])


# 残像の頂点を記録する
func _refresh_trail_points() -> void:
	_trail_points.push_front(_view_parent.global_position)
	if TRAIL_MAX_LENGTH < _trail_points.size():
		_trail_points.pop_back()
	_trail_line.clear_points()
	_trail_line.rotation = 0.0
	for point in _trail_points:
		_trail_line.add_point(point)


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
