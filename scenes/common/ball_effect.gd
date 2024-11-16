class_name BallEffect
extends Node


enum EffectType {
	# Game
	BREAK_MONEY_UP, # 破壊時に MONEY を増やす
	# Game DECK/EXTRA
	DECK_MIN_SIZE_DOWN, # Ball Deck の最小サイズを減らす
	EXTRA_MAX_SIZE_UP, # Extra Deck の最大サイズを増やす
	# Ball
	BALL_GAIN_UP, # Ball の Gain を増やす
	# Hole
	HOLE_GAIN_UP, # Hole の Gain を増やす
	HOLE_SIZE_UP, # Hole のサイズを大きくする
	HOLE_GRAVITY_UP, # Hole の重力範囲サイズを大きくする
	# Product
	PRODUCT_RARITY_TOP_UP, # 特定レアリティの出現確率が 上がる/下がる
}


# 効果の Title/Description
const EFFECT_DATA = {
}


static func getEffectTitle(level: int, rarity: Ball.Rarity) -> String:
	return ""


static func getEffectDescription(level: int, rarity: Ball.Rarity) -> String:
	return ""
