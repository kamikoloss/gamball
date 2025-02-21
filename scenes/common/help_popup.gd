class_name HelpPopup
extends Control


# Popup が表示される座標の差 (左上)
const POPUP_POSITION_DIFF := Vector2(40, 40)


@export var _help_popup_title: Label
@export var _help_popup_title_sub: Label
@export var _help_popup_description: RichTextLabel


func _ready() -> void:
	pass


func update_help_popup(help_area: HelpArea) -> void:
	print("[HelpPopup] update_help_popup")
	position = help_area.global_position + POPUP_POSITION_DIFF
	if help_area.related_object:
		if help_area.related_object is Ball:
			_update_help_popup_ball(help_area.related_object)
		elif help_area.related_object is Hole:
			_update_help_popup_hole(help_area.related_object)
	else:
		_update_help_popup(help_area)


func _update_help_popup(help_area: HelpArea) -> void:
	_help_popup_title.text = tr(help_area.title_key)
	_help_popup_title_sub.text = tr(help_area.title_sub_key)
	_help_popup_description.text = tr(help_area.description_key)


func _update_help_popup_ball(ball: Ball) -> void:
	if ball.number < 0:
		_help_popup_title.text = "-"
		_help_popup_title_sub.text = ""
		_help_popup_title_sub.self_modulate = Color.WHITE
	else:
		_help_popup_title.text = "%s-%s" % [Ball.Pool.keys()[ball.pool], ball.number]
		_help_popup_title_sub.text = BallEffect.RARITY_TEXT[ball.rarity]
		_help_popup_title_sub.self_modulate = ColorPalette.BALL_RARITY_COLORS[ball.rarity]
	_help_popup_description.text = BallEffect.get_effect_description(ball.number, ball.rarity)


func _update_help_popup_hole(hole: Hole) -> void:
	pass
