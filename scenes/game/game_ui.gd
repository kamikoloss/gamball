class_name GameUi
extends Control


enum TweenType { TAX, SHOP, BUNNY, BUBBLE, COUNT_DOWN }
enum DialogueFontSize { BASE, MEDIUM, LARGE }

# Signal
signal info_button_pressed
signal options_button_pressed
signal tax_pay_button_pressed
signal shop_exit_button_pressed
signal product_hovered
signal product_pressed


# Window 移動系
const WINDOW_POSITION_HORIZONTAL_FROM := Vector2(1280, 0)
const WINDOW_POSITION_HORIZONTAL_TO := Vector2(-1280, 0)
const WINDOW_MOVE_DURATION := 1.0

# Bunny 移動系
const BUNNY_POSITION_SMALL_IN := Vector2(1160, 0)
const BUNNY_POSITION_SMALL_OUT := Vector2(1920, 0)
const BUNNY_POSITION_LARGE_OUT := Vector2(1920, -240)
const BUNNY_POSITION_LARGE_IN := Vector2(960, -240)
const BUNNY_MOVE_DURATION := 1.0

# BallPopup を表示するオブジェクトからの位置
const BALL_POPUP_POSITION_DIFF := Vector2(0, 40)

# セリフのフェードの秒数
const DIALOGUE_FADE_DURATION := 0.4
# セリフのフォントサイズ
const DIALOGUE_FONT_SIZE := {
	DialogueSize.BASE: 16,
	DialogueSize.MEDIUM: 24,
	DialogueSize.LARGE: 32,
}

# ログの最大行数
const LOG_LINES_MAX := 100



@export var _log_label: RichTextLabel

@export_category("Scenes")
@export var _popup_score_scene: PackedScene

@export_category("Main/Balls")
@export var _deck_balls_parent: Node2D
@export var _extra_balls_parent: Node2D
@export var _deck_min_lamp: Control
@export var _extra_max_lamp: Control
@export_category("Main/Score")
@export var _turn_label: Label
@export var _next_turn_label: Label
@export var _balls_label: Label
@export var _next_balls_label: Label
@export_category("Main/Buttons")
@export var _info_button: Button
@export var _options_button: Button
@export_category("Main/Bunny+")
@export var _bunny: Bunny
@export var _bubble_top: Control
@export var _dialogue_top: RichTextLabel
@export var _bubble_bottom: Control
@export var _dialogue_bottom: RichTextLabel
@export_category("Main/Combo")
@export var _combo_bar: ColorRect

@export_category("Tax")
@export var _tax_window: Control
@export var _tax_pay_button: Button
@export var _tax_table_parent: BoxContainer

@export_category("Shop")
@export var _shop_window: Control
@export var _shop_exit_button: Button
@export var _products_parent: Control

@export_category("Popup")
@export var _popup: Control
@export var _popup_title: Label
@export var _popup_title_sub: Label
@export var _popup_description: RichTextLabel


var combo_bar_progress := 1.0:
	set(v):
		_combo_bar.scale.x = v


var _target_bubble: Control
var _target_dialogue: RichTextLabel

var _log_lines: Array[String] = []
var _tweens := {}


func _ready() -> void:
	# Main/Ball
	for node in _deck_balls_parent.get_children():
		if node is Ball:
			node.hovered.connect(func(entered): _on_deck_extra_balls_hovered(node, entered))
	for node in _extra_balls_parent.get_children():
		if node is Ball:
			node.hovered.connect(func(entered): _on_deck_extra_balls_hovered(node, entered))
	_hide_ball_popup()
	# Main/Buttons
	_info_button.pressed.connect(func(): info_button_pressed.emit())
	_options_button.pressed.connect(func(): options_button_pressed.emit())

	# Tax
	_tax_pay_button.pressed.connect(func(): tax_pay_button_pressed.emit())

	# Shop
	_shop_exit_button.pressed.connect(func(): shop_exit_button_pressed.emit())
	for node in _products_parent.get_children():
		if node is Product:
			node.hovered.connect(func(n, on): product_hovered.emit(node, on))
			node.pressed.connect(func(n): product_pressed.emit(node))

	# Bunny+
	_bunny.pressed.connect(func(): _on_bunny_pressed())
	_bunny.size_type = Bunny.SizeType.SMALL
	set_dialogue("...")
	_bubble_top.modulate = Color.WHITE
	_bubble_bottom.modulate = Color.TRANSPARENT
	_target_bubble = _bubble_top
	_target_dialogue = _dialogue_top


