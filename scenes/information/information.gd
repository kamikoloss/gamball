class_name Information
extends Control


signal exit_button_pressed


enum TweenType { WINDOW }


const WINDOW_SHOW_DURATION := 0.2

const LICENSE_SELECTOR_VALUE_MAIN = 1
const LICENSE_SELECTOR_VALUE_THIRD_PARTY = 2
const LICENSE_SELECTOR_LABELS := {
	LICENSE_SELECTOR_VALUE_MAIN: "Licenses",
	LICENSE_SELECTOR_VALUE_THIRD_PARTY: "Third-party components",
}


@export var _exit_button: Button
@export var _default_menu_help_area: HelpArea

@export_category("Windows")
@export var _windows_parent: Control
@export_category("Windows/BallEffects")
@export var _balls_parent: Control
@export var _ball_effect_selector: Selector
@export var _ball_effect_label: RichTextLabel
@export_category("Windows/Licenses")
@export var _license_selector: Selector
@export var _license_label: RichTextLabel
@export var _license_label_2: RichTextLabel


var _current_menu_help_area: HelpArea
var _tweens := {}


func _ready() -> void:
	_exit_button.pressed.connect(func(): exit_button_pressed.emit())

	# HelpArea
	for node in get_tree().get_nodes_in_group("help_area"):
		if node is HelpArea:
			node.hovered.connect(func(n, v): _on_help_area_hovered(node, v))
			#node.pressed.connect(func(n): _on_help_area_pressed(node))
	# Windows
	_init_ball_effects()
	_init_licenses()
	for window in _windows_parent.get_children():
		window.visible = false
	if _default_menu_help_area:
		_current_menu_help_area = _default_menu_help_area
		_show_window(_default_menu_help_area)


func _on_help_area_hovered(help_area: HelpArea, hovered: bool) -> void:
	if not hovered:
		return
	if help_area.object:
		if help_area.object is Ball:
			_update_ball_effect_label(help_area.object)
		else:
			_show_window(help_area)


func _show_window(help_area: HelpArea) -> void:
	var tween := _get_tween(TweenType.WINDOW)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)

	var window_from = _current_menu_help_area.object
	var window_to = help_area.object
	_current_menu_help_area = help_area
	# 現在表示中の Window を非表示にする
	tween.tween_property(_windows_parent, "modulate", Color.TRANSPARENT, WINDOW_SHOW_DURATION)
	tween.tween_callback(func(): window_from.visible = false)
	# クリックされた Window を表示する
	tween.tween_callback(func(): window_to.visible = true)
	tween.tween_property(_windows_parent, "modulate", Color.WHITE, WINDOW_SHOW_DURATION)


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
	# Label
	_ball_effect_label.text = ""


func _init_licenses() -> void:
	# Selector
	_license_selector.options = LICENSE_SELECTOR_LABELS
	_license_selector.value = LICENSE_SELECTOR_VALUE_MAIN
	_license_selector.changed.connect(func(v):
		_license_label.visible = false
		_license_label_2.visible = false
		match v:
			LICENSE_SELECTOR_VALUE_MAIN:
				_license_label.visible = true
			LICENSE_SELECTOR_VALUE_THIRD_PARTY:
				_license_label_2.visible = true
	)
	# Label
	var text_2 := ""
	for info_key in Engine.get_license_info().keys():
		text_2 += "[font_size=8]%s[/font_size]" % [Engine.get_license_info()[info_key]]
	_license_label_2.text = text_2


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
	_ball_effect_label.text = text


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
