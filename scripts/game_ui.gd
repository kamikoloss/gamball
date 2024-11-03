class_name GameUi
extends Control


signal buy_balls_button_pressed
signal sell_balls_button_pressed
signal tax_pay_button_pressed
signal shop_exit_button_pressed
signal info_button_pressed


const WINDOW_POSITION_BOTTOM_FROM: Vector2 = Vector2(0, 720)
const WINDOW_POSITION_BOTTOM_TO: Vector2 = Vector2(0, -720)
const WINDOW_POSITION_RIGHT_FROM: Vector2 = Vector2(1280, 0)
const WINDOW_POSITION_RIGHT_TO: Vector2 = Vector2(720, 0)
const WINDOW_POSITION_TO: Vector2 = Vector2(0, 0)
const WINDOW_MOVE_DURATION: float = 1.0

@export_category("Main/BallsSlotXxxx")
@export var _balls_slot_deck: Control
@export var _balls_slot_extra: Control
@export_category("Main/Buttons")
@export var _buy_balls_button: Button
@export var _sell_balls_button: Button
@export var _info_button: Button
@export_category("Main/Score")
@export var _turn_label: Label
@export var _money_label: Label
@export var _payout_label: Label
@export var _balls_label: Label
@export var _next_turn_label: Label
@export var _next_type_label: Label
@export var _next_amount_label: Label
@export_category("Main/DragPoint")
@export var _drag_point: Control
@export_category("Main/Arrow")
@export var _arrow: Control
@export var _arrow_square: TextureRect

@export_category("Tax")
@export var _tax_window: Control
@export var _tax_pay_button: TextureButton
@export var _tax_give_up_button: TextureButton

@export_category("Shop")
@export var _shop_window: Control
@export var _shop_exit_button: TextureButton

@export_category("People")
@export var _people_window: Control


func _ready() -> void:
	# Main/Buttons
	_buy_balls_button.pressed.connect(func(): buy_balls_button_pressed.emit())
	_sell_balls_button.pressed.connect(func(): sell_balls_button_pressed.emit())
	_tax_pay_button.pressed.connect(func(): tax_pay_button_pressed.emit())
	_shop_exit_button.pressed.connect(func(): shop_exit_button_pressed.emit())
	_info_button.pressed.connect(func(): info_button_pressed.emit())
	# Main/DragPoint
	hide_drag_point()
	# Main/Arrow
	hide_arrow()


func show_drag_point(position: Vector2) -> void:
	_drag_point.visible = true
	_drag_point.position = position

func hide_drag_point() -> void:
	_drag_point.visible = false


func show_arrow() -> void:
	_arrow.visible = true

func hide_arrow() -> void:
	_arrow.visible = false
	_arrow_square.scale.y = 0
	_drag_point.visible = false

func refresh_arrow(deg: int, scale: float) -> void:
	_arrow.rotation_degrees = deg
	_arrow_square.scale.y = scale


func show_tax_window() -> void:
	show_people_window() # 連動
	_tax_window.visible = true
	_tax_window.position = WINDOW_POSITION_BOTTOM_FROM
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_tax_window, "position", WINDOW_POSITION_TO, WINDOW_MOVE_DURATION)

func hide_tax_window() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_tax_window, "position", WINDOW_POSITION_BOTTOM_TO, WINDOW_MOVE_DURATION)


func show_shop_window() -> void:
	_shop_window.visible = true
	_shop_window.position = WINDOW_POSITION_BOTTOM_FROM
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_shop_window, "position", WINDOW_POSITION_TO, WINDOW_MOVE_DURATION)

func hide_shop_window() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_shop_window, "position", WINDOW_POSITION_BOTTOM_TO, WINDOW_MOVE_DURATION)
	hide_people_window() # 連動


func show_people_window() -> void:
	_people_window.visible = true
	_people_window.position = WINDOW_POSITION_RIGHT_FROM
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_people_window, "position", WINDOW_POSITION_TO, WINDOW_MOVE_DURATION)

func hide_people_window() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_people_window, "position", WINDOW_POSITION_RIGHT_TO, WINDOW_MOVE_DURATION)


func refresh_balls_slot_deck(deck_level_list: Array[int]) -> void:
	_refresh_balls_slot(_balls_slot_deck, deck_level_list)

func refresh_balls_slot_extra(extra_level_list: Array[int]) -> void:
	_refresh_balls_slot(_balls_slot_extra, extra_level_list)


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
	_next_type_label.text = "￥" if type == Game.TaxType.Money else "●"
	_next_amount_label.text = str(amount)

func refresh_next_clear() -> void:
	_next_turn_label.text = ""
	_next_type_label.text = ""
	_next_amount_label.text = "CLEAR!!"


func _refresh_balls_slot(parent_node: Node, level_list: Array[int]) -> void:
	var index = 0
	for node in parent_node.get_children():
		if node is Ball: # Label もある
			if index < level_list.size():
				node.level = level_list[index]
			else:
				node.level = Ball.BALL_LEVEL_EMPTY_SLOT
			node.refresh_view()
			index += 1
