class_name Ball
extends RigidBody2D


signal pressed # ()
signal hovered # (entered: bool)


# ボールのレア度
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
# ボールのプール 名称表示に使用される
enum Pool { A }
# Tween
enum TweenType { TRAIL, WARP, WARP_CURVE }


# Z index
const Z_INDEX_DEFAULT: int = 4
const Z_INDEX_SLOT: int = 3

# WARP
const WARP_DURATION: float = 1.0

# 残像の頂点数
const TRAIL_MAX_LENGTH: int = 10
# 残像の頂点の更新インターバル (秒)
const TRAIL_INTERVAL: float = 0.02

# 特殊なボール番号
const BALL_LEVEL_OPTIONAL_SLOT = -1 # 空きスロット用
const BALL_LEVEL_DISABLED_SLOT = -2 # 使用不可スロット用

# TODO: 色系まとめた const に移す？
# ボールの本体の色の定義 { <Level>: Color } 
const BALL_BODY_COLORS = {
	BALL_LEVEL_OPTIONAL_SLOT: Color(0.2, 0.2, 0.2),
	BALL_LEVEL_DISABLED_SLOT: Color(0.4, 0.2, 0.2),
	0: Color(0.8, 0.8, 0.8), 8: Color(0.2, 0.2, 0.2), # White/Black
	1: Color(1.0, 0.8, 0.0), 9: Color(1.0, 0.8, 0.0), # Yellow
	2: Color(0.0, 0.0, 0.8), 10: Color(0.0, 0.0, 0.8), # Blue
	3: Color(0.8, 0.0, 0.0), 11: Color(0.8, 0.0, 0.0), # Red
	4: Color(0.6, 0.0, 0.6), 12: Color(0.6, 0.0, 0.6), # Purple
	5: Color(1.0, 0.4, 0.0), 13: Color(1.0, 0.4, 0.0), # Orange
	6: Color(0.0, 0.4, 0.0), 14: Color(0.0, 0.4, 0.0), # Green
	7: Color(0.6, 0.2, 0.0), 15: Color(0.6, 0.2, 0.0), # Brown
}
# ボールのレア度の色の定義  { <Rarity>: Color } 
const BALL_RARITY_COLORS = {
	Rarity.COMMON: Color.WHITE,
	Rarity.UNCOMMON: Color.GREEN,
	Rarity.RARE: Color.CYAN,
	Rarity.EPIC: Color.MAGENTA,
	Rarity.LEGENDARY: Color.YELLOW,
}


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
# ボールの選択を示す周辺部分
@export var _hover_texture: TextureRect
# ボールの本体色部分
@export var _body_texture: TextureRect
@export var _body_stripe_texture: TextureRect
@export var _body_stripe_2_texture: TextureRect
# ボール番号の背景部分
@export var _inner_texture: TextureRect
@export var _inner_texture_2: TextureRect
# ボールが有効化されるまで全体を覆う部分
@export var _mask_texture: TextureRect

@export var _level_label: Label
@export var _hole_area: Area2D
@export var _trail_line: Line2D
@export var _touch_button: TextureButton


# 他のボールにぶつかって有効化されたかどうか
var is_active: bool = true 
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

var _tweens: Dictionary = {}


func _init(level: int = 0, rarity: Rarity = Rarity.COMMON) -> void:
	self.level = level
	self.rarity = rarity
	if Rarity.COMMON < rarity:
		self.effects.append(BallEffect.EFFECTS_POOL_1[level][rarity])

	# 残像の頂点の記録を開始する
	var tween = _get_tween(TweenType.TRAIL)
	tween.set_loops()
	tween.tween_interval(TRAIL_INTERVAL)
	tween.tween_callback(_refresh_trail_points)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_touch_button.pressed.connect(func(): pressed.emit())
	_touch_button.mouse_entered.connect(func(): hovered.emit(true))
	_touch_button.mouse_exited.connect(func(): hovered.emit(false))

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
	_body_texture.self_modulate = BALL_BODY_COLORS[level]
	if 0 < level:
		_body_texture.self_modulate = BALL_BODY_COLORS[5] # オレンジ固定
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
		_inner_texture_2.self_modulate = BALL_RARITY_COLORS[rarity]
		_level_label.self_modulate = BALL_RARITY_COLORS[rarity]

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

	# 残像
	var gradient = Gradient.new()
	if is_active:
		gradient.set_color(0, Color(BALL_BODY_COLORS[level], 0.5))
		gradient.set_color(1, Color(BALL_BODY_COLORS[level], 0))
		if 0 < level:
			gradient.set_color(0, Color(BALL_BODY_COLORS[5], 0.5)) # オレンジ固定
			gradient.set_color(1, Color(BALL_BODY_COLORS[5], 0)) # オレンジ固定
	else:
		gradient.set_color(0, Color(BALL_BODY_COLORS[0], 0.5))
		gradient.set_color(1, Color(BALL_BODY_COLORS[0], 0))
	_trail_line.gradient = gradient


# 自信の物理判定を更新する
func refresh_physics() -> void:
	# 展示用
	if is_display:
		freeze = true
		collision_layer = 0
		_hole_area.monitoring = false


func show_hover() -> void:
	_hover_texture.visible = true

func hide_hover() -> void:
	_hover_texture.visible = false


# 移動する
func warp(to: Vector2) -> void:
	var tween = _get_tween(TweenType.WARP)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", to, WARP_DURATION)


func _on_body_entered(body: Node) -> void:
	# 他の Ball にぶつかったとき
	if body is Ball:
		# 有効化されていない場合: 有効化する
		if not is_active:
			is_active = true
			refresh_view()


# 残像の頂点を記録する
func _refresh_trail_points() -> void:
	_trail_points.push_front(self.position)
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
