class_name Ball
extends RigidBody2D


# ボールのレア度
enum Rarity { Common, Rare, Epic, Legendary }


# 残像の頂点数
const TRAIL_MAX_LENGTH = 16
# 特殊なボール番号
const BALL_LEVEL_EMPTY_SLOT = -1

# ボールの色の定義 { <Level>: Color } 
const BALL_COLORS = {
	BALL_LEVEL_EMPTY_SLOT: Color(0.5, 0.5, 0.5, 0.5), # 空きスロット用
	0: Color(0.9, 0.9, 0.9), 1: Color.YELLOW, 2: Color.BLUE, 3: Color.RED,
	4: Color.PURPLE, 5: Color.ORANGE, 6: Color.GREEN, 7: Color.SADDLE_BROWN,
	8: Color(0.1, 0.1, 0.1), 9: Color.GOLD, 10: Color.LIGHT_BLUE, 11: Color.LIGHT_CORAL,
	12: Color.LIGHT_SALMON, 13: Color.LIGHT_SALMON, 14: Color.LIGHT_GREEN, 15: Color.ROSY_BROWN,
}


@export var level: int = 0 # ボール番号
@export var is_display: bool = false # 展示用かどうか

@export var _main_texture: TextureRect # ボールの色部分
@export var _inner_texture: TextureRect # ボール番号の背景部分
@export var _mask_texture: TextureRect # ボールが有効化されるまで全体を覆う部分
@export var _level_label: Label
@export var _hole_area: Area2D
@export var _trail_line: Line2D


var rarity: Rarity = Rarity.Common # ボールのレア度
var is_active = true # 他のボールにぶつかって有効化されたかどうか


var _trail_points: Array = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)
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
	# 色
	_main_texture.self_modulate = BALL_COLORS[level]
	_mask_texture.visible = not is_active # 有効なら表示しない

	# ボール番号
	if not is_active:
		_level_label.visible = true
		_level_label.text = "??"
	elif level < 0:
		_inner_texture.visible = false
		_level_label.visible = false
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
		gradient.set_color(0, Color(BALL_COLORS[0], 0.5))
		gradient.set_color(1, Color(BALL_COLORS[0], 0))
	else:
		gradient.set_color(0, Color(BALL_COLORS[level], 0.5))
		gradient.set_color(1, Color(BALL_COLORS[level], 0))
	_trail_line.gradient = gradient


func _on_body_entered(body: Node) -> void:
	# 他の Ball にぶつかったとき
	if body is Ball:
		# 有効化されていない場合: 有効化する
		if not is_active:
			is_active = true
			refresh_view()
