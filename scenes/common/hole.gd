class_name Hole
extends Area2D


# Ball が Hole に落ちたとき (Hole, Ball)
signal ball_entered


enum HoleType {
	EXTRA, # EXTRA を1個ビリヤード盤面上に出す + 抽選を行う
	GAIN, # Ball を gain_ratio 倍にして PAYOUT に加算する
	LOST, # 何もしない (Ball を失う)
	STACK, # BALLS に加算する
	WARP_FROM, # WARP_TO からワープする
	WARP_TO, # WARP_FROM にワープする
}
enum WarpGroup { NONE, A, B, C, D }


const HOLE_SIZE_LEVEL_MAX: int = 4
const GRAVITY_SIZE_LEVEL_MAX: int = 4
const HOLE_SCALE_STEP: float = 0.25
const GRAVITY_SCALE_STEP: float = 0.25


# Hole の種類
@export var hole_type: HoleType = HoleType.LOST
# (HoleType.GAIN 用) 増加する倍率
@export var gain_ratio: int = 0
# (HoleType.WARP_XXXX 用) ワープが通じるグループ
@export var warp_group: WarpGroup = WarpGroup.NONE


@export var _gravity_area: Area2D
@export var _gravity_texture: TextureRect
@export var _body_texture: TextureRect
@export var _label: Label


# 有効かどうか
var is_enabled = true


var _hole_scale_base: Vector2
var _gravity_scale_base: Vector2


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_hole_scale_base = self.scale
	_gravity_scale_base = _gravity_area.scale

	enable()
	refresh_view()
	refresh_physics()


# 有効化する
func enable() -> void:
	is_enabled = true
	modulate = Color(1, 1, 1, 1)
	refresh_physics()

# 無効化する
func disable() -> void:
	is_enabled = false
	modulate = Color(1, 1, 1, 0.1)
	refresh_physics()


# 自身の見た目を更新する
func refresh_view() -> void:
	match hole_type:
		Hole.HoleType.WARP_TO:
			_label.text = "%s>" % [WarpGroup.keys()[warp_group]]
			return
		Hole.HoleType.WARP_FROM:
			_label.text = ">%s" % [WarpGroup.keys()[warp_group]]
			_body_texture.self_modulate = Color(0.9, 0.9, 0.9)
			_label.self_modulate = Color.BLACK
			return
		Hole.HoleType.EXTRA:
			_label.text = "EX"
			_label.self_modulate = Color.GREEN
			return
		Hole.HoleType.GAIN:
			_label.text = "×%s" % [gain_ratio]
			if gain_ratio <= 0:
				_label.self_modulate = Color.RED
			return
		Hole.HoleType.LOST:
			pass
		Hole.HoleType.STACK:
			_label.text = "＋"
			return
	# return しなかった場合: Label を非表示にする
	_label.visible = false


# 自身の物理判定を更新する
func refresh_physics() -> void:
	# 衝突
	set_collision_layer_value(Collision.Layer.BASE, is_enabled)

	# 重力
	var gravity_types = [HoleType.WARP_TO, HoleType.STACK]
	if is_enabled and hole_type in gravity_types:
		_gravity_area.gravity_space_override = Area2D.SPACE_OVERRIDE_COMBINE_REPLACE
		_gravity_texture.visible = true
	else:
		_gravity_area.gravity_space_override = Area2D.SPACE_OVERRIDE_DISABLED
		_gravity_texture.visible = false


func set_hole_size(level: int = 0) -> void:
	var clamped_level = clampi(level, 0, HOLE_SIZE_LEVEL_MAX)
	var ratio: float = 1.0 + HOLE_SCALE_STEP * clamped_level
	self.scale = _hole_scale_base * ratio


func set_gravity_size(level: int = 0) -> void:
	var clamped_level = clampi(level, 0, GRAVITY_SIZE_LEVEL_MAX)
	var ratio: float = 1.0 + GRAVITY_SCALE_STEP * clamped_level
	_gravity_area.scale = _gravity_scale_base * ratio
	_gravity_texture.scale = _gravity_scale_base * ratio


func _on_area_entered(area: Area2D) -> void:
	if not is_enabled:
		return
	var white_types = [HoleType.WARP_FROM]
	if hole_type in white_types:
		return

	# Ball
	var maybe_ball = area.get_parent()
	if maybe_ball is Ball:
		ball_entered.emit(self, maybe_ball)
