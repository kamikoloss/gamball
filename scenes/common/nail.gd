class_name Nail
extends StaticBody2D


var disabled := false:
	set(v):
		disabled = v
		_refresh_view()
		_refresh_physics()


func _refresh_view() -> void:
	if disabled:
		modulate = Color(Color.WHITE, 0.2)
	else:
		modulate = Color(Color.WHITE, 1.0)


func _refresh_physics() -> void:
	set_collision_layer_value(Collision.Layer.BASE, not disabled)
