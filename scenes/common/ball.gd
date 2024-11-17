class_name Ball
extends RigidBody2D


signal pressed
#signal mouse_entered # CollisionObject2D が発火する
#signal mouse_exited # CollisionObject2D が発火する


# ボールのレア度
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
# Tween
enum TweenType { RARITY }


# 残像の頂点数
const TRAIL_MAX_LENGTH = 15
# 特殊なボール番号
const BALL_LEVEL_EMPTY_SLOT = -1

# ボールの本体の色の定義 { <Level>: Color } 
const BALL_BODY_COLORS = {
	BALL_LEVEL_EMPTY_SLOT: Color(0.5, 0.5, 0.5, 0.3), # 空きスロット用
	0: Color(0.9, 0.9, 0.9), 1: Color.YELLOW, 2: Color.BLUE, 3: Color.RED,
	4: Color.PURPLE, 5: Color.ORANGE, 6: Color.GREEN, 7: Color.SADDLE_BROWN,
	8: Color(0.1, 0.1, 0.1), 9: Color.GOLD, 10: Color.LIGHT_BLUE, 11: Color.LIGHT_CORAL,
	12: Color.LIGHT_SALMON, 13: Color.LIGHT_SALMON, 14: Color.LIGHT_GREEN, 15: Color.ROSY_BROWN,
}
# ボールのレア度の色の定義  { <Rarity>: Color } 
const BALL_RARITY_COLORS = {
	Rarity.UNCOMMON:	Color.DARK_GREEN,
	Rarity.RARE:		Color.DARK_BLUE,
	Rarity.EPIC:		Color.DARK_ORCHID,
	Rarity.LEGENDARY:	Color.DARK_GOLDENROD,
}


# ボール番号
@export var level: int = 0
# 展示用かどうか
@export var is_display: bool = false

# ボールの本体の色部分
@export var _body_texture: TextureRect
# ボール番号の背景部分
@export var _inner_texture: TextureRect
@export var _inner_texture_2: TextureRect
# ボールが有効化されるまで全体を覆う部分
@export var _mask_texture: TextureRect

@export var _level_label: Label
@export var _hole_area: Area2D
@export var _touch_area: Area2D
@export var _trail_line: Line2D


# 他のボールにぶつかって有効化されたかどうか
var is_active = true 
# ボールのレア度
var rarity: Rarity = Rarity.COMMON
# ボールの効果
var effects: Array[BallEffect] = []


# 残像の頂点座標
var _trail_points: Array = []


func _init(level: int = 0, rarity: Rarity = Rarity.COMMON) -> void:
	self.level = level
	self.rarity = rarity


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	input_event.connect(_on_input)
	refresh_view()


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
	elif level < 0:
		_inner_texture.visible = false
		_level_label.visible = false
		_level_label.text = ""
	else:
		_inner_texture.visible = true
		_level_label.visible = true
		_level_label.text = str(level)

	# 展示用
	if is_display:
		freeze = true
		collision_layer = 0
		_hole_area.monitoring = false

	# 残像
	var gradient = Gradient.new()
	if not is_active:
		gradient.set_color(0, Color(BALL_BODY_COLORS[0], 0.5))
		gradient.set_color(1, Color(BALL_BODY_COLORS[0], 0))
	else:
		gradient.set_color(0, Color(BALL_BODY_COLORS[level], 0.5))
		gradient.set_color(1, Color(BALL_BODY_COLORS[level], 0))
	_trail_line.gradient = gradient


func _on_body_entered(body: Node) -> void:
	# 他の Ball にぶつかったとき
	if body is Ball:
		# 有効化されていない場合: 有効化する
		if not is_active:
			is_active = true
			refresh_view()


func _on_input(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			pressed.emit()
