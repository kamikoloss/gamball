class_name Ball
extends RigidBody2D


signal pressed # ()
signal hovered # (entered: bool)


# ボールのレア度
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
# Tween
enum TweenType { RARITY }


# 残像の頂点数
const TRAIL_MAX_LENGTH = 16

# 特殊なボール番号
const BALL_LEVEL_EMPTY_SLOT = -1 # 空きスロット用
const BALL_LEVEL_NOT_EMPTY_SLOT = -2 # 使用不可スロット用

# ボールの本体の色の定義 { <Level>: Color } 
const BALL_BODY_COLORS = {
	BALL_LEVEL_EMPTY_SLOT: Color(0.5, 0.5, 0.5, 0.3),
	BALL_LEVEL_NOT_EMPTY_SLOT: Color(0.9, 0.5, 0.5, 0.3),
	0: Color(0.9, 0.9, 0.9), 1: Color.YELLOW, 2: Color.BLUE, 3: Color.RED,
	4: Color.PURPLE, 5: Color.ORANGE, 6: Color.GREEN, 7: Color.SADDLE_BROWN,
	8: Color(0.1, 0.1, 0.1), 9: Color(Color.YELLOW, 0.7), 10: Color(Color.BLUE, 0.7), 11: Color(Color.RED, 0.7),
	12: Color(Color.PURPLE, 0.7), 13: Color(Color.ORANGE, 0.7), 14: Color(Color.GREEN, 0.7), 15: Color(Color.SADDLE_BROWN, 0.7),
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
@export var level: int = 0
# 展示用かどうか
# pressed は展示用のみ発火する
@export var is_display: bool = false
# ボールがビリヤード盤面上にあるかどうか
# NOTE: ビリヤード盤面上の初期 Ball 用に export している
@export var is_on_billiards: bool = false


# ボールの選択を示す周辺部分
@export var _hover_texture: TextureRect
# ボールの本体の 下地/色 部分
@export var _base_texture: TextureRect
@export var _body_texture: TextureRect
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
var rarity: Rarity = Rarity.COMMON
# ボールの効果
# [ [ <BallEffect.EffectType>, param1, (param2) ], ... ]
var effects: Array = []


# 残像の頂点座標
var _trail_points: Array = []


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

	refresh_view()
	refresh_physics()
	hide_hover()


func _process(delta: float) -> void:
	_trail_points.push_front(self.position)
	if TRAIL_MAX_LENGTH < _trail_points.size():
		_trail_points.pop_back()
	_trail_line.clear_points()
	_trail_line.rotation = 0.0
	for point in _trail_points:
		_trail_line.add_point(point)


# 自身の見た目を更新する
func refresh_view() -> void:
	# 本体色
	if level == BALL_LEVEL_EMPTY_SLOT:
		_base_texture.visible = false
	else:
		_base_texture.visible = true
	_body_texture.self_modulate = BALL_BODY_COLORS[level]
	# レア度色
	if rarity == Rarity.COMMON:
		_inner_texture_2.visible = false
	else:
		_inner_texture_2.visible = true
		_inner_texture_2.self_modulate = Color(BALL_RARITY_COLORS[rarity], 0.3)

	# マスク
	_mask_texture.visible = not is_active # 有効なら表示しない

	# ボール番号
	if not is_active:
		_inner_texture.visible = true
		_level_label.visible = true
		_level_label.text = "??"
	elif level == BALL_LEVEL_EMPTY_SLOT:
		_inner_texture.visible = false
		_level_label.visible = false
		_level_label.text = ""
	else:
		_inner_texture.visible = true
		_level_label.visible = true
		_level_label.text = str(level)

	# 残像
	var gradient = Gradient.new()
	if is_active:
		gradient.set_color(0, Color(BALL_BODY_COLORS[level], 0.5))
		gradient.set_color(1, Color(BALL_BODY_COLORS[level], 0))
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


func _on_body_entered(body: Node) -> void:
	# 他の Ball にぶつかったとき
	if body is Ball:
		# 有効化されていない場合: 有効化する
		if not is_active:
			is_active = true
			refresh_view()
