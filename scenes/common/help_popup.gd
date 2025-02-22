class_name HelpPopup
extends Control


@export var _panel: Panel
@export var _title_label: Label
@export var _title_sub_label: Label
@export var _description_label: RichTextLabel


func update_content(help_area: HelpArea) -> void:
	var viewport_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var viewport_height = ProjectSettings.get_setting("display/window/size/viewport_height")
	var diff_x := help_area.size.x # 左上
	var diff_y := help_area.size.y # 左上
	if (viewport_width / 2) < help_area.global_position.x:
		diff_x = _panel.size.x * -1 # 右対応
	if (viewport_height / 2) < help_area.global_position.y:
		diff_y = _panel.size.y * -1 # 下対応
	global_position = help_area.global_position + Vector2(diff_x, diff_y)

	if help_area.related_object:
		if help_area.related_object is Ball:
			_update_content_ball(help_area.related_object)
		elif help_area.related_object is Hole:
			_update_content_hole(help_area.related_object)
	else:
		_update_content_common(help_area)


func _update_content_common(help_area: HelpArea) -> void:
	_title_label.text = tr(help_area.title_key)
	_title_sub_label.text = tr(help_area.title_sub_key)
	_description_label.text = tr(help_area.description_key)


func _update_content_ball(ball: Ball) -> void:
	if ball.is_on_billiards:
		visible = false
		return

	if ball.number < 0:
		_title_label.text = "-"
		_title_sub_label.text = ""
		_title_sub_label.self_modulate = Color.WHITE
	else:
		_title_label.text = "%s-%s" % [Ball.Pool.keys()[ball.pool], ball.number]
		_title_sub_label.text = BallEffect.RARITY_TEXT[ball.rarity]
		_title_sub_label.self_modulate = ColorPalette.BALL_RARITY_COLORS[ball.rarity]
	_description_label.text = BallEffect.get_effect_description(ball.number, ball.rarity)


func _update_content_hole(hole: Hole) -> void:
	pass
