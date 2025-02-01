class_name BallEffect
extends Object
# Ball の効果に関する enum, const, static func をまとめたクラス


# 効果の種類
# TODO: 命名もっとメソッド的にしたい BILLIARDS_MERGE_BALLS_ON_SPAWN あたりはちょうどいい
enum EffectType {
	NONE,
	BILLIARDS_COUNT_GAIN_UP, BILLIARDS_COUNT_GAIN_UP_2,
	BILLIARDS_LV_UP_ON_SPAWN,
	BILLIARDS_MERGE_BALLS_ON_SPAWN,
	DECK_SIZE_MIN_DOWN,
	DECK_COMPLETE_GAIN_UP,
	DECK_COUNT_GAIN_UP,
	EXTRA_SIZE_MAX_UP,
	HOLE_GAIN_UP,
	HOLE_SIZE_UP,
	HOLE_GRAVITY_SIZE_UP,
	GAIN_UP, GAIN_UP_2,
	MONEY_UP_ON_BREAK,
	MONEY_UP_ON_FALL,
	PACHINKO_START_TOP_UP,
	PACHINKO_CONTINUE_TOP_UP,
	RARITY_TOP_UP, RARITY_TOP_DOWN,
	TAX_BALLS_DOWN, TAX_MONEY_DOWN
}


# TODO: 居場所はここではない？
# TODO: Rarity って言葉が変？
const RARITY_TEXT := {
	Ball.Rarity.COMMON: 	"★",
	Ball.Rarity.UNCOMMON:	"★★",
	Ball.Rarity.RARE:		"★★★",
	Ball.Rarity.EPIC:		"★★★★",
	Ball.Rarity.LEGENDARY:	"★★★★★",
}

# 効果の説明文
const EFFECT_DESCRIPTIONS := {
	EffectType.NONE: "",
	EffectType.BILLIARDS_COUNT_GAIN_UP: "ビリヤード上のボールが {a} 個以下のとき Gain +{b}",
	EffectType.BILLIARDS_COUNT_GAIN_UP_2: "ビリヤード上のボールが {a} 個以下のとき Gain x{b}",
	EffectType.BILLIARDS_LV_UP_ON_SPAWN: "出現時にビリヤード上のすべてのボール LV. +{a}",
	EffectType.BILLIARDS_MERGE_BALLS_ON_SPAWN: "出現時にビリヤード上のボール LV.0 x{a} を LV15 x1 に変換する",
	EffectType.DECK_SIZE_MIN_DOWN: "DECK の最小サイズ -{a}",
	EffectType.DECK_COMPLETE_GAIN_UP: "DECK に LV.0 から LV.{a} まで揃っているとき Gain x{b}",
	EffectType.DECK_COUNT_GAIN_UP: "DECK のボールが {a} 個以下のとき Gain +{b}",
	EffectType.EXTRA_SIZE_MAX_UP: "EXTRA の最大サイズ +{a}",
	EffectType.HOLE_GAIN_UP: "パチンコポケットの Gain +{a}",
	EffectType.HOLE_SIZE_UP: "ビリヤードポケットのサイズ +{a} (最大 +4)",
	EffectType.HOLE_GRAVITY_SIZE_UP: "ビリヤードポケットの重力範囲サイズ +{a} (最大 +4)",
	EffectType.GAIN_UP: "LV.{a} 以下のボールの Gain +{b}",
	EffectType.GAIN_UP_2: "LV.{a} のボールの Gain x{b}",
	EffectType.MONEY_UP_ON_BREAK: "破壊時に MONEY x{a}",
	EffectType.MONEY_UP_ON_FALL: "ビリヤードポケット落下時に MONEY +{a}",
	EffectType.PACHINKO_START_TOP_UP: "パチンコの初当たりランプ数 +{a} (最大 +2)",
	EffectType.PACHINKO_CONTINUE_TOP_UP: "パチンコの継続ランプ数 +{a} (最大 +6)",
	EffectType.RARITY_TOP_UP: "{a} の出現確率 +1",
	EffectType.RARITY_TOP_DOWN: "{a} の出現確率 -1 (最小 -2)",
	EffectType.TAX_BALLS_DOWN: "BALLS で支払う延長料 -{a}% (最大 -50%)",
	EffectType.TAX_MONEY_DOWN: "MONEY で支払う延長料 -{a}% (最大 -50%)",
}

