#class_name CameraManager
extends Node


# カメラ移動座標
const CAMERA_POSITION_FROM: Vector2 = Vector2(640, 360)
const CAMERA_POSITION_LEFT_TO: Vector2 = Vector2(-640, 360)
const CAMERA_POSITION_RIGHT_TO: Vector2 = Vector2(1920, 360)
const CAMERA_MOVE_DURATION: float = 1.0


var _tween: Tween


func show_main() -> void:
	var camera = get_viewport().get_camera_2d()
	var tween = _get_tween()
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "position", CAMERA_POSITION_FROM, CAMERA_MOVE_DURATION)

func show_config() -> void:
	var camera = get_viewport().get_camera_2d()
	var tween = _get_tween()
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "position", CAMERA_POSITION_LEFT_TO, CAMERA_MOVE_DURATION)

func show_info() -> void:
	var camera = get_viewport().get_camera_2d()
	var tween = _get_tween()
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "position", CAMERA_POSITION_RIGHT_TO, CAMERA_MOVE_DURATION)


func _get_tween() -> Tween:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	return _tween
