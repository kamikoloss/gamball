class_name BallEffect
extends Node


# 効果の種類
# TODO: 命名のルール欲しいかも？
enum EffectType {
	BILLIARDS_COUNT_GAIN_UP,
	BILLIARDS_COUNT_GAIN_UP_2,
	BILLIARDS_LV_UP_ON_SPAWN,
	BILLIARDS_MERGE_BALLS_ON_SPAWN,
	DECK_MIN_SIZE_DOWN,
	DECK_COMPLETE_GAIN_UP,
	DECK_COUNT_GAIN_UP,
	EXTRA_MAX_SIZE_UP,
	HOLE_GAIN_UP,
	HOLE_SIZE_UP,
	HOLE_GRAVITY_SIZE_UP,
	LV_UP,
	LV_UP_2,
	MONEY_UP_ON_BREAK,
	MONEY_UP_ON_FALL,
	PACHINKO_START_TOP_UP,
	PACHINKO_CONTINUE_TOP_UP,
	RARITY_TOP_UP, RARITY_TOP_DOWN,
	TAX_DOWN,
}


# 効果の説明文
const EFFECT_DESCRIPTIONS = {
	EffectType.BILLIARDS_COUNT_GAIN_UP: "ビリヤード盤面上の Ball が %s 個以下のとき Gain +%s",
	EffectType.BILLIARDS_COUNT_GAIN_UP_2: "ビリヤード盤面上の Ball が %s 個以下のとき Gain x%s",
	EffectType.BILLIARDS_LV_UP_ON_SPAWN: "出現時にビリヤード盤面上の Ball LV +%s",
	EffectType.BILLIARDS_MERGE_BALLS_ON_SPAWN: "出現時にビリヤード顔面上の Ball LV %s x%s を LV 15 x1 に変換する",
	EffectType.DECK_MIN_SIZE_DOWN: "DECK の最小サイズ -%s",
	EffectType.DECK_COMPLETE_GAIN_UP: "Deck に 0-%s が揃っているとき Gain x%s",
	EffectType.DECK_COUNT_GAIN_UP: "Deck の Ball が %s 個以下のとき Gain +%s",
	EffectType.EXTRA_MAX_SIZE_UP: "Extra の最大サイズ +%s",
	EffectType.HOLE_GAIN_UP: "Hole の Gain +%s",
	EffectType.HOLE_SIZE_UP: "Hole のサイズ x%s",
	EffectType.HOLE_GRAVITY_SIZE_UP: "Hole の重力範囲サイズ x%s",
	EffectType.LV_UP: "LV %s 以下の Ball の LV +%s",
	EffectType.LV_UP_2: "LV % の Ball の LV x%",
	EffectType.MONEY_UP_ON_BREAK: "破壊時に MONEY x%s",
	EffectType.MONEY_UP_ON_FALL: "落下時に MONEY +%s",
	EffectType.PACHINKO_START_TOP_UP: "パチンコの初当たり確率 +%s",
	EffectType.PACHINKO_CONTINUE_TOP_UP: "パチンコの継続確率 +%s",
	EffectType.RARITY_TOP_UP: "レアリティ %s の出現確率が 上がる",
	EffectType.RARITY_TOP_DOWN: "レアリティ %s の出現確率が 下がる",
	EffectType.TAX_DOWN: "延長料 -%s%",
}

# Ball LV/Rarity ごとの初期効果
# { <Ball LV>: { <Ball Rarity>: [ <EffectType>, param1, (param2) ], ... } }
# TODO: 表っぽいデータなので Google Sheets とかに外出しする？
const EFFECT_POOL_1 = {
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
		Ball.Rarity.UNCOMMON:	[EffectType.BILLIARDS_LV_UP_ON_SPAWN, 10],
		Ball.Rarity.RARE:		[EffectType.BILLIARDS_LV_UP_ON_SPAWN, 20],
		Ball.Rarity.EPIC:		[EffectType.BILLIARDS_LV_UP_ON_SPAWN, 30],
		Ball.Rarity.LEGENDARY:	[EffectType.BILLIARDS_LV_UP_ON_SPAWN, 50],
	},
	5: {
		Ball.Rarity.UNCOMMON:	[EffectType.BILLIARDS_MERGE_BALLS_ON_SPAWN, 10],
		Ball.Rarity.RARE:		[EffectType.BILLIARDS_MERGE_BALLS_ON_SPAWN, 20],
		Ball.Rarity.EPIC:		[EffectType.BILLIARDS_MERGE_BALLS_ON_SPAWN, 30],
		Ball.Rarity.LEGENDARY:	[EffectType.BILLIARDS_MERGE_BALLS_ON_SPAWN, 50],
	},
	6: {
		Ball.Rarity.UNCOMMON:	[EffectType.LV_UP, 3, 1],
		Ball.Rarity.RARE:		[EffectType.LV_UP, 7, 1],
		Ball.Rarity.EPIC:		[EffectType.LV_UP, 11, 1],
		Ball.Rarity.LEGENDARY:	[EffectType.LV_UP, 15, 1],
	},
	7: {
		Ball.Rarity.UNCOMMON:	[EffectType.LV_UP_2, 1, 2],
		Ball.Rarity.RARE:		[EffectType.LV_UP_2, 2, 2],
		Ball.Rarity.EPIC:		[EffectType.LV_UP_2, 3, 2],
		Ball.Rarity.LEGENDARY:	[EffectType.LV_UP_2, 5, 2],
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
		Ball.Rarity.UNCOMMON:	[EffectType.EXTRA_MAX_SIZE_UP, 2],
		Ball.Rarity.RARE:		[EffectType.EXTRA_MAX_SIZE_UP, 4],
		Ball.Rarity.EPIC:		[EffectType.DECK_MIN_SIZE_DOWN, 1],
		Ball.Rarity.LEGENDARY:	[EffectType.DECK_MIN_SIZE_DOWN, 2],
	},
	15: {
		Ball.Rarity.UNCOMMON:	[EffectType.RARITY_TOP_UP, Ball.Rarity.RARE],
		Ball.Rarity.RARE:		[EffectType.RARITY_TOP_UP, Ball.Rarity.EPIC],
		Ball.Rarity.EPIC:		[EffectType.RARITY_TOP_UP, Ball.Rarity.LEGENDARY],
		Ball.Rarity.LEGENDARY:	[EffectType.RARITY_TOP_DOWN, Ball.Rarity.COMMON],
	},
}