# Ball LV/Rarity ごとの初期効果
# { <Ball LV>: { <Ball Rarity>: [ <EffectType>, param1, (param2) ], ... } }
# TODO: 表っぽいデータなので Google Sheets とかに外出しする？
const EFFECTS_POOL_1 := {
	0: {
		Ball.Rarity.UNCOMMON:	[EffectType.MONEY_UP_ON_BREAK, 2],
		Ball.Rarity.RARE:		[EffectType.MONEY_UP_ON_BREAK, 3],
		Ball.Rarity.EPIC:		[EffectType.MONEY_UP_ON_BREAK, 5],
		Ball.Rarity.LEGENDARY:	[EffectType.MONEY_UP_ON_BREAK, 10],
	},
	1: {
		Ball.Rarity.UNCOMMON:	[EffectType.MONEY_UP_ON_FALL, 10],
		Ball.Rarity.RARE:		[EffectType.MONEY_UP_ON_FALL, 20],
		Ball.Rarity.EPIC:		[EffectType.MONEY_UP_ON_FALL, 30],
		Ball.Rarity.LEGENDARY:	[EffectType.MONEY_UP_ON_FALL, 50],
	},
	2: {
		Ball.Rarity.UNCOMMON:	[EffectType.BILLIARDS_COUNT_GAIN_UP, 50, 1],
		Ball.Rarity.RARE:		[EffectType.BILLIARDS_COUNT_GAIN_UP, 30, 2],
		Ball.Rarity.EPIC:		[EffectType.BILLIARDS_COUNT_GAIN_UP, 20, 3],
		Ball.Rarity.LEGENDARY:	[EffectType.BILLIARDS_COUNT_GAIN_UP, 10, 5],
	},
	3: {
		Ball.Rarity.UNCOMMON:	[EffectType.BILLIARDS_COUNT_GAIN_UP_2, 5, 2],
		Ball.Rarity.RARE:		[EffectType.BILLIARDS_COUNT_GAIN_UP_2, 3, 3],
		Ball.Rarity.EPIC:		[EffectType.BILLIARDS_COUNT_GAIN_UP_2, 2, 5],
		Ball.Rarity.LEGENDARY:	[EffectType.BILLIARDS_COUNT_GAIN_UP_2, 1, 10],
	},
	4: {
		Ball.Rarity.UNCOMMON:	[EffectType.BILLIARDS_LV_UP_ON_SPAWN, 1],
		Ball.Rarity.RARE:		[EffectType.BILLIARDS_LV_UP_ON_SPAWN, 2],
		Ball.Rarity.EPIC:		[EffectType.BILLIARDS_LV_UP_ON_SPAWN, 3],
		Ball.Rarity.LEGENDARY:	[EffectType.BILLIARDS_LV_UP_ON_SPAWN, 5],
	},
	5: {
		Ball.Rarity.UNCOMMON:	[EffectType.PACHINKO_CONTINUE_TOP_UP, 1],
		Ball.Rarity.RARE:		[EffectType.PACHINKO_CONTINUE_TOP_UP, 2],
		Ball.Rarity.EPIC:		[EffectType.PACHINKO_START_TOP_UP, 1],
		Ball.Rarity.LEGENDARY:	[EffectType.PACHINKO_START_TOP_UP, 2],
	},
	6: {
		Ball.Rarity.UNCOMMON:	[EffectType.GAIN_UP, 3, 1],
		Ball.Rarity.RARE:		[EffectType.GAIN_UP, 7, 1],
		Ball.Rarity.EPIC:		[EffectType.GAIN_UP, 11, 1],
		Ball.Rarity.LEGENDARY:	[EffectType.GAIN_UP, 15, 1],
	},
	7: {
		Ball.Rarity.UNCOMMON:	[EffectType.GAIN_UP_2, 1, 2],
		Ball.Rarity.RARE:		[EffectType.GAIN_UP_2, 2, 2],
		Ball.Rarity.EPIC:		[EffectType.GAIN_UP_2, 3, 2],
		Ball.Rarity.LEGENDARY:	[EffectType.GAIN_UP_2, 5, 2],
	},
	8: {
		Ball.Rarity.UNCOMMON:	[EffectType.DECK_COUNT_GAIN_UP, 2, 1],
		Ball.Rarity.RARE:		[EffectType.DECK_COUNT_GAIN_UP, 4, 2],
		Ball.Rarity.EPIC:		[EffectType.DECK_COUNT_GAIN_UP, 6, 3],
		Ball.Rarity.LEGENDARY:	[EffectType.DECK_COUNT_GAIN_UP, 8, 5],
	},
	9: {
		Ball.Rarity.UNCOMMON:	[EffectType.HOLE_GAIN_UP, 1],
		Ball.Rarity.RARE:		[EffectType.HOLE_GAIN_UP, 2],
		Ball.Rarity.EPIC:		[EffectType.HOLE_GAIN_UP, 3],
		Ball.Rarity.LEGENDARY:	[EffectType.HOLE_GAIN_UP, 5],
	},
	10: {
		Ball.Rarity.UNCOMMON:	[EffectType.TAX_BALLS_DOWN, 10],
		Ball.Rarity.RARE:		[EffectType.TAX_BALLS_DOWN, 20],
		Ball.Rarity.EPIC:		[EffectType.TAX_BALLS_DOWN, 30],
		Ball.Rarity.LEGENDARY:	[EffectType.TAX_BALLS_DOWN, 50],
	},
	11: {
		Ball.Rarity.UNCOMMON:	[EffectType.TAX_MONEY_DOWN, 10],
		Ball.Rarity.RARE:		[EffectType.TAX_MONEY_DOWN, 20],
		Ball.Rarity.EPIC:		[EffectType.TAX_MONEY_DOWN, 30],
		Ball.Rarity.LEGENDARY:	[EffectType.TAX_MONEY_DOWN, 50],
	},
	12: {
		Ball.Rarity.UNCOMMON:	[EffectType.HOLE_SIZE_UP, 1],
		Ball.Rarity.RARE:		[EffectType.HOLE_SIZE_UP, 2],
		Ball.Rarity.EPIC:		[EffectType.HOLE_GRAVITY_SIZE_UP, 1],
		Ball.Rarity.LEGENDARY:	[EffectType.HOLE_GRAVITY_SIZE_UP, 2],
	},
	13: {
		Ball.Rarity.UNCOMMON:	[EffectType.DECK_COMPLETE_GAIN_UP, 3, 2],
		Ball.Rarity.RARE:		[EffectType.DECK_COMPLETE_GAIN_UP, 7, 3],
		Ball.Rarity.EPIC:		[EffectType.DECK_COMPLETE_GAIN_UP, 11, 5],
		Ball.Rarity.LEGENDARY:	[EffectType.DECK_COMPLETE_GAIN_UP, 15, 10],
	},
	14: {
		Ball.Rarity.UNCOMMON:	[EffectType.EXTRA_SIZE_MAX_UP, 2],
		Ball.Rarity.RARE:		[EffectType.EXTRA_SIZE_MAX_UP, 4],
		Ball.Rarity.EPIC:		[EffectType.DECK_SIZE_MIN_DOWN, 1],
		Ball.Rarity.LEGENDARY:	[EffectType.DECK_SIZE_MIN_DOWN, 2],
	},
	15: {
		Ball.Rarity.UNCOMMON:	[EffectType.RARITY_TOP_UP, Ball.Rarity.RARE],
		Ball.Rarity.RARE:		[EffectType.RARITY_TOP_UP, Ball.Rarity.EPIC],
		Ball.Rarity.EPIC:		[EffectType.RARITY_TOP_UP, Ball.Rarity.LEGENDARY],
		Ball.Rarity.LEGENDARY:	[EffectType.RARITY_TOP_DOWN, Ball.Rarity.COMMON],
	},
}
const EFFECTS_POOL_2 := {
}


