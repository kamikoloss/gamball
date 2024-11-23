class_name Information
extends Control


@export var _balls_parent: Control
@export var _ball_popup_level: Label
@export var _ball_popup_description: RichTextLabel


func _ready() -> void:
	var level = 0
	for node in _balls_parent.get_children():
		if node is Ball:
			node.level = level
			node.refresh_view()
			node.hovered.connect(func(entered): _show_ball_popup(node))
			level += 1


# Ball の効果をレアリティごとにすべて表示する
func _show_ball_popup(ball: Ball) -> void:
	_ball_popup_level.text = str(ball.level)

	var description = ""
	for rarity in Ball.Rarity.values():
		var rarity_value = Ball.Rarity.keys()[rarity]
		var rarity_color: Color = Ball.BALL_RARITY_COLORS[rarity]
		var rarity_color_code = rarity_color.to_html()
		description += "[color=%s]%s[/color]" % [rarity_color_code, rarity_value]
		description += "\n"
		description += BallEffect.get_effect_description(ball.level, rarity)
		description += "\n \n"
	_ball_popup_description.text = description
