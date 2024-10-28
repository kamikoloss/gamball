class_name Ball
extends RigidBody2D


# ボールのレア度
enum Rarity { Common, Rare, Epic, Legendary }


# ボールの色の定義 { <Level>: Color } 
const BALL_COLORS = {
	-1: Color(0.5, 0.5, 0.5, 0.5),
	0: Color(0.9, 0.9, 0.9), 1: Color.YELLOW, 2: Color.BLUE, 3: Color.RED,
	4: Color.PURPLE, 5: Color.ORANGE, 6: Color.GREEN, 7: Color.SADDLE_BROWN,
	8: Color(0.1, 0.1, 0.1), 9: Color.GOLD, 10: Color.LIGHT_BLUE, 11: Color.LIGHT_CORAL,
	12: Color.LIGHT_SALMON, 13: Color.LIGHT_SALMON, 14: Color.LIGHT_GREEN, 15: Color.ROSY_BROWN,
}


@export var level: int = 0 # ボール番号
@export var is_display: bool = false # 展示用かどうか

@export var _texture_rect: TextureRect # ボールの色
@export var _texture_rect_in: TextureRect # ボール番号の背景
@export var _texture_rect_mask: TextureRect # ボールが有効化したら取れる色
@export var _label: Label
@export var _area2d: Area2D


var rarity: Rarity = Rarity.Common # ボールのレア度
var is_active = true # 他のボールにぶつかって有効化されたかどうか


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	refresh_view()


# 自身の見た目を更新する
func refresh_view() -> void:
	# 色
	_texture_rect.self_modulate = BALL_COLORS[level]
	
	# 
	if is_active:
		_texture_rect_mask.visible = false

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


func _on_body_entered(body: Node) -> void:
	# 他の Ball にぶつかったとき
	if body is Ball:
		# 有効化されていない場合: 有効化する
		if not is_active:
			is_active = true
			refresh_view()
