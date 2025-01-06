class_name Product
extends Control


# アイコンがクリックされたとき (Product)
signal icon_pressed


enum ProductType {
	DECK_PACK,
	DECK_CLEANER,
	EXTRA_PACK,
	EXTRA_CLEANER,
}


const PRODUCT_PRICES = {
	ProductType.DECK_PACK: 100,
	ProductType.DECK_CLEANER: 50,
	ProductType.EXTRA_PACK: 200,
	ProductType.EXTRA_CLEANER: 100,
}

const BUY_COLOR_ACTIVE = Color(0.2, 0.6, 0.2)
const BUY_COLOR_DEACTIVE = Color(0.6, 0.2, 0.2)


# 商品の [<名称>, <説明分>]
# TODO: JSON に逃がす
const PRODUCT_DATA = {
	ProductType.DECK_PACK: ["DECK Pack", "Add random BALL x3\nto DECK"],
	ProductType.DECK_CLEANER: ["DECK Cleaner", "Remove the lowest\nBALL from DECK"],
	ProductType.EXTRA_PACK: ["EXTRA Pack", "Add random BALL x2\nto EXTRA"],
	ProductType.EXTRA_CLEANER: ["EXTRA Cleaner", "Remove the lowest\nBALL from EXTRA"],
}


@export var product_type: ProductType = ProductType.DECK_PACK

# UI
@export var _icon_texture: TextureRect
@export var _name_label: Label
@export var _desc_label: Label
@export var _price_label: Label
@export var _buy_texture: TextureRect
@export var _buy_label: Label

# Resources
@export var _icon_pack: Texture
@export var _icon_cleaner: Texture


# 価格
var price: int:
	get:
		return PRODUCT_PRICES[product_type]
# 所持金
# TODO: ここで持つのか？変な気がする
var main_money: int = 0:
	set (value):
		main_money = value
		refresh_view()


# アイコン画像にカーソルが載っているか
var _is_icon_hovered: bool = false


func _ready() -> void:
	_icon_texture.gui_input.connect(_on_icon_input)
	_icon_texture.mouse_entered.connect(_on_icon_mouse_entered)
	_icon_texture.mouse_exited.connect(_on_icon_mouse_exited)
	refresh_view()


# 自身の見た目を更新する
func refresh_view() -> void:
	if not product_type in ProductType.values():
		print("[Product] ERROR: invalid product type")

	match product_type:
		ProductType.DECK_PACK:
			_icon_texture.texture = _icon_pack
		ProductType.DECK_CLEANER:
			_icon_texture.texture = _icon_cleaner
		ProductType.EXTRA_PACK:
			_icon_texture.texture = _icon_pack
		ProductType.EXTRA_CLEANER:
			_icon_texture.texture = _icon_cleaner

	_name_label.text = PRODUCT_DATA[product_type][0]
	_desc_label.text = PRODUCT_DATA[product_type][1]
	_price_label.text = "＄%s" % str(price)

	# 購入ボタン
	# TODO: 買えないときは Deacive な色にする
	if _is_icon_hovered:
		_buy_texture.visible = true
		if main_money < price:
			_buy_texture.self_modulate = BUY_COLOR_DEACTIVE
			_buy_label.text = "NO MONEY"
		else:
			_buy_texture.self_modulate = BUY_COLOR_ACTIVE
			_buy_label.text = "BUY"
	else:
		_buy_texture.visible = false


func _on_icon_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			icon_pressed.emit(self)


func _on_icon_mouse_entered() -> void:
	_is_icon_hovered = true
	refresh_view()

func _on_icon_mouse_exited() -> void:
	_is_icon_hovered = false
	refresh_view()
