class_name Nail
extends StaticBody2D


func _ready() -> void:
	enable()


# 有効化する
func enable() -> void:
	collision_layer = Collision.Layer.BASE
	modulate = Color(1, 1, 1, 1)

# 無効化する
func disable() -> void:
	collision_layer = Collision.Layer.NONE
	modulate = Color(1, 1, 1, 0.1)