func show_tax_window() -> void:
	_tax_window.visible = true
	_tax_window.position = WINDOW_POSITION_HORIZONTAL_FROM
	var tween = _get_tween(TweenType.TAX)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_tax_window, "position", Vector2.ZERO, WINDOW_MOVE_DURATION)

func hide_tax_window() -> void:
	var tween = _get_tween(TweenType.TAX)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_tax_window, "position", WINDOW_POSITION_HORIZONTAL_TO, WINDOW_MOVE_DURATION)


func show_shop_window() -> void:
	_shop_window.visible = true
	_shop_window.position = WINDOW_POSITION_HORIZONTAL_FROM
	var tween = _get_tween(TweenType.SHOP)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_shop_window, "position", Vector2.ZERO, WINDOW_MOVE_DURATION)

func hide_shop_window() -> void:
	var tween = _get_tween(TweenType.SHOP)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_shop_window, "position", WINDOW_POSITION_HORIZONTAL_TO, WINDOW_MOVE_DURATION)


#Main/Balls
func update_deck_balls(deck_ball_list: Array[Ball], min: int, max: int) -> void:
	_refresh_balls(_deck_balls_parent, deck_ball_list, min, max)

func update_extra_balls(extra_ball_list: Array[Ball], min: int, max: int) -> void:
	_refresh_balls(_extra_balls_parent, extra_ball_list, min, max)

func update_deck_slots(shift: int) -> void:
	_deck_min_lamp.position = Vector2(130 - 30 * shift, 0)

func update_extra_slots(shift: int) -> void:
	_extra_max_lamp.position = Vector2(130 + 30 * shift, 0)


# Main/Score
func update_turn_label(turn: int) -> void:
	_turn_label.text = _get_seg_text(turn)

func update_balls_label(balls: int) -> void:
	_balls_label.text = _get_seg_text(balls)

func update_next(turn: int, amount: int) -> void:
	_next_turn_label.text = _get_seg_text(turn)
	_next_balls_label.text = _get_seg_text(amount)

func update_next_clear() -> void:
	_next_turn_label.text = "!!!---"
	_next_balls_label.text = "!!!---"

func _get_seg_text(value: int) -> String:
	return ("%6d" % value).replace(" ", "!")


func add_log(text: String) -> void:
	_log_lines.push_back(text)
	if LOG_LINES_MAX < _log_lines.size():
		_log_lines.pop_front()

	_log_label.clear()
	_log_label.text = "\n".join(_log_lines)

# Main/Score
# NOTE: Bunny ではなく GameUI 側が持っていることに注意する
func set_dialogue(dialogue: String, pose_and_jump: bool = false) -> void:
	if pose_and_jump:
		_bunny.shuffle_pose()
		_bunny.jump()

	var tween = _get_tween(TweenType.BUBBLE)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(_target_bubble, "modulate", Color.TRANSPARENT, DIALOGUE_FADE_DURATION / 2) # 表示を消す
	tween.tween_callback(func(): _target_dialogue.text = dialogue) # セリフを変える
	tween.tween_property(_target_bubble, "modulate", Color.WHITE, DIALOGUE_FADE_DURATION) # 表示を戻す


# NOTE: 消えたまま終わるので set_dialogue で表示させる
func change_target_bubble(bottom: bool = true) -> void:
	var tween = _get_tween(TweenType.BUBBLE)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	# Top -> Bottom
	if bottom:
		_target_bubble = _bubble_bottom
		_target_dialogue = _dialogue_bottom
		tween.tween_property(_bubble_top, "modulate", Color.TRANSPARENT, DIALOGUE_FADE_DURATION / 2)
	# Bottom -> Top
	else:
		_target_bubble = _bubble_top
		_target_dialogue = _dialogue_top
		tween.tween_property(_bubble_bottom, "modulate", Color.TRANSPARENT, DIALOGUE_FADE_DURATION / 2)

	await tween.finished


