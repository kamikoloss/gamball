class_name BallEffect
extends Node
# Ball の効果に関する enum, const, static func をまとめたクラス


# 効果の種類
# TODO: 命名もっとメソッド的にしたい BILLIARDS_MERGE_BALLS_ON_SPAWN あたりはちょうどいい
enum EffectType {
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
	TAX_DOWN,
}


# 効果の説明文 (BBCode)
const EFFECT_DESCRIPTIONS = {
	EffectType.BILLIARDS_COUNT_GAIN_UP: "ビリヤード盤面上の Ball が [color={r}][{a}][/color] 個以下のとき Gain [color={r}][+{b}][/color]",
	EffectType.BILLIARDS_COUNT_GAIN_UP_2: "ビリヤード盤面上の Ball が [color={r}][{a}][/color] 個以下のとき Gain [color={r}][x{b}][/color]",
	EffectType.BILLIARDS_LV_UP_ON_SPAWN: "出現時にビリヤード盤面上の Ball LV [color={r}][+{a}][/color]",
	EffectType.BILLIARDS_MERGE_BALLS_ON_SPAWN: "出現時にビリヤード顔面上の Ball LV 0 [color={r}][x{a}][/color] を LV 15 x1 に変換する",
	EffectType.DECK_SIZE_MIN_DOWN: "DECK の最小サイズ [color={r}][-{a}][/color]",
	EffectType.DECK_COMPLETE_GAIN_UP: "DECK に [color={r}][0-{a}][/color] が揃っているとき Gain [color={r}][x{b}][/color]",
	EffectType.DECK_COUNT_GAIN_UP: "DECK の Ball が [color={r}][{a}][/color] 個以下のとき Gain [color={r}][+{b}][/color]",
	EffectType.EXTRA_SIZE_MAX_UP: "EXTRA の最大サイズ [color={r}][+{a}][/color]",
	EffectType.HOLE_GAIN_UP: "Hole の Gain [color={r}][+{a}][/color]",
	EffectType.HOLE_SIZE_UP: "Hole のサイズ [color={r}][x{a}][/color]",
	EffectType.HOLE_GRAVITY_SIZE_UP: "Hole の重力範囲サイズ [color={r}][x{a}][/color]",
	EffectType.GAIN_UP: "LV [color={r}][{a}][/color] 以下の Ball の Gain [color={r}][+{b}][/color]",
	EffectType.GAIN_UP_2: "LV [color={r}][{a}][/color] の Ball の Gain [color={r}][x{b}][/color]",
	EffectType.MONEY_UP_ON_BREAK: "破壊時に MONEY [color={r}][x{a}][/color]",
	EffectType.MONEY_UP_ON_FALL: "落下時に MONEY [color={r}][+{a}][/color]",
	EffectType.PACHINKO_START_TOP_UP: "パチンコの初当たり確率 [color={r}][+{a}][/color]",
	EffectType.PACHINKO_CONTINUE_TOP_UP: "パチンコの継続確率 [color={r}][+{a}][/color]",
	EffectType.RARITY_TOP_UP: "[color={r}][{a}][/color] の出現確率が上がる",
	EffectType.RARITY_TOP_DOWN: "[color={r}][{a}][/color] の出現確率が下がる",
	EffectType.TAX_DOWN: "延長料 [color={r}][-{a}%][/color]",
}

