class_name Ball
extends RigidBody2D


# ボールの色の定義 { <Level>: Color } 
const BALL_COLORS = {
	-1: Color(0.5, 0.5, 0.5, 0.5),
	0: Color(0.875, 0.875, 0.875), 1: Color.YELLOW, 2: Color.BLUE, 3: Color.RED,
	4: Color.PURPLE, 5: Color.ORANGE, 6: Color.GREEN, 7: Color.SADDLE_BROWN,
	8: Color(0.125, 0.125, 0.125), 9: Color.GOLD, 10: Color.LIGHT_BLUE, 11: Color.LIGHT_CORAL,
	12: Color.LIGHT_SALMON, 13: Color.LIGHT_SALMON, 14: Color.LIGHT_GREEN, 15: Color.ROSY_BROWN,
}


@export var level: int = 0 # ボール番号
@export var is_display: bool = false # 展示用かどうか

@export var _texture_rect: TextureRect # ボールの色
@export var _texture_rect_in: TextureRect # ボール番号の背景
@export var _label: Label
@export var _area2d: Area2D


func _ready() -> void:
	refresh_view()


# 自身の見た目を更新する
func refresh_view() -> void:
	# 色
	_texture_rect.self_modulate = BALL_COLORS[level]

	# ボール番号
	if level < 0:
		_texture_rect_in.visible = false
		_label.visible = false
	else:
		_texture_rect_in.visible = true
		_label.visible = true
		_label.text = str(level)

	# 展示用
	if is_display:
		freeze = true
		collision_layer = 0
		_area2d.monitoring = false
