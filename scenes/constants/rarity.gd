class_name Rarity
extends Object


enum Type {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
}


# レア度のテキスト
const RARITY_TEXT := {
	Type.COMMON: "★",
	Type.UNCOMMON: "★★",
	Type.RARE: "★★★",
	Type.EPIC: "★★★★",
	Type.LEGENDARY: "★★★★★",
}
