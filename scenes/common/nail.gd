class_name Nail
extends StaticBody2D


var disabled: bool = false:
	set(v):
		disabled = v
		set_collision_layer_value(Collision.Layer.BASE, true)
		_refresh_view()


func _refresh_view() -> void:
	if disabled:
		modulate = Color(Color.WHITE, 0.2)
	else:
		modulate = Color(Color.WHITE, 1.0)
