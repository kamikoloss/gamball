class_name GameUiDebug
extends Control


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
@export var _debug_buttons_parent: Control

@export_category("Balls")
@export var _balls_parent: Node2D
@export var _balls_lv1_button: Button
@export var _balls_lv2_button: Button
@export var _balls_lv3_button: Button
@export var _balls_lv4_button: Button
@export var _balls_lv5_button: Button
@export var _balls_deck_add_button: Button
@export var _balls_deck_remove_button: Button
@export var _balls_extra_add_button: Button
@export var _balls_extra_remove_button: Button


@export_category("Labels")
@export var _game_state_label: Label


# { <ラベル名>: <Callable>, ... } 
var _debug_functions: Dictionary = {
	"restart_game": func(): _game.restart_game(),
	"TURN +10": func(): _game.turn += 10,
	"TURN -10": func(): _game.turn -= 10,
	"MONEY +100": func(): _game.money += 100,
	"MONEY -100": func(): _game.money -= 100,
	"BALLS +100": func(): _game.balls += 100,
	"BALLS -100": func(): _game.balls -= 100,
	"start_lottery": func(): _pachinko.start_lottery(true),
	"_start_rush": func(): _pachinko._start_rush(),
	"_finish_rush": func(): _pachinko._finish_rush(true),
	"show_tax_window": func(): _game_ui.show_tax_window(),
	"hide_tax_window": func(): _game_ui.hide_tax_window(),
	"show_shop_window": func(): _game_ui.show_shop_window(),
	"hide_shop_window": func(): _game_ui.hide_shop_window(),
	"show_people_window": func(): _game_ui.show_people_window(),
	"hide_people_window": func(): _game_ui.hide_people_window(),
	"refresh_dialogue_label": func(): _bunny.refresh_dialogue_label(_sample_dialogue_list.pick_random()),
	"shuffle_pose": func(): _bunny.shuffle_pose(),
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
	_debug_button.pressed.connect(func(): _debug_window.visible = not _debug_window.visible)

	var index = 0
	var debug_buttons = _debug_buttons_parent.get_children()
	for key in _debug_functions.keys():
		var debug_button: Button = debug_buttons[index]
		var debug_function: Callable = _debug_functions[key]
		debug_button.text = key
		debug_button.pressed.connect(debug_function)
		index += 1


func _process(delta: float) -> void:
	_game_state_label.text = "State: %s" % [Game.GameState.keys()[_game.game_state]]
