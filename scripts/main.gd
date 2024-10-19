class_name Main
extends Node


var money: int = 0:
	set(value):
		money = value
		_money_label.text = str(money)
var balls: int = 0:
	set(value):
		balls = value
		_balls_label.text = str(balls)


@export var _money_label: Label
@export var _balls_label: Label


func _ready() -> void:
	money = 0
	balls = 0
