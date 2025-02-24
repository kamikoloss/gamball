class_name Information
extends Control


signal exit_button_pressed


enum TweenType { WINDOW }


const WINDOW_SHOW_DURATION := 0.2


@export var _exit_button: Button
@export var _menu_help_areas: Control
@export var _default_menu_help_area: HelpArea

@export_category("BallEffects")
@export var _balls_parent: Control
@export var _ball_effect_selector: Selector
@export var _ball_effect_description: RichTextLabel


var _current_menu_help_area: HelpArea
var _tweens := {}


func _ready() -> void:
	_exit_button.pressed.connect(func(): exit_button_pressed.emit())

	# MenuHelpAreas
	for node in get_tree().get_nodes_in_group("help_area"):
		if node is HelpArea:
			node.hovered.connect(func(n, v): _on_help_area_hovered(node, v))
			node.pressed.connect(func(n): _on_help_area_pressed(node))
	# Windows
	for help_area in _menu_help_areas.get_children():
		if help_area.object:
			help_area.object.visible = true
			help_area.object.modulate = Color.TRANSPARENT
	if _default_menu_help_area:
		_on_help_area_pressed(_default_menu_help_area)
	
	_init_ball_effects()
	_init_licenses()


func _on_help_area_hovered(help_area: HelpArea, hovered: bool) -> void:
	if help_area.object:
		if help_area.object is Ball:
			_update_ball_effect_label(help_area.object)


func _on_help_area_pressed(help_area: HelpArea) -> void:
	var tween := _get_tween(TweenType.WINDOW)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	# 現在表示中の Window を非表示にする
	if _current_menu_help_area and _current_menu_help_area.object:
		tween.tween_property(_current_menu_help_area.object, "modulate", Color.TRANSPARENT, WINDOW_SHOW_DURATION)
	# クリックされた Window を表示する
	_current_menu_help_area = help_area
	if _current_menu_help_area.object:
		tween.tween_property(_current_menu_help_area.object, "modulate", Color.WHITE, WINDOW_SHOW_DURATION)


func _show_window(window: Control) -> void:
	pass


func _init_ball_effects() -> void:
	# Selector
	var pool_options := {}
	for value in Ball.Pool.values():
		pool_options[value] = "Pool %s" % [Ball.Pool.keys()[value]]
	_ball_effect_selector.options = pool_options
	_ball_effect_selector.value = Ball.Pool.A
	# Balls
	var number = 0
	for node in _balls_parent.get_children():
		if node is Ball:
			node.number = number
			node.refresh_view()
			number += 1
	# Decription
	_ball_effect_description.text = ""


func _init_licenses() -> void:
	pass


# Ball の効果をレアリティごとにすべて表示する
func _update_ball_effect_label(ball: Ball) -> void:
	var text := ""
	var pool_text = Ball.Pool.keys()[ball.pool]
	text += "[font_size=24][b]%s-%s[/b][/font_size]\n" % [pool_text, ball.number]
	text += "[font_size=8] [/font_size]\n" # ハーフ改行
	for rarity in Ball.Rarity.values():
		var rarity_text = BallEffect.RARITY_TEXT[rarity]
		var rarity_color: Color = ColorPalette.BALL_RARITY_COLORS[rarity]
		var rarity_color_code = rarity_color.to_html()
		text += "[color=%s][b]%s[/b][/color]\n" % [rarity_color_code, rarity_text]
		text += "%s\n" % [BallEffect.get_effect_description(ball.number, rarity)]
		text += "[font_size=8] [/font_size]\n" # ハーフ改行
	_ball_effect_description.text = text


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
