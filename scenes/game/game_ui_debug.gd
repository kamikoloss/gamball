class_name GameUiDebug
extends Control


@export var _enable: bool = false

@export_category("Nodes")
@export var _game: Game
@export var _billards: Billiards
@export var _pachinko: Pachinko
@export var _stack: Stack
@export var _game_ui: GameUi
@export var _bunny: Bunny

@export_category("Debug")
@export var _debug_button: Button
@export var _debug_window: Control
@export var _main_buttons_parent: Control
@export var _balls_parent: Node2D
@export var _balls_buttons_parent: Control
@export var _main_labels_parent: Control


# { <ボタン文字列: string>: <ボタン処理: Callable>, ... } 
var _main_functions: Dictionary = {
	# Game
	"TURN +10": func(): _game.turn += 10,
	"TURN -10": func(): _game.turn -= 10,
	"MONEY +100": func(): _game.money += 100,
	"MONEY -100": func(): _game.money -= 100,
	"BALLS +100": func(): _game.balls += 100,
	"BALLS -100": func(): _game.balls -= 100,
	"PAYOUT +100": func(): _game._push_payout(0, 100),
	"payout speed x1": func(): _game._start_payout(1.0),
	"payout speed x2": func(): _game._start_payout(2.0),
	"payout speed x3": func(): _game._start_payout(3.0),
	"payout speed x4": func(): _game._start_payout(4.0),
	# Pachinko
	"start_lottery": func(): _pachinko.start_lottery(true),
	"_start_rush": func(): _pachinko._start_rush(),
	"_finish_rush": func(): _pachinko._finish_rush(true),
	# GameUi
	"show_tax_window": func(): _game_ui.show_tax_window(),
	"hide_tax_window": func(): _game_ui.hide_tax_window(),
	"show_shop_window": func(): _game_ui.show_shop_window(),
	"hide_shop_window": func(): _game_ui.hide_shop_window(),
	"show_people_window": func(): _game_ui.show_people_window(),
	"hide_people_window": func(): _game_ui.hide_people_window(),
	"refresh_dialogue_label": func(): _bunny.refresh_dialogue_label(_sample_dialogue_list.pick_random()),
	"shuffle_pose": func(): _bunny.shuffle_pose(),
}
# { <ボタン文字列: string>: <ボタン処理: Callable>, ... } 
var _balls_functions: Dictionary = {
	"Lv.1": func(): _on_balls_rarity_pressed(Ball.Rarity.COMMON),
	"Lv.2": func(): _on_balls_rarity_pressed(Ball.Rarity.UNCOMMON),
	"Lv.3": func(): _on_balls_rarity_pressed(Ball.Rarity.RARE),
	"Lv.4": func(): _on_balls_rarity_pressed(Ball.Rarity.EPIC),
	"Lv.5": func(): _on_balls_rarity_pressed(Ball.Rarity.LEGENDARY),
	"DECK+": func(): _on_balls_deck_pressed(true),
	"DECK-": func(): _on_balls_deck_pressed(false),
	"EXTRA+": func(): _on_balls_extra_pressed(true),
	"EXTRA-": func(): _on_balls_extra_pressed(false),
}
# { <ラベル文字列 Key: string>: <ラベル文字列 Value: Callable>, ... }
var _main_texts: Dictionary = {
	"GameState": func(): return Game.GameState.keys()[_game.game_state],
}

var _sample_dialogue_list = [
	"セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。(030+04)",
	"セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。(060+04)",
	"セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。(090+04)",
	"セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。(120+04)",
]
var _sample_dialogue_big_list = [
	"セリフサンプルだよ～！",
	"セリフサンプルだよ～！\nセリフサンプルだよ～！",
]

var _current_ball_level: int = 0
var _current_ball_rarity: Ball.Rarity = Ball.Rarity.COMMON


func _ready() -> void:
	_debug_window.visible = false
	_debug_button.visible = false

	if not _enable:
		return

	_debug_button.visible = true
	_debug_button.pressed.connect(func(): _debug_window.visible = not _debug_window.visible)

	# MainButtons
	var main_buttons_index = 0
	var main_buttons = _main_buttons_parent.get_children()
	for key in _main_functions.keys():
		main_buttons[main_buttons_index].text = key
		main_buttons[main_buttons_index].pressed.connect(_main_functions[key])
		main_buttons_index += 1

	# BallButtons
	var balls_buttons_index = 0
	var balls_buttons = _balls_buttons_parent.get_children()
	for key in _balls_functions.keys():
		balls_buttons[balls_buttons_index].text = key
		balls_buttons[balls_buttons_index].pressed.connect(_balls_functions[key])
		balls_buttons_index += 1
	var ball_level = 0
	for ball: Ball in _balls_parent.get_children():
		ball.level = ball_level
		ball.refresh_view()
		ball.pressed.connect(func(): _on_ball_pressed(ball))
		ball_level += 1

	# MainLabels
	var labels_tween = create_tween()
	labels_tween.set_loops()
	labels_tween.tween_interval(0.25)
	labels_tween.tween_callback(_refresh_labels)


func _on_ball_pressed(ball: Ball) -> void:
	_current_ball_level = ball.level
	for b: Ball in _balls_parent.get_children():
		b.hide_hover()
	ball.show_hover()

func _on_balls_rarity_pressed(rarity: Ball.Rarity) -> void:
	_current_ball_rarity = rarity
	for ball: Ball in _balls_parent.get_children():
		ball.rarity = rarity
		ball.refresh_view()

func _on_balls_deck_pressed(add: bool) -> void:
	if add:
		_game._deck_ball_list.push_back(Ball.new(_current_ball_level, _current_ball_rarity))
	else:
		_game._deck_ball_list.pop_front()
	_game._apply_extra_ball_effects()
	_game._refresh_deck()

func _on_balls_extra_pressed(add: bool) -> void:
	if add:
		_game._extra_ball_list.push_back(Ball.new(_current_ball_level, _current_ball_rarity))
	else:
		_game._extra_ball_list.pop_front()
	_game._apply_extra_ball_effects()
	_game._refresh_deck_extra()
	_game._refresh_next()


func _refresh_labels() -> void:
	var index = 0
	var main_labels = _main_labels_parent.get_children()
	for key in _main_texts.keys():
		var main_label: Label = main_labels[index]
		main_labels[index].text = "%s: %s" % [key, _main_texts[key].call()]
