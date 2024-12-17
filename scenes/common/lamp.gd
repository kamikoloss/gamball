class_name Lamp
extends Control


# ランプの発光色の種類
enum LightColor {
	DEFAULT_OFF, DEFAULT_ON,
	GREEN_OFF, GREEN_ON,
}


# ランプの発光色 { LightColor: Color } 
const LIGHT_COLORS = {
	LightColor.DEFAULT_OFF: Color(0.1, 0.1, 0.1),
	LightColor.DEFAULT_ON: Color(1, 1, 1),
	LightColor.GREEN_OFF: Color(0.2, 0.6, 0.2),
	LightColor.GREEN_ON: Color(0, 1, 0),
}


@export var _texture: TextureRect


var _on_color: LightColor = LightColor.DEFAULT_ON # 点灯時の色
var _off_color: LightColor = LightColor.DEFAULT_OFF # 消灯時の色


func _ready() -> void:
	disable()


# ランプを点灯する
func enable() -> void:
	_change_light_color(_on_color)

# ランプを消灯する
func disable() -> void:
	_change_light_color(_off_color)


# ランプの 点灯色/消灯色 を設定する
func set_light_colors(on_color: LightColor, off_color: LightColor) -> void:
	#print("[Lamp] set_light_colors on/off: %s/%s" % [on_color, off_color])
	_on_color = on_color
	_off_color = off_color


# ランプを 点灯/消灯 する
func _change_light_color(color: LightColor) -> void:
	_texture.self_modulate = LIGHT_COLORS[color]
