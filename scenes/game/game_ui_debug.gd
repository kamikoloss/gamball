class_name GameUiDebug
extends Control


@export var _enable := false

@export_category("Nodes")
@export var _game: Game
@export var _billards: Billiards
@export var _pachinko: Pachinko
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
	"TURN +10": func(): _game._turn += 10,
	"TURN -10": func(): _game._turn -= 10,
	"BALLS +10": func(): _game._increase_balls(10),
	"BALLS +100": func(): _game._increase_balls(100),
	"BALLS -10": func(): _game._increase_balls(-10),
	"BALLS -100": func(): _game._increase_balls(-100),
	# Pachinko
	"start_lottery": func(): _pachinko.start_lottery(true),
	"_start_rush": func(): _pachinko._start_rush(),
	"_finish_rush": func(): _pachinko._finish_rush(true),
	# GameUi
	"show_tax_window": func(): _game_ui.show_tax_window(),
	"hide_tax_window": func(): _game_ui.hide_tax_window(),
	"show_shop_window": func(): _game_ui.show_shop_window(),
	"hide_shop_window": func(): _game_ui.hide_shop_window(),
	"set_dialogue": func(): _game_ui.set_dialogue(_sample_dialogue_list.pick_random()),
	"bubble Bottom": func(): _game_ui.change_target_bubble(true),
	"bubble Top": func(): _game_ui.change_target_bubble(false),
	"bunny Large": func(): _game_ui.change_bunny_size(true),
	"bunny Small": func(): _game_ui.change_bunny_size(false),
	"bunny shuffle_pose": func(): _bunny.shuffle_pose(),
	"bunny jump": func(): _bunny.jump(),
}
# { <ボタン文字列: string>: <ボタン処理: Callable>, ... } 
var _balls_functions: Dictionary = {
	"Lv.1": func(): _on_balls_rarity_pressed(Rarity.Type.COMMON),
	"Lv.2": func(): _on_balls_rarity_pressed(Rarity.Type.UNCOMMON),
	"Lv.3": func(): _on_balls_rarity_pressed(Rarity.Type.RARE),
	"Lv.4": func(): _on_balls_rarity_pressed(Rarity.Type.EPIC),
	"Lv.5": func(): _on_balls_rarity_pressed(Rarity.Type.LEGENDARY),
	"DECK-": func(): _on_balls_remove_pressed(false),
	"EXTRA-": func(): _on_balls_remove_pressed(true),
}
# { <ラベル文字列 Key: string>: <ラベル文字列 Value: Callable>, ... }
var _main_texts: Dictionary = {
	"GameState": func(): return Game.GameState.keys()[_game._game_state],
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
	var ball_number = 0
	for ball: Ball in _balls_parent.get_children():
		ball.number = ball_number
		ball.refresh_view()
		ball_number += 1

	# MainLabels
	var labels_tween = create_tween()
	labels_tween.set_loops()
	labels_tween.tween_interval(0.25)
	labels_tween.tween_callback(_refresh_labels)


# TODO: HelpArea 対応
func _on_ball_pressed(ball: Ball) -> void:
	_game._extra_ball_list.push_back(Ball.new(ball.number, ball.rarity))
	_game._apply_extra_ball_effects()
	_game._refresh_deck_extra()
	_game._refresh_next()

func _on_balls_rarity_pressed(rarity: Rarity.Type) -> void:
	for ball: Ball in _balls_parent.get_children():
		ball.rarity = rarity
		ball.refresh_view()

func _on_balls_remove_pressed(is_extra: bool) -> void:
	if is_extra:
		_game._extra_ball_list.pop_front()
	else:
		_game._deck_ball_list.pop_front()
	_game._apply_extra_ball_effects()
	_game._refresh_deck_extra()
	_game._refresh_next()


func _refresh_labels() -> void:
	var index = 0
	var main_labels = _main_labels_parent.get_children()
	for key in _main_texts.keys():
		var main_label: Label = main_labels[index]
		main_labels[index].text = "%s: %s" % [key, _main_texts[key].call()]
