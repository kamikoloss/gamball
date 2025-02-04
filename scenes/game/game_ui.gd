class_name GameUi
extends Control


enum TweenType { TAX, SHOP, BUNNY, BUBBLE, DIALOGUE, COUNT_DOWN }


# Signal
signal buy_balls_button_pressed
signal sell_balls_button_pressed
signal tax_pay_button_pressed
signal shop_exit_button_pressed
signal info_button_pressed
signal options_button_pressed


# Window 移動系
const WINDOW_POSITION_BOTTOM_FROM := Vector2(0, 720)
const WINDOW_POSITION_BOTTOM_TO := Vector2(0, -720)
const WINDOW_POSITION_RIGHT_FROM := Vector2(1280, 0)
const WINDOW_POSITION_RIGHT_TO := Vector2(720, 0)
const WINDOW_POSITION_TO := Vector2(0, 0)
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
# ログの最大行数
const LOG_LINES_MAX := 100


@export var _log_label: RichTextLabel

@export_category("Scenes")
@export var _popup_score_scene: PackedScene

@export_category("Main/Balls")
@export var _deck_balls_parent: Node2D
@export var _extra_balls_parent: Node2D
@export var _ball_popup: Control
@export var _ball_popup_level: Label
@export var _ball_popup_rarity: Label
@export var _ball_popup_description: RichTextLabel
@export_category("Main/Score")
@export var _turn_label: Label
@export var _next_turn_label: Label
@export var _money_label: Label
@export var _next_money_label: Label
@export var _balls_label: Label
@export var _next_balls_label: Label
@export_category("Main/Buttons")
@export var _buy_balls_button: Button
@export var _sell_balls_button: Button
@export var _info_button: Button
@export var _options_button: Button
@export_category("Main/Bunny+")
@export var _bunny: Bunny
@export var _bubble_top: Control
@export var _dialogue_top: RichTextLabel
@export var _bubble_bottom: Control
@export var _dialogue_bottom: RichTextLabel

@export_category("Tax")
@export var _tax_window: Control
@export var _tax_pay_button: Button
@export var _tax_table_parent: BoxContainer

@export_category("Shop")
@export var _shop_window: Control
@export var _shop_exit_button: Button


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
	_buy_balls_button.pressed.connect(func(): buy_balls_button_pressed.emit())
	_sell_balls_button.pressed.connect(func(): sell_balls_button_pressed.emit())
	_info_button.pressed.connect(func(): info_button_pressed.emit())
	_options_button.pressed.connect(func(): options_button_pressed.emit())

	# Tax
	_tax_pay_button.pressed.connect(func(): tax_pay_button_pressed.emit())
	# Shop
	_shop_exit_button.pressed.connect(func(): shop_exit_button_pressed.emit())

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
	_tax_window.position = WINDOW_POSITION_BOTTOM_FROM
	var tween = _get_tween(TweenType.TAX)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_tax_window, "position", WINDOW_POSITION_TO, WINDOW_MOVE_DURATION)

func hide_tax_window() -> void:
	var tween = _get_tween(TweenType.TAX)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_tax_window, "position", WINDOW_POSITION_BOTTOM_TO, WINDOW_MOVE_DURATION)


func show_shop_window() -> void:
	_shop_window.visible = true
	_shop_window.position = WINDOW_POSITION_BOTTOM_FROM
	var tween = _get_tween(TweenType.SHOP)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_shop_window, "position", WINDOW_POSITION_TO, WINDOW_MOVE_DURATION)

func hide_shop_window() -> void:
	var tween = _get_tween(TweenType.SHOP)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_shop_window, "position", WINDOW_POSITION_BOTTOM_TO, WINDOW_MOVE_DURATION)


#Main/Balls
func refresh_deck_balls(deck_ball_list: Array[Ball], min: int, max: int) -> void:
	_refresh_balls(_deck_balls_parent, deck_ball_list, min, max)

func refresh_extra_balls(extra_ball_list: Array[Ball], min: int, max: int) -> void:
	_refresh_balls(_extra_balls_parent, extra_ball_list, min, max)

func refresh_deck_slots(min: int, max: int) -> void:
	pass

func refresh_extra_slots(min: int, max: int) -> void:
	pass


# Main/Score
func refresh_turn_label(turn: int) -> void:
	_turn_label.text = _get_seg_text(turn)

func refresh_money_label(money: int) -> void:
	_money_label.text = _get_seg_text(money)

func refresh_balls_label(balls: int) -> void:
	_balls_label.text = _get_seg_text(balls)

func refresh_next(turn: int, type: Game.TaxType, amount: int) -> void:
	_next_turn_label.text = _get_seg_text(turn)
	if type == Game.TaxType.MONEY:
		_next_money_label.text = _get_seg_text(amount)
		_next_balls_label.text = "!!!!"
	else:
		_next_money_label.text = "!!!!"
		_next_balls_label.text = _get_seg_text(amount)

func _get_seg_text(value: int) -> String:
	return ("%4d" % value).replace(" ", "!")

func refresh_next_clear() -> void:
	_next_turn_label.text = "----"
	_next_money_label.text = "----"
	_next_balls_label.text = "----"


func add_log(text: String) -> void:
	_log_lines.push_back(text)
	if LOG_LINES_MAX < _log_lines.size():
		_log_lines.pop_front()

	_log_label.clear()
	_log_label.text = "\n".join(_log_lines)

