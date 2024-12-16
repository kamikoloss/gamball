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

# DECK/EXTRA Slot の背景色
const BALL_SLOT_COLOR_REQUIRED: Color = Color(0.2, 0.6, 0.2) # 必須 (min より下)
const BALL_SLOT_COLOR_OPTIONAL: Color = Color(0.6, 0.6, 0.6) # 任意 (min と max の間)
const BALL_SLOT_COLOR_DISABLED: Color = Color(0.6, 0.2, 0.2) # 不可 (max より上)

const BALL_POPUP_POSITION_DIFF: Vector2 = Vector2(0, 40)


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
@export_category("Main/DragPoint")
@export var _drag_point: Control
@export_category("Main/Arrow")
@export var _arrow: Control
@export var _arrow_square: TextureRect

@export_category("Tax")
@export var _tax_window: Control
@export var _tax_pay_button: Button
@export var _tax_give_up_button: Button

@export_category("Shop")
@export var _shop_window: Control
@export var _shop_exit_button: Button

@export_category("People")
@export var _people_window: Control


var _tweens: Dictionary = {}


func _ready() -> void:
	# Main/Ball
	for node in _deck_balls_parent.get_children():
		if node is Ball:
			node.hovered.connect(func(entered): _show_ball_popup(node) if entered else _hide_ball_popup())
	for node in _extra_balls_parent.get_children():
		if node is Ball:
			node.hovered.connect(func(entered): _show_ball_popup(node) if entered else _hide_ball_popup())
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

	# Main/DragPoint
	hide_drag_point()

	# Main/Arrow
	hide_arrow()


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


# Main/DragPoint
func show_drag_point(position: Vector2) -> void:
	_drag_point.visible = true
	_drag_point.position = position

func hide_drag_point() -> void:
	_drag_point.visible = false


# Main/Arrow
func show_arrow() -> void:
	_arrow.visible = true

func hide_arrow() -> void:
	_arrow.visible = false
	_arrow_square.scale.y = 0
	_drag_point.visible = false

func refresh_arrow(deg: int, scale: float) -> void:
	_arrow.rotation_degrees = deg
	_arrow_square.scale.y = scale


func _show_ball_popup(ball: Ball) -> void:
	#print("[GameUi] _show_ball_popup(%s)" % [ball])
	_ball_popup.visible = true
	_ball_popup.position = ball.global_position + BALL_POPUP_POSITION_DIFF
	if ball.level < 0:
		_ball_popup_level.text = "-"
		_ball_popup_rarity.text = ""
		_ball_popup_rarity.self_modulate = Color.WHITE
	else:
		_ball_popup_level.text = str(ball.level)
		_ball_popup_rarity.text = BallEffect.RARITY_TEXT[ball.rarity]
		_ball_popup_rarity.self_modulate = Ball.BALL_RARITY_COLORS[ball.rarity]
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
				node.self_modulate = BALL_SLOT_COLOR_REQUIRED
			elif max <= index:
				node.self_modulate = BALL_SLOT_COLOR_DISABLED
			else:
				node.self_modulate = BALL_SLOT_COLOR_OPTIONAL
			index += 1


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
