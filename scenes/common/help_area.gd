class_name HelpArea
extends Control


# ホバーしたとき
signal hovered # (self, <bool>)
# クリックしたとき
#signal pressed # (self)


const SHOW_DURATION := 0.2


@export var title: String
@export var title_sub: String
@export_multiline var description: String
@export var related_object: Node


@export var _panel: Panel


# 現在ホバーしているかどうか
var _hovered := false:
	set(v):
		_hovered = v
		_refresh_view()
		print("help area hovered")
		hovered.emit(self, _hovered)
var _tween: Tween:
	get():
		if _tween:
			_tween.kill()
		return create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)


func _ready() -> void:
	mouse_entered.connect(func(): _hovered = true)
	mouse_exited.connect(func(): _hovered = false)
	_refresh_view()


func _refresh_view() -> void:
	if _hovered:
		_tween.tween_property(_panel, "modulate", Color.TRANSPARENT, SHOW_DURATION)
	else:
		_tween.tween_property(_panel, "modulate", Color.WHITE, SHOW_DURATION)
