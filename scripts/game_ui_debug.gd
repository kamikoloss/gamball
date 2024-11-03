class_name GameUiDebug
extends Control


@export var _debug_button: Button
@export var _debug_window: Control

@export var _game: Game
@export var _game_ui: GameUi

@export var _show_tax_button: Button
@export var _hide_tax_button: Button
@export var _show_shop_button: Button
@export var _hide_shop_button: Button
@export var _show_people_button: Button
@export var _hide_people_button: Button
@export var _refresh_people_dialogue_button: Button


var _dialogue_sample = [
	"そのころわたくしは、モリーオ市の博物局に勤めて居りました。",
	"十八等官でしたから役所のなかでも、ずうっと下の方でしたし俸給もほんのわずかでしたが、受持ちが標本の採集や整理で生れ付き好きなことでしたから、わたくしは毎日ずいぶん愉快にはたらきました。",
	"あのイーハトーヴォのすきとおった風、夏でも底に冷たさをもつ青いそら、うつくしい森で飾られたモリーオ市、郊外のぎらぎらひかる草の波。",
	"では、わたくしはいつかの小さなみだしをつけながら、しずかにあの年のイーハトーヴォの五月から十月までを書きつけましょう。",
]


func _ready() -> void:
	_debug_window.visible = false

	_debug_button.pressed.connect(func(): _debug_window.visible = not _debug_window.visible)
	_show_tax_button.pressed.connect(func(): _game_ui.show_tax_window())
	_hide_tax_button.pressed.connect(func(): _game_ui.hide_tax_window())
	_show_shop_button.pressed.connect(func(): _game_ui.show_shop_window())
	_hide_shop_button.pressed.connect(func(): _game_ui.hide_shop_window())
	_show_people_button.pressed.connect(func(): _game_ui.show_people_window())
	_hide_people_button.pressed.connect(func(): _game_ui.hide_people_window())
	_refresh_people_dialogue_button.pressed.connect(func(): _game_ui.refresh_dialogue_label(_dialogue_sample.pick_random()))
