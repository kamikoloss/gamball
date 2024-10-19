class_name Ball
extends RigidBody2D


# { <Level>: ボールの色 } 
const BALL_COLORS = {
	0: Color.WHITE, 1: Color.YELLOW, 2: Color.BLUE, 3: Color.RED,
	4: Color.PURPLE, 5: Color.ORANGE, 6: Color.GREEN, 7: Color.SADDLE_BROWN,
	8: Color.BLACK, 9: Color.LIGHT_YELLOW, 10: Color.LIGHT_BLUE, 11: Color.LIGHT_CORAL,
	12: Color.LIGHT_SALMON, 13: Color.LIGHT_SALMON, 14: Color.LIGHT_GREEN, 15: Color.ROSY_BROWN,
}


@export var _area: Area2D
@export var _texture_rect: TextureRect
@export var _label: Label


var level: int = 0


func _ready() -> void:
	_area.area_entered.connect(_on_area_entered)
	_init_view()


# level に応じて自身の見た目を決定する
func _init_view() -> void:
	_texture_rect.self_modulate = BALL_COLORS[level]
	_label.text = "%s" % level


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("pocket"):
		print("[Ball] entered to pocket.")
		queue_free()