# Main/Score
# NOTE: Bunny ではなく GameUI 側が持っていることに注意する
func set_dialogue(dialogue: String) -> void:
	var tween = _get_tween(TweenType.DIALOGUE)
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

	await tween.finished


func count_down() -> void:
	_bunny.disable_touch() # バニーのタッチを無効にする

	set_dialogue("[font_size=32][color=DARK_RED]延長[/color]のお時間\nで～す[/font_size]")
	_bunny.shuffle_pose()
	_bunny.jump()

	var tween = _get_tween(TweenType.COUNT_DOWN)
	tween.tween_interval(2.0)
	tween.tween_callback(func(): set_dialogue("[font_size=32]さ～～ん[/font_size]"))
	tween.tween_callback(func(): _bunny.shuffle_pose())
	tween.tween_callback(func(): _bunny.jump())
	tween.tween_interval(1.0)
	tween.tween_callback(func(): set_dialogue("[font_size=32]に～～い[/font_size]"))
	tween.tween_callback(func(): _bunny.shuffle_pose())
	tween.tween_callback(func(): _bunny.jump())
	tween.tween_interval(1.0)
	tween.tween_callback(func(): set_dialogue("[font_size=32]い～～ち[/font_size]"))
	tween.tween_callback(func(): _bunny.shuffle_pose())
	tween.tween_callback(func(): _bunny.jump())
	tween.tween_interval(1.0)
	# Tax Window を表示する
	tween.tween_callback(func(): set_dialogue("ゲームを続けたいなら延長料を払ってね～。\n真ん中の下らへんに出てるやつ。"))
	tween.tween_callback(func(): _bunny.shuffle_pose())
	tween.tween_callback(func(): _bunny.jump())
	tween.tween_callback(func(): _bunny.enable_touch()) # バニーのタッチを有効に戻す

	await tween.finished


func popup_score(from: Vector2, text: String, color: Color = Color.WHITE, ratio: float = 1.0) -> void:
	var popup_score: PopupScore = _popup_score_scene.instantiate()
	popup_score.set_font_color(color)
	popup_score.set_font_size(ratio)
	add_child(popup_score)
	popup_score.popup(from, text)


# tax_list: [ <turn>, TaxType, <amount> ]
func refresh_tax_table(tax_list: Array) -> void:
	var row_index = -1
	var col_index = 0

	for row in _tax_table_parent.get_children():
		col_index = 0
		# ヘッダー行はスキップする
		if row_index == -1:
			row_index += 1
			continue
		for col in row.get_children():
			if col is Label:
				col.text = "----"
				if tax_list.size() <= row_index:
					col_index += 1
					continue
				var turn = tax_list[row_index][0]
				var tax_type = tax_list[row_index][1]
				var amount = tax_list[row_index][2]
				if col_index == 0:
					col.text = str(turn)
				elif col_index == 1 and tax_type == Game.TaxType.MONEY:
					col.text = str(amount)
				elif col_index == 2 and tax_type == Game.TaxType.BALLS:
					col.text = str(amount)
				col_index += 1
		row_index += 1


func _on_deck_extra_balls_hovered(ball: Ball, entered: bool) -> void:
	if entered:
		_show_ball_popup(ball)
		ball.show_hover()
	else:
		_hide_ball_popup()
		ball.hide_hover()


func _show_ball_popup(ball: Ball) -> void:
	#print("[GameUi] _show_ball_popup(%s)" % [ball])
	_ball_popup.visible = true
	_ball_popup.position = ball.global_position + BALL_POPUP_POSITION_DIFF
	if ball.level < 0:
		_ball_popup_level.text = "-"
		_ball_popup_rarity.text = ""
		_ball_popup_rarity.self_modulate = Color.WHITE
	else:
		_ball_popup_level.text = "%s-%s" % [Ball.Pool.keys()[ball.pool], ball.level]
		_ball_popup_rarity.text = BallEffect.RARITY_TEXT[ball.rarity]
		_ball_popup_rarity.self_modulate = ColorPalette.BALL_RARITY_COLORS[ball.rarity]
	_ball_popup_description.text = BallEffect.get_effect_description(ball.level, ball.rarity)

func _hide_ball_popup() -> void:
	#print("[GameUi] _hide_ball_popup()")
	_ball_popup.visible = false


func _refresh_balls(parent_node: Node, ball_list: Array[Ball], min: int, max: int) -> void:
	var index = 0
	for node in parent_node.get_children():
		if node is Ball:
			if index < ball_list.size():
				node.level = ball_list[index].level
				node.rarity = ball_list[index].rarity
			elif max <= index:
				node.level = Ball.BALL_LEVEL_DISABLED_SLOT
				node.rarity = Ball.Rarity.COMMON
			else:
				node.level = Ball.BALL_LEVEL_OPTIONAL_SLOT
				node.rarity = Ball.Rarity.COMMON
			node.refresh_view()
			index += 1


func _on_bunny_pressed() -> void:
	# セリフをランダムに変更する
	# TODO: JSON に逃がす
	var dialogue_list = [
		"いらっしゃ～い！調子どう？",
		"[rainbow]GAMBALL[/rainbow] は近未来のバーチャルハイリスクハイリターンギャンブルだよ！",
		"ビリヤードポケットに入ったボールはパチンコ盤面上にワープしていくよ。",
		"ビリヤードで打ち出すボールは他のボールにぶつからないと有効化されないんだよね～",
	]
	set_dialogue(dialogue_list.pick_random())

	_bunny.shuffle_pose()
	_bunny.jump()


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
