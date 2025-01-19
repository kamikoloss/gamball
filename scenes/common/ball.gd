class_name Ball
extends RigidBody2D


signal pressed # ()
signal hovered # (entered: bool)


# ボールのレア度
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
# ボールのプール 名称表示に使用される
enum Pool { A }
# Tween
enum TweenType { TRAIL, SHRINK, HIDE, WARP, WARP_CURVE }


# Z index
const Z_INDEX_DEFAULT: int = 4
const Z_INDEX_SLOT: int = 3

# Tween
const WARP_DURATION: float = 1.0
const SHRINK_DURATION: float = 1.0
const SHRINK_SCALE: Vector2 = Vector2(0.4, 0.4)
const HIDE_DURATION: float = 1.0

# 残像の頂点数
const TRAIL_MAX_LENGTH: int = 10
# 残像の頂点の更新インターバル (秒)
const TRAIL_INTERVAL: float = 0.02

# 特殊なボール番号
const BALL_LEVEL_OPTIONAL_SLOT = -1 # 空きスロット用
const BALL_LEVEL_DISABLED_SLOT = -2 # 使用不可スロット用


# ボール番号
# TODO: number の方がいい
@export var level: int = 0
# 展示用かどうか
# pressed は展示用のみ発火する
@export var is_display: bool = false
# ボールがビリヤード盤面上にあるかどうか
# NOTE: ビリヤード盤面上の初期 Ball 用に export している
@export var is_on_billiards: bool = false


# 見た目部分をまとめる親
@export var _view_parent: Node2D
# ボールが有効化されるまで全体を覆う部分
@export var _mask_texture: TextureRect
# ボールの本体色部分
@export var _body_texture: TextureRect
@export var _body_stripe_texture: TextureRect
@export var _body_stripe_2_texture: TextureRect
# ボール番号の背景部分
@export var _inner_texture: TextureRect
@export var _inner_texture_2: TextureRect
# ボール番号
@export var _level_label: Label
# ボールの選択を示す周辺部分
@export var _hover_texture: TextureRect

# 残像
@export var _trail_line: Line2D
# Hole 用の当たり判定
@export var _hole_area: Area2D
# pressed, hovered 用
@export var _touch_button: TextureButton


# 他のボールにぶつかって有効化されたかどうか
var is_active: bool = true
# Gain/Stack に触れたかどうか
var is_gained: bool = false
var is_stacked: bool = false
# 現在ワープ中かどうか
var is_warping: bool = false
# 見た目が縮小されているか
var is_shrinked: bool = false
# ボールのレア度
# TODO: level の方がいい
var rarity: Rarity = Rarity.COMMON
# ボールのプール
var pool: Pool = Pool.A
# ボールの効果
# NOTE: 効果移譲とかありそうなので配列で持つ
# [ [ <BallEffect.EffectType>, param1, (param2) ], ... ]
var effects: Array = []


# 残像の頂点座標
var _trail_points: Array = []
# 残像の太さ (保持用)
var _trail_default_width: float = 0

var _tweens: Dictionary = {}


func _init(level: int = 0, rarity: Rarity = Rarity.COMMON) -> void:
	self.level = level
	self.rarity = rarity

	if Rarity.COMMON < rarity:
		self.effects.append(BallEffect.EFFECTS_POOL_1[level][rarity])


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_touch_button.pressed.connect(func(): pressed.emit())
	_touch_button.mouse_entered.connect(func(): hovered.emit(true))
	_touch_button.mouse_exited.connect(func(): hovered.emit(false))

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
	hide_hover()


# 自身の見た目を更新する
func refresh_view() -> void:
	# Ordering
	if level < 0:
		z_index = Z_INDEX_SLOT
	else:
		z_index = Z_INDEX_DEFAULT

	# 本体色
	var body_color: Color
	if level < 0:
		body_color = ColorData.GRAY_80
	elif level == 0:
		body_color = ColorData.GRAY_20
	elif level <= 15:
		body_color = ColorData.SECONDARY
	else:
		body_color = ColorData.PRIMARY
	_body_texture.self_modulate = body_color
	# 残像色
	var trail_color = body_color
	if not is_active:
		trail_color = ColorData.GRAY_20
	var gradient = Gradient.new()
	gradient.set_color(0, Color(trail_color, 0.5))
	gradient.set_color(1, Color(trail_color, 0))
	_trail_line.gradient = gradient

	# 模様
	var show_stripe = 9 <= level and level <= 15
	_body_stripe_texture.visible = show_stripe
	_body_stripe_2_texture.visible = show_stripe

	# レア度
	if rarity == Rarity.COMMON:
		_inner_texture.self_modulate = Color.WHITE
		_inner_texture_2.visible = false
		_level_label.self_modulate = Color.BLACK
	else:
		_inner_texture.self_modulate = Color.BLACK
		_inner_texture_2.visible = true
		_inner_texture_2.self_modulate = ColorData.BALL_RARITY_COLORS[rarity]
		_level_label.self_modulate = ColorData.BALL_RARITY_COLORS[rarity]

	# マスク
	_mask_texture.visible = not is_active # 有効なら表示しない

	# ボール番号
	if not is_active:
		_inner_texture.visible = true
		_level_label.visible = true
		_level_label.text = "??"
	elif level < 0:
		_inner_texture.visible = false
		_level_label.visible = false
	else:
		_inner_texture.visible = true
		_level_label.visible = true
		_level_label.text = str(level)

	# 縮小
	if is_shrinked:
		_body_stripe_texture.visible = false
		_body_stripe_2_texture.visible = false
		_inner_texture.visible = false
		_inner_texture_2.visible = false
		_level_label.visible = false


# 自身の物理判定を更新する
func refresh_physics() -> void:
	freeze = is_display

	if is_display:
		collision_layer = 0
		collision_mask = 0


func show_hover() -> void:
	_hover_texture.visible = true

func hide_hover() -> void:
	_hover_texture.visible = false


# ワープする (WARP_TO 用)
func warp_for_warp_to(to: Vector2) -> void:
	set_collision_layer_value(Collision.Layer.BASE, false)
	set_collision_mask_value(Collision.Layer.HOLE_WALL, true)

	await _enable_shrink()
	await _warp(to)

	set_collision_layer_value(Collision.Layer.BASE, true)
	set_collision_mask_value(Collision.Layer.HOLE_WALL, false)

	# TODO: await の前におかないとボールが勢いよく出てしまうのでここに書いている
	# できれば _disable_shrink() が終わってからボールを射出したい
	linear_velocity = Vector2.ZERO

	await _disable_shrink()


# ワープする (GAIN 用)
func warp_for_gain(from: Vector2, to: Vector2) -> void:
	position = from
	set_collision_layer_value(Collision.Layer.BASE, false)
	set_collision_mask_value(Collision.Layer.HOLE_WALL, true)

	# 即座に縮小する
	_view_parent.scale = SHRINK_SCALE
	_trail_line.width = _trail_default_width * SHRINK_SCALE.x
	is_shrinked = true
	refresh_view()

	position = from
	await _warp(to)


# 消える
func die() -> void:
	set_collision_layer_value(Collision.Layer.BASE, false)
	set_collision_mask_value(Collision.Layer.HOLE_WALL, true)
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

	var tween_warp = _get_tween(TweenType.WARP)
	tween_warp.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween_warp.tween_property(self, "position", to, WARP_DURATION)

	var tween_warp_curve = _get_tween(TweenType.WARP_CURVE)
	var view_from = _view_parent.position
	var view_to = view_from + Vector2(0, randi_range(-80, 80))
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
