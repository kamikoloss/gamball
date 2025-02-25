class_name Hole
extends Area2D


# Ball が Hole に落ちたとき
signal ball_entered # (hole: Hole, ball: Ball)
# HelpArea ホバー時
signal help_area_hovered # (help_area: HelpArea, hovered: bool)
# HelpArea クリック時
signal help_area_pressed # (help_area: HelpArea)


# Hole のタイプ
enum HoleType {
	EXTRA, # EXTRA を1個ビリヤード盤面上に出す + 抽選を行う
	GAIN, # Ball を gain_ratio 倍にして PAYOUT に加算する
	LOST, # 何もしない (Ball を失う)
	STACK, # TODO: 消す
	WARP_FROM, # WARP_TO からワープしてくる
	WARP_TO, # WARP_FROM にワープする
}
# ワープ元/ワープ先 のグループ
enum WarpGroup { NONE, PAYOUT, A, B, C, D }
# Tween
enum TweenType { FLASH }


const HOLE_SIZE_LEVEL_MAX := 4
const GRAVITY_SIZE_LEVEL_MAX := 4
const HOLE_SCALE_STEP := 0.25
const GRAVITY_SCALE_STEP := 0.25


# Hole の種類
@export var hole_type := HoleType.LOST
# (HoleType.GAIN 用) 増加する倍率
@export var gain_ratio := 0
# (HoleType.WARP_XXXX 用) ワープが通じるグループ
@export var warp_group := WarpGroup.NONE
#
@export var help_area: HelpArea


@export var _gravity_area: Area2D
@export var _gravity_texture: TextureRect
@export var _body_texture: TextureRect
@export var _label: Label


var disabled := false:
	set(v):
		disabled = v
		_refresh_view()
		_refresh_physics()


var _hole_scale_base: Vector2
var _gravity_scale_base: Vector2
var _body_color_base: Color
var _tweens := {}


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	help_area.hovered.connect(func(n, h): help_area_hovered.emit(n, h))
	help_area.pressed.connect(func(n): help_area_pressed.emit(n))

	_hole_scale_base = self.scale
	_gravity_scale_base = _gravity_area.scale
	_body_color_base = _body_texture.self_modulate

	_refresh_view()
	_refresh_physics()


func set_hole_size(level: int = 0) -> void:
	var clamped_level = clampi(level, 0, HOLE_SIZE_LEVEL_MAX)
	var ratio = 1.0 + HOLE_SCALE_STEP * clamped_level
	self.scale = _hole_scale_base * ratio


func set_gravity_size(level: int = 0) -> void:
	var clamped_level = clampi(level, 0, GRAVITY_SIZE_LEVEL_MAX)
	var ratio = 1.0 + GRAVITY_SCALE_STEP * clamped_level
	_gravity_area.scale = _gravity_scale_base * ratio
	_gravity_texture.scale = _gravity_scale_base * ratio


# 点滅する
func flash(count: int, color: Color, duration_ratio: int = 1) -> void:
	var duration = 0.2 * duration_ratio # TODO: const
	var tween = _get_tween(TweenType.FLASH)
	tween.set_loops(count)
	tween.tween_property(_body_texture, "self_modulate", color, 0.0)
	tween.tween_property(_body_texture, "self_modulate", _body_color_base, duration)


func _on_area_entered(area: Area2D) -> void:
	if disabled:
		return
	var white_types = [HoleType.WARP_FROM]
	if hole_type in white_types:
		return

	# Ball
	var maybe_ball = area.get_parent()
	if maybe_ball is Ball:
		ball_entered.emit(self, maybe_ball)


# 自身の見た目を更新する
func _refresh_view() -> void:
	# デフォルト
	_body_texture.self_modulate = ColorPalette.BLACK
	_label.self_modulate = ColorPalette.WHITE

	match hole_type:
		Hole.HoleType.WARP_TO:
			_label.text = WarpGroup.keys()[warp_group]
			_label.self_modulate = ColorPalette.GRAY_60
		Hole.HoleType.WARP_FROM:
			_body_texture.self_modulate = ColorPalette.GRAY_20
			_label.text = WarpGroup.keys()[warp_group]
			_label.self_modulate = ColorPalette.GRAY_60
		Hole.HoleType.EXTRA:
			_body_texture.self_modulate = ColorPalette.SUCCESS
			_label.text = "!!"
		Hole.HoleType.GAIN:
			_label.text = "x%s" % [gain_ratio]
			if gain_ratio <= 0:
				_label.self_modulate = ColorPalette.DANGER
		Hole.HoleType.LOST:
			_label.visible = false
		Hole.HoleType.STACK:
			_label.text = "+"

	# disabled
	if disabled:
		modulate = Color(Color.WHITE, 0.2)
	else:
		modulate = Color(Color.WHITE, 1.0)


# 自身の物理判定を更新する
func _refresh_physics() -> void:
	# 衝突
	set_collision_layer_value(Collision.Layer.BASE, not disabled)

	# 重力
	var gravity_types = [HoleType.WARP_TO, HoleType.STACK]
	if not disabled and hole_type in gravity_types:
		_gravity_area.gravity_space_override = Area2D.SPACE_OVERRIDE_COMBINE_REPLACE
		_gravity_texture.visible = true
	else:
		_gravity_area.gravity_space_override = Area2D.SPACE_OVERRIDE_DISABLED
		_gravity_texture.visible = false


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
