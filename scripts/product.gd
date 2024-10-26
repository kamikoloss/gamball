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

# 商品の [<名称>, <説明分>]
const PRODUCT_DATA = {
	ProductType.DeckPack: ["DECK Pack", "Add random BALL x3\n(0-7) to DECK"],
	ProductType.DeckPack2: ["DECK Pack+", "Add random BALL x1\n(8-15) to DECK"],
	ProductType.DeckCleaner: ["DECK Cleaner", "Remove the lowest\nBALL from DECK"],
	ProductType.ExtraPack: ["EXTRA Pack", "Add random BALL x2\n(0-7) to EXTRA"],
	ProductType.ExtraPack2: ["EXTRA Pack+", "Add random BALL x1\n(8-15) to EXTRA"],
	ProductType.ExtraCleaner: ["EXTRA Cleaner", "Remove the lowest\nBALL from EXTRA"],
}


@export var product_type: ProductType = ProductType.DeckPack

# UI
@export var _icon_texture: TextureRect
@export var _name_label: Label
@export var _desc_label: Label
@export var _price_label: Label


var price: int:
	get:
		return PRODUCT_PRICES[product_type]


func _ready() -> void:
	refresh_view()
	_icon_texture.gui_input.connect(_on_icon_input)


# 自身の見た目を更新する
func refresh_view() -> void:
	#icon_texture
	_name_label.text = PRODUCT_DATA[product_type][0]
	_desc_label.text = PRODUCT_DATA[product_type][1]
	_price_label.text = "＄%s" % str(price)


func _on_icon_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			icon_pressed.emit(self)