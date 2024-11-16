class_name BallEffect
extends Node


# TODO: 命名のルール欲しいかも？
enum EffectType {
	# Game
	MONEY_UP_ON_BREAK, # (a) 破壊時に MONEY xa
	MONEY_UP_ON_FALL, # (a) 落下時に MONEY +a
	DECK_MIN_SIZE_DOWN, # (a) Deck の最小サイズ -a
	DECK_COMPLETE_GAIN_UP, # (a, b) Deck に LV 0-a が揃っているとき Gain xb
	DECK_COUNT_GAIN_UP, # (a, b) Deck の Ball が a 個以下のとき Gain +b
	EXTRA_MAX_SIZE_UP, # (a) Extra の最大サイズ +a
	RARITY_TOP_UP, RARITY_TOP_DOWN, # (r) レアリティ r の出現確率が 上がる/下がる
	TAX_DOWN, # (a) 延長料 -a%
	# Game/Billiards
	BILLIARDS_COUNT_GAIN_UP, # (a, b) ビリヤード盤面上の Ball が a 個以下のとき Gain +b
	BILLIARDS_COUNT_GAIN_UP_2, # (a, b) ビリヤード盤面上の Ball が a 個以下のとき Gain xb
	BILLIARDS_LV_UP_ON_SPAWN, # (a) 出現時にビリヤード盤面上の Ball LV +a
	BILLIARDS_MERGE_BALLS_ON_SPAWN, # (a, b) 出現時にビリヤード顔面上の Ball LV a xb を LV 15 x1 に変換する
	# Game/Pachinko
	PACHINKO_START_TOP_UP, # (a) パチンコの初当たり確率の分子 +a
	PACHINKO_CONTINUE_TOP_UP, # (a) パチンコの継続確率の分子 +a
	# Ball
	LV_UP, # (a, b) LV a 以下の Ball の LV +b
	LV_UP_2, # (a, b) LV a の Ball の LV xb
	# Hole
	HOLE_GAIN_UP, # (a) Hole の Gain +a
	HOLE_SIZE_UP, # (a) Hole のサイズ xa
	HOLE_GRAVITY_SIZE_UP, # (a) Hole の重力範囲サイズ xa
}


# 効果の説明文
const EFFECT_TEMPLATE = {
	EffectType.MONEY_UP_ON_BREAK: "",
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
