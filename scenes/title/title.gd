class_name Title
extends Control


signal play_button_pressed
signal options_button_pressed
signal information_button_pressed
signal exit_button_pressed


enum TweenType { BUTTON, BUNNY }


const BUTTON_MOVE_DURATION := 0.4
const BUTTON_MOVE_DIFF := Vector2(640, 0)
const BUNNY_MOVE_DURATION := 4.0
const BUNNY_MOVE_DIFF := Vector2(0, 320)


@export var _play_button: TitleButton
@export var _information_button: TitleButton
@export var _options_button: TitleButton
@export var _exit_button: TitleButton

@export var _bunny_texture: TextureRect


var _tweens := {}


func _ready() -> void:
	_play_button.pressed.connect(func():play_button_pressed.emit())
	_information_button.pressed.connect(func(): information_button_pressed.emit())
	_options_button.pressed.connect(func(): options_button_pressed.emit())
	_exit_button.pressed.connect(func(): exit_button_pressed.emit())

	_show_buttons()
	_show_bunny()


func _show_buttons() -> void:
	_play_button.position = _play_button.position - BUTTON_MOVE_DIFF
	_options_button.position = _options_button.position - BUTTON_MOVE_DIFF
	_information_button.position = _information_button.position - BUTTON_MOVE_DIFF
	_exit_button.position = _exit_button.position - BUTTON_MOVE_DIFF

	var tween = _get_tween(TweenType.BUTTON)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(_play_button, "position", _play_button.position + BUTTON_MOVE_DIFF, BUTTON_MOVE_DURATION)
	tween.tween_property(_information_button, "position", _information_button.position + BUTTON_MOVE_DIFF, BUTTON_MOVE_DURATION)
	tween.tween_property(_options_button, "position", _options_button.position + BUTTON_MOVE_DIFF, BUTTON_MOVE_DURATION)
	tween.tween_property(_exit_button, "position", _exit_button.position + BUTTON_MOVE_DIFF, BUTTON_MOVE_DURATION)


func _show_bunny() -> void:
	_bunny_texture.modulate = Color.TRANSPARENT
	_bunny_texture.position = _bunny_texture.position - BUNNY_MOVE_DIFF

	var tween = _get_tween(TweenType.BUNNY)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(_bunny_texture, "modulate", Color.WHITE, BUNNY_MOVE_DURATION)
	tween.tween_property(_bunny_texture, "position", _bunny_texture.position + BUNNY_MOVE_DIFF, BUNNY_MOVE_DURATION)


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
