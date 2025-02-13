class_name ColorPalette
extends Object


# Util
const WHITE :=		Color(0.95, 0.95, 0.95)
const BLACK :=		Color(0.05, 0.05, 0.05)
const GRAY_20 :=	Color(0.8, 0.8, 0.8)
const GRAY_40 :=	Color(0.6, 0.6, 0.6)
const GRAY_60 :=	Color(0.4, 0.4, 0.4)
const GRAY_80 :=	Color(0.2, 0.2, 0.2)

# Theme
const PRIMARY := 	Color("#f5f759")
const SECONDARY := 	Color("#eb3d00")
const SUCCESS := 	Color("#03432d")
const DANGER := 	Color("#f53921")

# Rarity
const COMMON := 	Color("#f4ffea")
const UNCOMMON := 	Color("#4f7454")
const RARE := 		Color("#01a158")
const EPIC := 		Color("#f77660")
const LEGENDARY := 	Color("#b19e4c")

# Ball
const BALL_RARITY_COLORS := {
	Ball.Rarity.COMMON: COMMON,
	Ball.Rarity.UNCOMMON: UNCOMMON,
	Ball.Rarity.RARE: RARE,
	Ball.Rarity.EPIC: EPIC,
	Ball.Rarity.LEGENDARY: LEGENDARY,
}