# 画面外に出て 大きく/小さく なって戻ってくる
func change_bunny_size(large: bool = true) -> void:
	_bunny.disabled = true # バニーのタッチを無効にする
	var tween = _get_tween(TweenType.BUNNY)

	# Small -> Large
	if large:
		tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
		tween.tween_property(_bunny, "position", BUNNY_POSITION_SMALL_OUT, BUNNY_MOVE_DURATION)
		tween.tween_callback(func(): _bunny.size_type = Bunny.SizeType.LARGE)
		tween.tween_callback(func(): _bunny.position = BUNNY_POSITION_LARGE_OUT)
		tween.tween_callback(func(): _bunny.shuffle_pose())
		tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		tween.tween_property(_bunny, "position", BUNNY_POSITION_LARGE_IN, BUNNY_MOVE_DURATION)
	# Large -> Small
	else:
		tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
		tween.tween_property(_bunny, "position", BUNNY_POSITION_LARGE_OUT, BUNNY_MOVE_DURATION)
		tween.tween_callback(func(): _bunny.size_type = Bunny.SizeType.SMALL)
		tween.tween_callback(func(): _bunny.position = BUNNY_POSITION_SMALL_OUT)
		tween.tween_callback(func(): _bunny.shuffle_pose())
		tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		tween.tween_property(_bunny, "position", BUNNY_POSITION_SMALL_IN, BUNNY_MOVE_DURATION)

	tween.tween_callback(func(): _bunny.disabled = false) # バニーのタッチを有効に戻す
	await tween.finished


func count_down() -> void:
	_bunny.disabled = true # バニーのタッチを無効にする
	set_dialogue(tr("bunny_countdown_start"), true)

	var tween = _get_tween(TweenType.COUNT_DOWN)
	tween.tween_interval(2.0)
	tween.tween_callback(func(): set_dialogue(tr("bunny_countdown_3"), true))
	tween.tween_interval(1.0)
	tween.tween_callback(func(): set_dialogue(tr("bunny_countdown_2"), true))
	tween.tween_interval(1.0)
	tween.tween_callback(func(): set_dialogue(tr("bunny_countdown_1"), true))
	tween.tween_interval(1.0)
	tween.tween_callback(func(): set_dialogue(tr("bunny_countdown_0"), true))
	tween.tween_interval(1.0)
	tween.tween_callback(func(): _bunny.disabled = false) # バニーのタッチを有効に戻す

	await tween.finished


func popup_score(from: Vector2, text: String, color: Color = Color.WHITE, ratio: float = 1.0) -> void:
	var popup_score: PopupScore = _popup_score_scene.instantiate()
	popup_score.set_font_color(color)
	popup_score.set_font_size(ratio)
	add_child(popup_score)
	popup_score.popup(from, text)


func _on_deck_extra_balls_hovered(ball: Ball, entered: bool) -> void:
	if entered:
		_show_ball_popup(ball)
		ball.show_hover()
	else:
		_hide_ball_popup()
		ball.hide_hover()


func _show_ball_popup(ball: Ball) -> void:
	#print("[GameUi] _show_ball_popup(%s)" % [ball])
	_popup.visible = true
	_popup.position = ball.global_position + BALL_POPUP_POSITION_DIFF
	if ball.number < 0:
		_popup_title.text = "-"
		_popup_title_sub.text = ""
		_popup_title_sub.self_modulate = Color.WHITE
	else:
		_popup_title.text = "%s-%s" % [Ball.Pool.keys()[ball.pool], ball.number]
		_popup_title_sub.text = BallEffect.RARITY_TEXT[ball.rarity]
		_popup_title_sub.self_modulate = ColorPalette.BALL_RARITY_COLORS[ball.rarity]
	_popup_description.text = BallEffect.get_effect_description(ball.number, ball.rarity)

func _hide_ball_popup() -> void:
	#print("[GameUi] _hide_ball_popup()")
	_popup.visible = false


func _refresh_balls(parent_node: Node, ball_list: Array[Ball], min: int, max: int) -> void:
	var index = 0
	for node in parent_node.get_children():
		if node is Ball:
			if index < ball_list.size():
				node.number = ball_list[index].number
				node.rarity = ball_list[index].rarity
			elif max <= index:
				node.number = Ball.BALL_NUMBER_DISABLED_SLOT
				node.rarity = Ball.Rarity.COMMON
			else:
				node.number = Ball.BALL_NUMBER_OPTIONAL_SLOT
				node.rarity = Ball.Rarity.COMMON
			#print("refresh ball %s, %s" % [node.number, node.rarity])
			node.refresh_view()
			index += 1


func _on_bunny_pressed() -> void:
	# セリフをランダムに変更する
	# TODO: 状態に応じてランダムの取得元を変更する
	var key := "bunny_normal_%s" % [randi_range(0, 3)]
	set_dialogue(tr(key), true)


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
