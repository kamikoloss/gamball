class_name Product
extends Control


signal hovered # (self, on: bool)
signal pressed # (self)


enum Type {
	TAX,
	DECK_PACK,
	DECK_CLEANER,
	EXTRA_PACK,
	EXTRA_CLEANER,
}


# 初期価格
const PRODUCT_PRICES := {
	Type.DECK_PACK: 100,
	Type.DECK_CLEANER: 50,
	Type.EXTRA_PACK: 100,
	Type.EXTRA_CLEANER: 50,
}


# UI
@export var _icon_texture: TextureRect
@export var _name_label: Label
@export var _price_label: Label
@export var _buy_button: Button

# Resources
@export var _icon_pack: Texture
@export var _icon_cleaner: Texture


# 種類
var type := Type.DECK_PACK:
	set(v):
		type = v
		title = tr("product_%s_title" % [Type.keys()[type]])
		description = tr("product_%s_desc" % [Type.keys()[type]])
# 価格
var price := 0
# 名前
var title := ""
# 説明文
var description := ""
# 購入可能かどうか
var disabled := false:
	set(v):
		disabled = v
		_refresh_view()


# 現在ホバーしているかどうか
var _hovered := false:
	set(v):
		_hovered = v
		_refresh_view()
		hovered.emit(self, _hovered)


func _ready() -> void:
	mouse_entered.connect(func(): _hovered = true)
	mouse_exited.connect(func(): _hovered = false)
	_buy_button.pressed.connect(func(): pressed.emit(self))
	
	_refresh_view()


# 価格を設定する
func set_price(rate: float = 1.0) -> void:
	if not PRODUCT_PRICES.has(type):
		return
	price = int(PRODUCT_PRICES[type] * rate)
	_refresh_view()


# 自身の見た目を更新する
func _refresh_view() -> void:
	# アイコン
	match type:
		Type.DECK_PACK:
			_icon_texture.texture = _icon_pack
		Type.DECK_CLEANER:
			_icon_texture.texture = _icon_cleaner
		Type.EXTRA_PACK:
			_icon_texture.texture = _icon_pack
		Type.EXTRA_CLEANER:
			_icon_texture.texture = _icon_cleaner

	# テキスト
	_name_label.text = title
	_price_label.text = "● %s" % str(price)

	# 購入ボタン
	_buy_button.visible = _hovered
	if disabled:
		_buy_button.self_modulate = ColorPalette.GRAY_40
		_buy_button.text = "----"
	else:
		_buy_button.self_modulate = ColorPalette.PRIMARY
		_buy_button.text = "Buy"
