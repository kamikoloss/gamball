class_name BallEffect
extends Object
# ボール効果に関するデータをまとめたクラス


# ボール効果の種類
enum Type {
	NONE,
	DECK_SIZE_MIN_DOWN,
	EXTRA_SIZE_MAX_UP,
	GAIN_UP_BALL_NUMBER, GAIN_UP_BALL_NUMBER_2,
	GAIN_UP_BL_COUNT, GAIN_UP_BL_COUNT_2,
	GAIN_UP_DECK_COMPLETE,
	GAIN_UP_DECK_COUNT,
	GAIN_UP_HOLE,
	HOLE_SIZE_UP,
	HOLE_GRAVITY_SIZE_UP,
	MONEY_UP_BREAK,
	MONEY_UP_FALL,
	NUMBER_UP_SPAWN,
	PC_START_TOP_UP, PC_CONTINUE_TOP_UP,
	RARITY_TOP_UP, RARITY_TOP_DOWN,
	TAX_BALLS_DOWN, TAX_MONEY_DOWN,
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

# 効果の説明文 (翻訳キー)
const EFFECT_DESCRIPTIONS := {
	Type.NONE: "",
	Type.GAIN_UP_BALL_NUMBER: "LV.{a} 以下のボールの Gain +{b}",
	Type.GAIN_UP_BALL_NUMBER_2: "LV.{a} のボールの Gain x{b}",
	Type.GAIN_UP_BL_COUNT: "ビリヤード上のボールが {a} 個以下のとき Gain +{b}",
	Type.GAIN_UP_BL_COUNT_2: "ビリヤード上のボールが {a} 個以下のとき Gain x{b}",
	Type.GAIN_UP_DECK_COMPLETE: "DECK に LV.0 から LV.{a} まで揃っているとき Gain x{b}",
	Type.GAIN_UP_DECK_COUNT: "DECK のボールが {a} 個以下のとき Gain +{b}",
	Type.GAIN_UP_HOLE: "xn の Gain +{a}",
	Type.NUMBER_UP_SPAWN: "出現時にビリヤード上のすべてのボール LV. +{a}",
	Type.DECK_SIZE_MIN_DOWN: "DECK の最小サイズ -{a}",
	Type.EXTRA_SIZE_MAX_UP: "EXTRA の最大サイズ +{a}",
	Type.HOLE_SIZE_UP: "ビリヤードポケットのサイズ +{a} (最大 +4)",
	Type.HOLE_GRAVITY_SIZE_UP: "ビリヤードポケットの重力範囲サイズ +{a} (最大 +4)",
	Type.MONEY_UP_BREAK: "破壊時に MONEY x{a}",
	Type.MONEY_UP_FALL: "ビリヤードポケット落下時に MONEY +{a}",
	Type.PC_START_TOP_UP: "パチンコの初当たりランプ数 +{a} (最大 +2)",
	Type.PC_CONTINUE_TOP_UP: "パチンコの継続ランプ数 +{a} (最大 +6)",
	Type.RARITY_TOP_UP: "{a} の出現確率 +1",
	Type.RARITY_TOP_DOWN: "{a} の出現確率 -1 (最小 -2)",
	Type.TAX_BALLS_DOWN: "BALLS で支払う延長料 -{a}% (最大 -50%)",
	Type.TAX_MONEY_DOWN: "MONEY で支払う延長料 -{a}% (最大 -50%)",
}

# Ball LV/Rarity ごとの初期効果
# { <Ball LV>: { <Ball Rarity>: [ <EffectType>, param1, (param2) ], ... } }
const EFFECTS_POOL_1 := {
	0: {
		Ball.Rarity.UNCOMMON:	[Type.MONEY_UP_BREAK, 2],
		Ball.Rarity.RARE:		[Type.MONEY_UP_BREAK, 3],
		Ball.Rarity.EPIC:		[Type.MONEY_UP_BREAK, 5],
		Ball.Rarity.LEGENDARY:	[Type.MONEY_UP_BREAK, 10],
	},
	1: {
		Ball.Rarity.UNCOMMON:	[Type.MONEY_UP_FALL, 10],
		Ball.Rarity.RARE:		[Type.MONEY_UP_FALL, 20],
		Ball.Rarity.EPIC:		[Type.MONEY_UP_FALL, 30],
		Ball.Rarity.LEGENDARY:	[Type.MONEY_UP_FALL, 50],
	},
	2: {
		Ball.Rarity.UNCOMMON:	[Type.GAIN_UP_BL_COUNT, 50, 1],
		Ball.Rarity.RARE:		[Type.GAIN_UP_BL_COUNT, 30, 2],
		Ball.Rarity.EPIC:		[Type.GAIN_UP_BL_COUNT, 20, 3],
		Ball.Rarity.LEGENDARY:	[Type.GAIN_UP_BL_COUNT, 10, 5],
	},
	3: {
		Ball.Rarity.UNCOMMON:	[Type.GAIN_UP_BL_COUNT_2, 5, 2],
		Ball.Rarity.RARE:		[Type.GAIN_UP_BL_COUNT_2, 3, 3],
		Ball.Rarity.EPIC:		[Type.GAIN_UP_BL_COUNT_2, 2, 5],
		Ball.Rarity.LEGENDARY:	[Type.GAIN_UP_BL_COUNT_2, 1, 10],
	},
	4: {
		Ball.Rarity.UNCOMMON:	[Type.NUMBER_UP_SPAWN, 1],
		Ball.Rarity.RARE:		[Type.NUMBER_UP_SPAWN, 2],
		Ball.Rarity.EPIC:		[Type.NUMBER_UP_SPAWN, 3],
		Ball.Rarity.LEGENDARY:	[Type.NUMBER_UP_SPAWN, 5],
	},
	5: {
		Ball.Rarity.UNCOMMON:	[Type.PC_CONTINUE_TOP_UP, 1],
		Ball.Rarity.RARE:		[Type.PC_CONTINUE_TOP_UP, 2],
		Ball.Rarity.EPIC:		[Type.PC_START_TOP_UP, 1],
		Ball.Rarity.LEGENDARY:	[Type.PC_START_TOP_UP, 2],
	},
	6: {
		Ball.Rarity.UNCOMMON:	[Type.GAIN_UP_BALL_NUMBER, 3, 1],
		Ball.Rarity.RARE:		[Type.GAIN_UP_BALL_NUMBER, 7, 1],
		Ball.Rarity.EPIC:		[Type.GAIN_UP_BALL_NUMBER, 11, 1],
		Ball.Rarity.LEGENDARY:	[Type.GAIN_UP_BALL_NUMBER, 15, 1],
	},
	7: {
		Ball.Rarity.UNCOMMON:	[Type.GAIN_UP_BALL_NUMBER_2, 1, 2],
		Ball.Rarity.RARE:		[Type.GAIN_UP_BALL_NUMBER_2, 2, 2],
		Ball.Rarity.EPIC:		[Type.GAIN_UP_BALL_NUMBER_2, 3, 2],
		Ball.Rarity.LEGENDARY:	[Type.GAIN_UP_BALL_NUMBER_2, 5, 2],
	},
	8: {
		Ball.Rarity.UNCOMMON:	[Type.GAIN_UP_DECK_COUNT, 2, 1],
		Ball.Rarity.RARE:		[Type.GAIN_UP_DECK_COUNT, 4, 2],
		Ball.Rarity.EPIC:		[Type.GAIN_UP_DECK_COUNT, 6, 3],
		Ball.Rarity.LEGENDARY:	[Type.GAIN_UP_DECK_COUNT, 8, 5],
	},
	9: {
		Ball.Rarity.UNCOMMON:	[Type.GAIN_UP_HOLE, 1],
		Ball.Rarity.RARE:		[Type.GAIN_UP_HOLE, 2],
		Ball.Rarity.EPIC:		[Type.GAIN_UP_HOLE, 3],
		Ball.Rarity.LEGENDARY:	[Type.GAIN_UP_HOLE, 5],
	},
	10: {
		Ball.Rarity.UNCOMMON:	[Type.TAX_BALLS_DOWN, 10],
		Ball.Rarity.RARE:		[Type.TAX_BALLS_DOWN, 20],
		Ball.Rarity.EPIC:		[Type.TAX_BALLS_DOWN, 30],
		Ball.Rarity.LEGENDARY:	[Type.TAX_BALLS_DOWN, 50],
	},
	11: {
		Ball.Rarity.UNCOMMON:	[Type.TAX_MONEY_DOWN, 10],
		Ball.Rarity.RARE:		[Type.TAX_MONEY_DOWN, 20],
		Ball.Rarity.EPIC:		[Type.TAX_MONEY_DOWN, 30],
		Ball.Rarity.LEGENDARY:	[Type.TAX_MONEY_DOWN, 50],
	},
	12: {
		Ball.Rarity.UNCOMMON:	[Type.HOLE_SIZE_UP, 1],
		Ball.Rarity.RARE:		[Type.HOLE_SIZE_UP, 2],
		Ball.Rarity.EPIC:		[Type.HOLE_GRAVITY_SIZE_UP, 1],
		Ball.Rarity.LEGENDARY:	[Type.HOLE_GRAVITY_SIZE_UP, 2],
	},
	13: {
		Ball.Rarity.UNCOMMON:	[Type.GAIN_UP_DECK_COMPLETE, 3, 2],
		Ball.Rarity.RARE:		[Type.GAIN_UP_DECK_COMPLETE, 7, 3],
		Ball.Rarity.EPIC:		[Type.GAIN_UP_DECK_COMPLETE, 11, 5],
		Ball.Rarity.LEGENDARY:	[Type.GAIN_UP_DECK_COMPLETE, 15, 10],
	},
	14: {
		Ball.Rarity.UNCOMMON:	[Type.EXTRA_SIZE_MAX_UP, 2],
		Ball.Rarity.RARE:		[Type.EXTRA_SIZE_MAX_UP, 4],
		Ball.Rarity.EPIC:		[Type.DECK_SIZE_MIN_DOWN, 1],
		Ball.Rarity.LEGENDARY:	[Type.DECK_SIZE_MIN_DOWN, 2],
	},
	15: {
		Ball.Rarity.UNCOMMON:	[Type.RARITY_TOP_UP, Ball.Rarity.RARE],
		Ball.Rarity.RARE:		[Type.RARITY_TOP_UP, Ball.Rarity.EPIC],
		Ball.Rarity.EPIC:		[Type.RARITY_TOP_UP, Ball.Rarity.LEGENDARY],
		Ball.Rarity.LEGENDARY:	[Type.RARITY_TOP_DOWN, Ball.Rarity.COMMON],
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
	if effect_data[0] == Type.NONE:
		return "(TODO)"

	var description_base = EFFECT_DESCRIPTIONS[effect_data[0]]
	var rarity_color: Color = ColorPalette.BALL_RARITY_COLORS[rarity]
	var rarity_color_code = rarity_color.to_html()
	var get_variable_text = func(x) -> String:
		return "[color={r}][b]{x}[/b][/color]".format({ "r": rarity_color_code, "x": x })

	# [ <EffectType>, Ball.Rarity ]
	if effect_data[0] in [Type.RARITY_TOP_UP, Type.RARITY_TOP_DOWN]:
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
