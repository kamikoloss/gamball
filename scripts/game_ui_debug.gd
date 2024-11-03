class_name GameUiDebug
extends Control


@export var _debug_button: Button
@export var _debug_window: Control

@export var _game: Game
@export var _game_ui: GameUi
@export var _bunny: Bunny

@export var _restart_game_button: Button
@export var _turn_add_button: Button
@export var _money_add_button: Button
@export var _balls_add_button: Button
@export var _show_tax_button: Button
@export var _hide_tax_button: Button
@export var _show_shop_button: Button
@export var _hide_shop_button: Button
@export var _show_people_button: Button
@export var _hide_people_button: Button
@export var _refresh_people_dialogue_button: Button
@export var _shuffle_people_pose_button: Button


var _dialogue_sample_list = [
	"セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。(030+04)",
	"セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。(060+04)",
	"セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。(090+04)",
	"セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。セリフサンプルだよ。(120+04)",
]


func _ready() -> void:
	_debug_window.visible = false

	_restart_game_button.pressed.connect(func(): _game.restart_game())
	_turn_add_button.pressed.connect(func(): _game.turn += 20)
	_money_add_button.pressed.connect(func(): _game.money += 100)
	_balls_add_button.pressed.connect(func(): _game.balls += 100)
	_debug_button.pressed.connect(func(): _debug_window.visible = not _debug_window.visible)
	_show_tax_button.pressed.connect(func(): _game_ui.show_tax_window())
	_hide_tax_button.pressed.connect(func(): _game_ui.hide_tax_window())
	_show_shop_button.pressed.connect(func(): _game_ui.show_shop_window())
	_hide_shop_button.pressed.connect(func(): _game_ui.hide_shop_window())
	_show_people_button.pressed.connect(func(): _game_ui.show_people_window())
	_hide_people_button.pressed.connect(func(): _game_ui.hide_people_window())
	_refresh_people_dialogue_button.pressed.connect(func(): _game_ui.refresh_dialogue_label(_dialogue_sample_list.pick_random()))
	_shuffle_people_pose_button.pressed.connect(func(): _bunny.shuffle_pose())
