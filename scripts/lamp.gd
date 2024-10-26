class_name Lamp
extends Control


# ランプの発光色の種類
enum LightColor {
	OFF,
	OFF_GREEN,
	WHITE,
	RED,
	GREEN,
}


# ランプの発光色 { LightColor: Color } 
const LIGHT_COLORS = {
	LightColor.OFF: Color(0.5, 0.5, 0.5),
	LightColor.OFF_GREEN: Color(0.5, 1, 0.5),
	LightColor.WHITE: Color.WHITE,
	LightColor.RED: Color.RED,
	LightColor.GREEN: Color.GREEN,
}


@export var _texture: TextureRect


func _ready() -> void:
	disable()


# ランプを点灯する
func enable() -> void:
	change_light_color(LightColor.WHITE)

# ランプを消灯する
func disable() -> void:
	change_light_color(LightColor.OFF)


# ランプの点灯色を変更する
func change_light_color(color: LightColor) -> void:
	_texture.self_modulate = LIGHT_COLORS[color]
