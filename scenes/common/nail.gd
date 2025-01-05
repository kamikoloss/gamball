class_name Nail
extends StaticBody2D


func _ready() -> void:
	enable()


# 有効化する
func enable() -> void:
	modulate = Color(1, 1, 1, 1)
	set_collision_layer_value(Collision.Layer.BASE, true)

# 無効化する
func disable() -> void:
	modulate = Color(1, 1, 1, 0.1)
	set_collision_layer_value(Collision.Layer.BASE, false)
