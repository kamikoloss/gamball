class_name Hole
extends Area2D


# Ball が Hole に落ちたとき (Hole, Ball)
signal ball_entered


const HOLE_SCALE_STEP = 0.5
const GRAVITY_SCALE_STEP = 0.25


enum HoleType {
	BILLIARDS, # (ビリヤード用) パチンコ盤面上に転送する
	EXTRA, # (パチンコ用) EXTRA を1個ビリヤード盤面上に出す + 抽選を行う
	GAIN, # (パチンコ用) 何倍かにして PAYOUT に加算する
	LOST, # 通常使わない 何もしない (失う)
	STACK, # (払い出し用) そのまま BALLS に加算する
}


# 有効かどうか
var is_enabled = true


# 
@export var hole_type: HoleType = HoleType.LOST
# (HoleType.GAIN 用) 増加する倍率
@export var gain_ratio: int = 0


@export var _label: Label
@export var _gravity_area: Area2D
@export var _gravity_texture: TextureRect


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	enable()
	refresh_view()


# 有効化する
func enable() -> void:
	is_enabled = true
	modulate = Color(1, 1, 1, 1)

	# 吸引力を有効化するかどうか
	var gravity_hole_types = [HoleType.BILLIARDS, HoleType.STACK]
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
		Hole.HoleType.BILLIARDS:
			pass
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

	# return しなかった場合:
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

	var maybe_ball = area.get_parent()
	if maybe_ball is Ball:
		ball_entered.emit(self, maybe_ball)
		maybe_ball.queue_free()
