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

@export_category("Game")
@export var _restart_game_button: Button
@export var _turn_plus_button: Button
@export var _turn_minus_button: Button
@export var _money_plus_button: Button
@export var _money_minus_button: Button
@export var _balls_plus_button: Button
@export var _balls_minus_button: Button
@export_category("Pachinko")
@export var _pachinko_start_lottery_button: Button
@export var _pachinko_start_rush_button: Button
@export var _pachinko_finish_rush_button: Button
@export_category("Window")
@export var _show_tax_button: Button
@export var _hide_tax_button: Button
@export var _show_shop_button: Button
@export var _hide_shop_button: Button
@export_category("People")
@export var _show_people_button: Button
@export var _hide_people_button: Button
@export var _refresh_dialogue_button: Button
@export var _refresh_dialogue_big_button: Button
@export var _shuffle_pose_button: Button


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

	_restart_game_button.pressed.connect(func(): _game.restart_game())
	_turn_plus_button.pressed.connect(func(): _game.turn += 10)
	_turn_minus_button.pressed.connect(func(): _game.turn -= 10)
	_money_plus_button.pressed.connect(func(): _game.money += 100)
	_money_minus_button.pressed.connect(func(): _game.money -= 100)
	_balls_plus_button.pressed.connect(func(): _game.balls += 100)
	_balls_minus_button.pressed.connect(func(): _game.balls -= 100)

	_pachinko_start_lottery_button.pressed.connect(func(): _pachinko.start_lottery())
	_pachinko_start_rush_button.pressed.connect(func(): _pachinko._start_rush())
	_pachinko_finish_rush_button.pressed.connect(func(): _pachinko._finish_rush())

	_show_tax_button.pressed.connect(func(): _game_ui.show_tax_window())
	_hide_tax_button.pressed.connect(func(): _game_ui.hide_tax_window())
	_show_shop_button.pressed.connect(func(): _game_ui.show_shop_window())
	_hide_shop_button.pressed.connect(func(): _game_ui.hide_shop_window())

	_show_people_button.pressed.connect(func(): _game_ui.show_people_window())
	_hide_people_button.pressed.connect(func(): _game_ui.hide_people_window())
	_refresh_dialogue_button.pressed.connect(func(): _game_ui.refresh_dialogue_label(_sample_dialogue_list.pick_random()))
	_refresh_dialogue_big_button.pressed.connect(func(): _game_ui.refresh_dialogue_big_label(_sample_dialogue_big_list.pick_random()))
	_shuffle_pose_button.pressed.connect(func(): _bunny.shuffle_pose())
