class_name HelpPopup
extends Control


const SHOW_DURATION := 0.2


@export var _panel_container: PanelContainer
@export var _label: RichTextLabel


var _tween: Tween:
	get():
		if _tween:
			_tween.kill()
		return create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)


func show_popup_common(help_area: HelpArea) -> void:
	_update_content_common(help_area)
	_show_popup(help_area)


func show_popup_ball(ball: Ball) -> void:
	# ビリヤード上のボールは popup を表示しない
	if ball.is_on_billiards:
		return
	_update_content_ball(ball)
	_show_popup(ball.help_area)


func show_popup_hole(hole: Hole) -> void:
	_update_content_hole(hole)
	_show_popup(hole.help_area)


func hide_popup() -> void:
	_tween.tween_property(self, "modulate", Color.TRANSPARENT, SHOW_DURATION)


func _update_content_common(help_area: HelpArea) -> void:
	var title := tr("%s_title" % [help_area.key])
	var description := tr("%s_desc" % [help_area.key])
	_label.text = "[b]%s[/b]\n%s" % [title, description]


func _update_content_ball(ball: Ball) -> void:
	var text := ""
	if 0 <= ball.number:
		var pool = Ball.Pool.keys()[ball.pool]
		var rarity = BallEffect.RARITY_TEXT[ball.rarity]
		text += "[b]%s-%s %s[/b]\n" % [pool, ball.number, rarity]
	text += BallEffect.get_effect_description(ball.number, ball.rarity)
	_label.text = text


func _update_content_hole(hole: Hole) -> void:
	var hole_type_string = Hole.HoleType.keys()[hole.hole_type]
	var title := tr("hole_%s_title" % [hole_type_string])
	var description := tr("hole_%s_desc" % [hole_type_string])

	match hole.hole_type:
		Hole.HoleType.WARP_TO, Hole.HoleType.WARP_FROM:
			var warp_type_string = Hole.WarpGroup.keys()[hole.warp_group]
			title = title.format({ "a": warp_type_string })
			description = description.format({ "a": warp_type_string })
		Hole.HoleType.EXTRA:
			pass
		Hole.HoleType.GAIN:
			title = title.format({ "a": hole.gain_ratio })
			description = description.format({ "a": hole.gain_ratio })
		Hole.HoleType.LOST:
			pass
		Hole.HoleType.STACK:
			pass

	if hole.disabled:
		var color := ColorPalette.DANGER.to_html()
		description += "\n[color=%s](%s)[/color]" % [color, tr("hole_disabled")]

	_label.text = "[b]%s[/b]\n%s" % [title, description]


func _show_popup(help_area: HelpArea) -> void:
	# NOTE: _panel_container.size に Label の大きさが反映されないのでこうしている
	_panel_container.visible = false
	_panel_container.visible = true

	# 出現位置を調整する
	# 画面の 左/右 x 上/下 で4パターン
	var viewport_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var viewport_height = ProjectSettings.get_setting("display/window/size/viewport_height")
	var diff_x := help_area.size.x # 左上
	var diff_y := help_area.size.y # 左上
	if (viewport_width / 2) < help_area.global_position.x:
		diff_x = _panel_container.size.x * -1 # 右
	if (viewport_height / 2) < help_area.global_position.y:
		diff_y = _panel_container.size.y * -1 # 下
	global_position = help_area.global_position + Vector2(diff_x, diff_y)

	_tween.tween_property(self, "modulate", Color.WHITE, SHOW_DURATION)
