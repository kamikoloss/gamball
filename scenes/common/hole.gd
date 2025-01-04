class_name Hole
extends Area2D


# Ball が Hole に落ちたとき (Hole, Ball)
signal ball_entered


const HOLE_SCALE_STEP: float = 0.5
const GRAVITY_SCALE_STEP: float = 0.25


enum HoleType {
	WARP_TO, # WARP_FROM にワープする
	WARP_FROM, # WARP_TO からワープする
	EXTRA, # (パチンコ用) EXTRA を1個ビリヤード盤面上に出す + 抽選を行う
	GAIN, # (パチンコ用) Ball を gain_ratio 倍にして PAYOUT に加算する
	LOST, # 通常使わない 何もしない (失う)
	STACK, # (払い出し用) そのまま BALLS に加算する
}
enum WarpGroup { NONE, A, B, C, D }


# 有効かどうか
var is_enabled = true


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


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	enable()
	refresh_view()


# 有効化する
func enable() -> void:
	is_enabled = true
	modulate = Color(1, 1, 1, 1)

	# 吸引力を有効化するかどうか
	var gravity_hole_types = [HoleType.WARP_TO, HoleType.STACK]
	if hole_type in gravity_hole_types:
		_gravity_area.gravity_space_override = Area2D.SPACE_OVERRIDE_COMBINE_REPLACE
		_gravity_texture.visible = true
	else:
		_gravity_area.gravity_space_override = Area2D.SPACE_OVERRIDE_DISABLED
		_gravity_texture.visible = false

# 無効化する
func disable() -> void:
	is_enabled = false
	modulate = Color(1, 1, 1, 0.1)
	_gravity_area.gravity_space_override = Area2D.SPACE_OVERRIDE_DISABLED


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


func set_hole_size(level: int = 0) -> void:
	var ratio: float = 1 + HOLE_SCALE_STEP * (level + 1)
	self.scale = Vector2(ratio , ratio)

func set_gravity_size(level: int = 0) -> void:
	var ratio: float = 1 + GRAVITY_SCALE_STEP * (level + 1)
	_gravity_area.scale = Vector2(ratio, ratio)


func _on_area_entered(area: Area2D) -> void:
	if not is_enabled:
		return
	if hole_type == HoleType.WARP_FROM:
		return

	# Ball への作用
	var maybe_ball = area.get_parent()
	if maybe_ball is Ball:
		if not maybe_ball.is_active:
			await maybe_ball.die()
			return 
		if maybe_ball.is_shrinked:
			return
		ball_entered.emit(self, maybe_ball)
		var free_hole_types = [HoleType.STACK, HoleType.GAIN, HoleType.EXTRA, HoleType.LOST] # TODO: GAIN は warp させる
		if hole_type in free_hole_types:
			maybe_ball.die()
