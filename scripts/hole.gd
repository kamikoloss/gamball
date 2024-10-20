class_name Hole
extends Area2D


# Ball が Hole に落ちたとき (Hole, Ball)
signal ball_entered


enum HoleType {
	Billiards,
	Gain,
	Lost,
	Stack,
}


@export var hole_type: HoleType = HoleType.Lost
@export var gain_ratio: int = 0 # 増加する倍率

@export var _label: Label


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_init_view()


func _on_area_entered(area: Area2D) -> void:
	var maybe_ball = area.get_parent()
	if maybe_ball is Ball:
		ball_entered.emit(self, maybe_ball)
		maybe_ball.queue_free()


# 自身の見た目を決定する
func _init_view() -> void:
	match hole_type:
		Hole.HoleType.Billiards:
			pass
		Hole.HoleType.Gain:
			_label.text = "×%s" % [gain_ratio]
			if gain_ratio == 0:
				_label.self_modulate = Color.RED
			return
		Hole.HoleType.Lost:
			pass
		Hole.HoleType.Stack:
			pass
	
	_label.visible = false