# Ball LV/Rarity ごとの初期効果
# { <Ball LV>: { <Ball Rarity>: [ <EffectType>, param1, (param2) ], ... } }
# TODO: 表っぽいデータなので Google Sheets とかに外出しする？
const EFFECTS_POOL_1 = {
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
		Ball.Rarity.UNCOMMON:	[EffectType.BILLIARDS_MERGE_BALLS_ON_SPAWN, 50],
		Ball.Rarity.RARE:		[EffectType.BILLIARDS_MERGE_BALLS_ON_SPAWN, 30],
		Ball.Rarity.EPIC:		[EffectType.BILLIARDS_MERGE_BALLS_ON_SPAWN, 20],
		Ball.Rarity.LEGENDARY:	[EffectType.BILLIARDS_MERGE_BALLS_ON_SPAWN, 10],
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
		Ball.Rarity.UNCOMMON:	[EffectType.DECK_COUNT_GAIN_UP, 4, 1],
		Ball.Rarity.RARE:		[EffectType.DECK_COUNT_GAIN_UP, 8, 2],
		Ball.Rarity.EPIC:		[EffectType.DECK_COUNT_GAIN_UP, 12, 3],
		Ball.Rarity.LEGENDARY:	[EffectType.DECK_COUNT_GAIN_UP, 16, 5],
	},
	9: {
		Ball.Rarity.UNCOMMON:	[EffectType.HOLE_GAIN_UP, 1],
		Ball.Rarity.RARE:		[EffectType.HOLE_GAIN_UP, 2],
		Ball.Rarity.EPIC:		[EffectType.HOLE_GAIN_UP, 3],
		Ball.Rarity.LEGENDARY:	[EffectType.HOLE_GAIN_UP, 5],
	},
	10: {
		Ball.Rarity.UNCOMMON:	[EffectType.PACHINKO_CONTINUE_TOP_UP, 1],
		Ball.Rarity.RARE:		[EffectType.PACHINKO_CONTINUE_TOP_UP, 2],
		Ball.Rarity.EPIC:		[EffectType.PACHINKO_START_TOP_UP, 1],
		Ball.Rarity.LEGENDARY:	[EffectType.PACHINKO_START_TOP_UP, 2],
	},
	11: {
		Ball.Rarity.UNCOMMON:	[EffectType.TAX_DOWN, 10],
		Ball.Rarity.RARE:		[EffectType.TAX_DOWN, 20],
		Ball.Rarity.EPIC:		[EffectType.TAX_DOWN, 30],
		Ball.Rarity.LEGENDARY:	[EffectType.TAX_DOWN, 50],
	},
	12: {
		Ball.Rarity.UNCOMMON:	[EffectType.HOLE_SIZE_UP, 2],
		Ball.Rarity.RARE:		[EffectType.HOLE_SIZE_UP, 3],
		Ball.Rarity.EPIC:		[EffectType.HOLE_GRAVITY_SIZE_UP, 2],
		Ball.Rarity.LEGENDARY:	[EffectType.HOLE_GRAVITY_SIZE_UP, 3],
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


# 効果の説明文 (RichTextLabel 用) を取得する
static func get_effect_description(level: int, rarity: Ball.Rarity) -> String:
	if level == Ball.BALL_LEVEL_EMPTY_SLOT:
		return "(空きスロット)"
	if level == Ball.BALL_LEVEL_NOT_EMPTY_SLOT:
		return "(使用不可スロット)"
	if rarity == Ball.Rarity.COMMON:
		return "(効果なし)"

	var effect_data = EFFECTS_POOL_1[level][rarity] # [ <EffectType>, param1, (param2) ]
	var description_base = EFFECT_DESCRIPTIONS[effect_data[0]]
	var rarity_color: Color = Ball.BALL_RARITY_COLORS[rarity]
	var rarity_color_code = rarity_color.to_html()

	# [ <EffectType>, Ball.Rarity ]
	if effect_data[0] in [EffectType.RARITY_TOP_UP, EffectType.RARITY_TOP_DOWN]:
		var a = Ball.Rarity.keys()[effect_data[1]]
		return description_base.format({ "r": rarity_color_code, "a": a })

	# [ <EffectType>, param1 ]
	if effect_data.size() == 2:
		return description_base.format({ "r": rarity_color_code, "a": effect_data[1] })
	# [ <EffectType>, param1, param2 ]
	if effect_data.size() == 3:
		return description_base.format({ "r": rarity_color_code, "a": effect_data[1], "b": effect_data[2] })

	return ""
