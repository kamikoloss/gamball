class_name Product
extends Control


# アイコンがクリックされたとき (Product)
signal icon_pressed


enum ProductType {
	DeckPack,
	DeckPack2,
	DeckCleaner,
	ExtraPack,
	ExtraPack2,
	ExtraCleaner,
}


const PRODUCT_PRICES = {
	ProductType.DeckPack: 100,
	ProductType.DeckPack2: 200,
	ProductType.DeckCleaner: 50,
	ProductType.ExtraPack: 200,
	ProductType.ExtraPack2: 400,
	ProductType.ExtraCleaner: 100,
}

const BUY_COLOR_ACTIVE = Color(0.25, 0.5, 0.25)
const BUY_COLOR_DEACTIVE = Color(0.5, 0.25, 0.25)


# 商品の [<名称>, <説明分>]
# TODO: JSON に逃がす
const PRODUCT_DATA = {
	ProductType.DeckPack: ["DECK Pack", "Add random BALL x3\nto DECK"],
	ProductType.DeckPack2: ["DECK Pack+", "Add random BALL x1\nto DECK"],
	ProductType.DeckCleaner: ["DECK Cleaner", "Remove the lowest\nBALL from DECK"],
	ProductType.ExtraPack: ["EXTRA Pack", "Add random BALL x2\nto EXTRA"],
	ProductType.ExtraPack2: ["EXTRA Pack+", "Add random BALL x1\nto EXTRA"],
	ProductType.ExtraCleaner: ["EXTRA Cleaner", "Remove the lowest\nBALL from EXTRA"],
}


@export var product_type: ProductType = ProductType.DeckPack

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
	match product_type:
		ProductType.DeckPack:
			_icon_texture.texture = _icon_pack
		ProductType.DeckCleaner:
			_icon_texture.texture = _icon_cleaner
		ProductType.ExtraPack:
			_icon_texture.texture = _icon_pack
		ProductType.ExtraCleaner:
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
