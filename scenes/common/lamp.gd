class_name Lamp
extends Control


# ランプの発光色の種類
enum LightColor {
	DEFAULT_OFF, DEFAULT_ON,
	GREEN_OFF, GREEN_ON,
}


# ランプの発光色 { LightColor: Color } 
const LIGHT_COLORS := {
	LightColor.DEFAULT_OFF: Color(ColorPalette.BLACK, 0.5), # NOTE: フレーム上に置くため半透明にした
	LightColor.DEFAULT_ON: ColorPalette.WHITE,
	LightColor.GREEN_OFF: ColorPalette.SUCCESS,
	LightColor.GREEN_ON: Color.GREEN,
}


@export var _texture: TextureRect


var disabled : = true:
	set(v):
		disabled = v
		_refresh_view()


var _on_color := LightColor.DEFAULT_ON # 点灯時の色
var _off_color := LightColor.DEFAULT_OFF # 消灯時の色


func set_light_colors(on_color: LightColor, off_color: LightColor) -> void:
	#print("[Lamp] set_light_colors on/off: %s/%s" % [on_color, off_color])
	_on_color = on_color
	_off_color = off_color
	_refresh_view()


func _refresh_view() -> void:
	if disabled:
		_texture.self_modulate = LIGHT_COLORS[_off_color]
	else:
		_texture.self_modulate = LIGHT_COLORS[_on_color]
