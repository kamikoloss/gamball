class_name GameUi
extends Control


enum TweenType { TAX, SHOP, PEOPLE }


# Signal
signal buy_balls_button_pressed
signal sell_balls_button_pressed
signal tax_pay_button_pressed
signal shop_exit_button_pressed
signal info_button_pressed
signal options_button_pressed


# Window 移動系
const WINDOW_POSITION_BOTTOM_FROM: Vector2 = Vector2(0, 720)
const WINDOW_POSITION_BOTTOM_TO: Vector2 = Vector2(0, -720)
const WINDOW_POSITION_RIGHT_FROM: Vector2 = Vector2(1280, 0)
const WINDOW_POSITION_RIGHT_TO: Vector2 = Vector2(720, 0)
const WINDOW_POSITION_TO: Vector2 = Vector2(0, 0)
const WINDOW_MOVE_DURATION: float = 1.0

const BALL_POPUP_POSITION_DIFF: Vector2 = Vector2(0, 40)

const LOG_LINES_MAX: int = 100


@export_category("Scenes")
@export var _popup_score_scene: PackedScene

@export_category("Main/Ball")
@export var _deck_balls_parent: Node2D
@export var _deck_slots_parent: Control
@export var _extra_balls_parent: Node2D
@export var _extra_slots_parent: Control
@export var _ball_popup: Control
@export var _ball_popup_level: Label
@export var _ball_popup_rarity: Label
@export var _ball_popup_description: RichTextLabel
@export_category("Main/Buttons")
@export var _buy_balls_button: Button
@export var _sell_balls_button: Button
@export var _info_button: Button
@export var _options_button: Button
@export_category("Main/Score")
@export var _turn_label: Label
@export var _money_label: Label
@export var _payout_label: Label
@export var _balls_label: Label
@export var _next_turn_label: Label
@export var _next_money_label: Label
@export var _next_balls_label: Label
@export var _log_label: RichTextLabel

@export_category("Tax")
@export var _tax_window: Control
@export var _tax_pay_button: Button
@export var _tax_give_up_button: Button
@export var _tax_table_parent: BoxContainer

@export_category("Shop")
@export var _shop_window: Control
@export var _shop_exit_button: Button

@export_category("People")
@export var _people_window: Control


var _log_lines: Array[String] = []
var _tweens: Dictionary = {}


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


func show_people_window() -> void:
	_people_window.visible = true
	_people_window.position = WINDOW_POSITION_RIGHT_FROM
	var tween = _get_tween(TweenType.PEOPLE)
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_people_window, "position", WINDOW_POSITION_TO, WINDOW_MOVE_DURATION)

func hide_people_window() -> void:
	var tween = _get_tween(TweenType.PEOPLE)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_people_window, "position", WINDOW_POSITION_RIGHT_TO, WINDOW_MOVE_DURATION)


#Main/BallsSlotXxxx
func refresh_deck_balls(deck_ball_list: Array[Ball], min: int, max: int) -> void:
	_refresh_balls(_deck_balls_parent, deck_ball_list, min, max)

func refresh_extra_balls(extra_ball_list: Array[Ball], min: int, max: int) -> void:
	_refresh_balls(_extra_balls_parent, extra_ball_list, min, max)

func refresh_deck_slots(min: int, max: int) -> void:
	_refresh_slots(_deck_slots_parent, min, max)

func refresh_extra_slots(min: int, max: int) -> void:
	_refresh_slots(_extra_slots_parent, min, max)


# Main/Score
func refresh_turn_label(turn: int) -> void:
	_turn_label.text = str(turn)
	
func refresh_money_label(money: int) -> void:
	_money_label.text = str(money)

func refresh_payout_label(payout: int) -> void:
	_payout_label.text = str(payout)

func refresh_balls_label(balls: int) -> void:
	_balls_label.text = str(balls)


func refresh_next(turn: int, type: Game.TaxType, amount: int) -> void:
	_next_turn_label.text = str(turn)
	if type == Game.TaxType.MONEY:
		_next_money_label.text = str(amount)
		_next_balls_label.text = ""
	else:
		_next_money_label.text = ""
		_next_balls_label.text = str(amount)


func refresh_next_clear() -> void:
	_next_turn_label.text = "CLEAR!!"
	_next_money_label.text = "CLEAR!!"
	_next_balls_label.text = "CLEAR!!"


func add_log(text: String) -> void:
	_log_lines.push_back(text)
	if LOG_LINES_MAX < _log_lines.size():
		_log_lines.pop_front()

	_log_label.clear()
	_log_label.text = "\n".join(_log_lines)


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
		_ball_popup_rarity.self_modulate = ColorData.BALL_RARITY_COLORS[ball.rarity]
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

func _refresh_slots(parent_node: Control, min: int, max: int) -> void:
	var index = 0
	for node in parent_node.get_children():
		if node is TextureRect:
			if index < min:
				node.self_modulate = ColorData.PRIMARY
			elif max <= index:
				node.self_modulate = ColorData.SECONDARY
			else:
				node.self_modulate = ColorData.GRAY_40
			index += 1


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