# 効果の説明文 (RichTextLabel 用) を取得する
static func get_effect_description(level: int, rarity: Ball.Rarity) -> String:
	if level == Ball.BALL_LEVEL_OPTIONAL_SLOT:
		return "(空きスロット)"
	if level == Ball.BALL_LEVEL_DISABLED_SLOT:
		return "(使用不可スロット)"
	if rarity == Ball.Rarity.COMMON:
		return "(効果なし)"

	var effect_data = EFFECTS_POOL_1[level][rarity] # [ <EffectType>, param1, (param2) 

	# 効果なし
	if effect_data[0] == EffectType.NONE:
		return "(TODO)"

	var description_base = EFFECT_DESCRIPTIONS[effect_data[0]]
	var rarity_color: Color = ColorPalette.BALL_RARITY_COLORS[rarity]
	var rarity_color_code = rarity_color.to_html()
	var get_variable_text = func(x) -> String:
		return "[color={r}][b]{x}[/b][/color]".format({ "r": rarity_color_code, "x": x })

	# [ <EffectType>, Ball.Rarity ]
	if effect_data[0] in [EffectType.RARITY_TOP_UP, EffectType.RARITY_TOP_DOWN]:
		var a = BallEffect.RARITY_TEXT[effect_data[1]]
		return description_base.format({
			"a": get_variable_text.call(a),
		})
	# [ <EffectType>, param1 ]
	if effect_data.size() == 2:
		return description_base.format({
			"a": get_variable_text.call(effect_data[1]),
		})
	# [ <EffectType>, param1, param2 ]
	if effect_data.size() == 3:
		return description_base.format({
			"a": get_variable_text.call(effect_data[1]),
			"b": get_variable_text.call(effect_data[2]),
		})

	return ""
