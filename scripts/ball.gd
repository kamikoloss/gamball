class_name Ball
extends RigidBody2D


# { <Level>: ボールの色 } 
const BALL_COLORS = {
	0: Color.GRAY, 1: Color.YELLOW, 2: Color.BLUE, 3: Color.RED,
	4: Color.PURPLE, 5: Color.ORANGE, 6: Color.GREEN, 7: Color.SADDLE_BROWN,
	8: Color.BLACK, 9: Color.GOLD, 10: Color.LIGHT_BLUE, 11: Color.LIGHT_CORAL,
	12: Color.LIGHT_SALMON, 13: Color.LIGHT_SALMON, 14: Color.LIGHT_GREEN, 15: Color.ROSY_BROWN,
}


@export var level: int = 0

@export var _texture_rect: TextureRect
@export var _label: Label


func _ready() -> void:
	_init_view()


# level に応じて自身の見た目を決定する
func _init_view() -> void:
	_texture_rect.self_modulate = BALL_COLORS[level]
	_label.text = str(level)
