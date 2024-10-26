class_name Nail
extends StaticBody2D


# 有効化する
func enable() -> void:
	modulate = Color(1, 1, 1, 1)
	collision_layer = 1

# 無効化する
func disable() -> void:
	modulate = Color(1, 1, 1, 0.1)
	collision_layer = 0
