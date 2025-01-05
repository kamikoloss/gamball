class_name Nail
extends StaticBody2D


func _ready() -> void:
	enable()


# 有効化する
func enable() -> void:
	set_collision_layer_value(Collision.Layer.BASE, true)
	modulate = Color(1, 1, 1, 1)

# 無効化する
func disable() -> void:
	set_collision_layer_value(Collision.Layer.BASE, false)
	modulate = Color(1, 1, 1, 0.1)
