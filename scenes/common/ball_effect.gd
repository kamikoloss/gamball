class_name BallEffect
extends Node


enum EffectType {
	# Game
	BREAK_MONEY_UP, # 破壊時に MONEY を増やす
	FALL_MONEY_UP, # ビリヤード Hole 落下時に MONEY を増やす
	DECK_MIN_SIZE_DOWN, # Ball Deck の最小サイズを減らす
	EXTRA_MAX_SIZE_UP, # Extra Deck の最大サイズを増やす
	RARITY_TOP_UP, RARITY_TOP_DOWN, # 特定レアリティの出現確率が 上がる/下がる
	TAX_OFF, # 延長料が下がる
	# Game/Pachinko
	PACHINKO_START_TOP_UP, # パチンコの初当たり確率が上がる
	PACHINKO_CONTINUE_TOP_UP, # パチンコの継続確率が上がる
	# Ball
	BALL_GAIN_UP, # LV n 以下の Ball の LV を増やす
	BALL_GAIN_UP_2, # LV n の Ball の LV を増やす
	# Hole
	HOLE_GAIN_UP, # Hole の Gain を増やす
	HOLE_SIZE_UP, # Hole のサイズを大きくする
	HOLE_GRAVITY_SIZE_UP, # Hole の重力範囲サイズを大きくする
}


# 効果の タイトル/説明文
const EFFECT_TEMPLATE = {
	EffectType.BREAK_MONEY_UP: [
		"",
		"",
	],
}

# Ball LV/Rarity ごとの初期効果
# { <Ball LV>: { <Ball Rarity>: [ <EffectType>, param1, (param2) ], ... } }
const EFFECT_POOL_1 = {
	0: {
		Ball.Rarity.UNCOMMON:	[EffectType.BREAK_MONEY_UP, 2],
		Ball.Rarity.RARE:		[EffectType.BREAK_MONEY_UP, 3],
		Ball.Rarity.EPIC:		[EffectType.BREAK_MONEY_UP, 5],
		Ball.Rarity.LEGENDARY:	[EffectType.BREAK_MONEY_UP, 10],
	},
	1: {
		Ball.Rarity.UNCOMMON:	[EffectType.FALL_MONEY_UP, 20],
		Ball.Rarity.RARE:		[EffectType.BREAK_MONEY_UP, 30],
		Ball.Rarity.EPIC:		[EffectType.BREAK_MONEY_UP, 50],
		Ball.Rarity.LEGENDARY:	[EffectType.BREAK_MONEY_UP, 100],
	},
	2: {
		Ball.Rarity.UNCOMMON:	[EffectType.TAX_OFF, 10],
		Ball.Rarity.RARE:		[EffectType.TAX_OFF, 20],
		Ball.Rarity.EPIC:		[EffectType.TAX_OFF, 30],
		Ball.Rarity.LEGENDARY:	[EffectType.TAX_OFF, 50],
	},
	3: {},
	4: {},
	5: {},
	6: {
		Ball.Rarity.UNCOMMON:	[EffectType.BALL_GAIN_UP, 3, 1],
		Ball.Rarity.RARE:		[EffectType.BALL_GAIN_UP, 7, 1],
		Ball.Rarity.EPIC:		[EffectType.BALL_GAIN_UP, 11, 1],
		Ball.Rarity.LEGENDARY:	[EffectType.BALL_GAIN_UP, 15, 1],
	},
	7: {
		Ball.Rarity.UNCOMMON:	[EffectType.BALL_GAIN_UP_2, 1, 2],
		Ball.Rarity.RARE:		[EffectType.BALL_GAIN_UP_2, 2, 2],
		Ball.Rarity.EPIC:		[EffectType.BALL_GAIN_UP_2, 3, 2],
		Ball.Rarity.LEGENDARY:	[EffectType.BALL_GAIN_UP_2, 5, 2],
	},
	8: {
		
	},
	9: {
		
	},
	10: {
		Ball.Rarity.UNCOMMON:	[EffectType.PACHINKO_CONTINUE_TOP_UP, 1],
		Ball.Rarity.RARE:		[EffectType.PACHINKO_CONTINUE_TOP_UP, 2],
		Ball.Rarity.EPIC:		[EffectType.PACHINKO_START_TOP_UP, 1],
		Ball.Rarity.LEGENDARY:	[EffectType.PACHINKO_START_TOP_UP, 2],
	},
	11: {
		
	},
	12: {
		
	},
	13: {
		
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


static func getEffectTitle(level: int, rarity: Ball.Rarity) -> String:
	return ""


static func getEffectDescription(level: int, rarity: Ball.Rarity) -> String:
	return ""
