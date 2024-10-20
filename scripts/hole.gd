class_name Hole
extends Area2D


# Ball が Hole に落ちたとき (Hole: 落ちた Hole, Ball: 落ちた Ball)
signal ball_entered


enum HoleType {
	Billiards,
	Extra,
	Gain,
	Lost,
	Stack,
}


@export var hole_type: HoleType = HoleType.Lost
@export var gain_ratio: int = 0 # 増加する倍率

@export var _label: Label


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	refresh_view()


func _on_area_entered(area: Area2D) -> void:
	var maybe_ball = area.get_parent()
	if maybe_ball is Ball:
		ball_entered.emit(self, maybe_ball)
		maybe_ball.queue_free()


# 自身の見た目を更新する
func refresh_view() -> void:
	match hole_type:
		Hole.HoleType.Billiards:
			pass
		Hole.HoleType.Extra:
			_label.text = "EX"
			_label.self_modulate = Color.GREEN
			return
		Hole.HoleType.Gain:
			_label.text = "×%s" % [gain_ratio]
			if gain_ratio <= 0:
				_label.self_modulate = Color.RED
			return
		Hole.HoleType.Lost:
			pass
		Hole.HoleType.Stack:
			_label.text = "＋"
			return
	_label.visible = false
