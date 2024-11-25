class_name Information
extends Control


signal exit_button_pressed


@export var _exit_button: TextureButton

@export var _balls_parent: Control
@export var _ball_popup_level: Label
@export var _ball_popup_description: RichTextLabel


func _ready() -> void:
	# Signal
	_exit_button.pressed.connect(func(): exit_button_pressed.emit())

	_init_display_balls()


# ボールの展示を初期化する
func _init_display_balls() -> void:
	var level = 0
	for node in _balls_parent.get_children():
		if node is Ball:
			node.level = level
			node.refresh_view()
			node.hovered.connect(func(entered): _show_ball_popup(node) if entered else _hide_ball_popup(node))
			level += 1
	_ball_popup_level.text = ""
	_ball_popup_description.text = ""


# Ball の効果をレアリティごとにすべて表示する
func _show_ball_popup(ball: Ball) -> void:
	ball.show_hover()
	_ball_popup_level.text = str(ball.level)

	var description = " \n"
	for rarity in Ball.Rarity.values():
		var rarity_value = Ball.Rarity.keys()[rarity]
		var rarity_color: Color = Ball.BALL_RARITY_COLORS[rarity]
		var rarity_color_code = rarity_color.to_html()
		description += "[color=%s]%s[/color]" % [rarity_color_code, rarity_value]
		description += " \n"
		description += BallEffect.get_effect_description(ball.level, rarity)
		description += " \n \n"
	_ball_popup_description.text = description

func _hide_ball_popup(ball: Ball) -> void:
	# hover だけ非表示にする
	ball.hide_hover()