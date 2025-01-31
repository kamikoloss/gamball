class_name Product
extends Control

# ホバーしたとき
signal hovered # (Product, <bool>)
# クリックしたとき
signal pressed # (Product)


enum ProductType {
	DECK_PACK,
	DECK_CLEANER,
	EXTRA_PACK,
	EXTRA_CLEANER,
}


const PRODUCT_PRICES = {
	ProductType.DECK_PACK: 200,
	ProductType.DECK_CLEANER: 100,
	ProductType.EXTRA_PACK: 200,
	ProductType.EXTRA_CLEANER: 100,
}

# 商品の [<名称>, <説明分>]
# TODO: JSON に逃がす
const PRODUCT_DATA = {
	ProductType.DECK_PACK: ["DECK Pack", "DECK にランダムな\nボール x2 を追加する"],
	ProductType.DECK_CLEANER: ["DECK Cleaner", "DECK から最も低い No. の\nボール x1 を削除する"],
	ProductType.EXTRA_PACK: ["EXTRA Pack", "EXTRA にランダムな\nボール x2 を追加する"],
	ProductType.EXTRA_CLEANER: ["EXTRA Cleaner", "EXTRA から最も低い No. の\nボール x1を削除する"],
}


@export var product_type: ProductType = ProductType.DECK_PACK

# UI
@export var _icon_texture: TextureRect
@export var _name_label: Label
@export var _price_label: Label
@export var _buy_button: Button

# Resources
@export var _icon_pack: Texture
@export var _icon_cleaner: Texture


# 価格
var price: int:
	get:
		return PRODUCT_PRICES[product_type]
# 名前
var title: String:
	get:
		return PRODUCT_DATA[product_type][0]
# 説明文
var description: String:
	get:
		return PRODUCT_DATA[product_type][1]


# 購入可能かどうか
var _enabled: bool = false
# アイコン画像にカーソルが載っているか
var _is_icon_hovered: bool = false


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_buy_button.pressed.connect(_on_buy_button_pressed)

	refresh_view()


func enable() -> void:
	_enabled = true

func disable() -> void:
	_enabled = false


# 自身の見た目を更新する
func refresh_view() -> void:
	# アイコン
	match product_type:
		ProductType.DECK_PACK:
			_icon_texture.texture = _icon_pack
		ProductType.DECK_CLEANER:
			_icon_texture.texture = _icon_cleaner
		ProductType.EXTRA_PACK:
			_icon_texture.texture = _icon_pack
		ProductType.EXTRA_CLEANER:
			_icon_texture.texture = _icon_cleaner

	# テキスト
	_name_label.text = title
	_price_label.text = "＄%s" % str(price)

	# 購入ボタン
	_buy_button.visible = _is_icon_hovered
	if _enabled:
		_buy_button.self_modulate = ColorPalette.SUCCESS
		_buy_button.text = "Buy"
	else:
		_buy_button.self_modulate = ColorPalette.DANGER
		_buy_button.text = "----"


func _on_mouse_entered() -> void:
	_is_icon_hovered = true
	refresh_view()
	hovered.emit(self, _is_icon_hovered)

func _on_mouse_exited() -> void:
	_is_icon_hovered = false
	refresh_view()
	hovered.emit(self, _is_icon_hovered)


func _on_buy_button_pressed(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit(self)
