class_name DragShooter
extends Area2D


# ドラッグを開始したときに発火する
signal pressed
# ドラッグを終了したときに発火する
signal released # (drag_vector: Vector2)
# ドラッグの距離が足りずにキャンセルされたときに発火する
signal canceled


# ドラッグの最小距離 (px)
# これ未満の場合はキャンセル扱いになる
const DRAG_LENGTH_MIN := 10.0
# ドラッグの最大距離 (px)
const DRAG_LENGTH_MAX := 100.0


@export var _arrow: Control
@export var _arrow_square: TextureRect
@export var _drag_point: Control


var disabled := true:
	set(v):
		disabled = v
		# ドラッグ中に無効になった場合: キャンセル扱いにする
		if disabled and _is_dragging:
			_is_dragging = false
			_hide_drag_point()
			_hide_arrow()
			canceled.emit()


# 現在ドラッグ中かどうか
var _is_dragging := false
# ドラッグを開始した座標
var _drag_position_from: Vector2
# 現在ドラッグしている座標
var _drag_position_to: Vector2


func _ready() -> void:
	_hide_arrow()
	_hide_drag_point()

	_drag_point.modulate = ColorPalette.PRIMARY


func _input(event: InputEvent) -> void:
	if disabled or not _is_dragging:
		return

	# 左クリックを離したとき
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_is_dragging = false
		_hide_drag_point()
		_hide_arrow()

		# ドラッグの距離を算出して丸める
		var drag_vector = Vector2.ZERO
		var clamped_length = 0
		if _drag_position_to != Vector2.ZERO:
			drag_vector = _drag_position_from - _drag_position_to
			clamped_length = clampf(drag_vector.length(), 0, DRAG_LENGTH_MAX)
		var drag_vector_clamped = drag_vector.normalized() * clamped_length

		# ドラッグの距離が充分な場合
		if DRAG_LENGTH_MIN < clamped_length:
			released.emit(drag_vector_clamped)
			#print("[DragShooter] released.")
		# ドラッグの距離が充分でない場合
		else:
			canceled.emit()
			#print("[DragShooter] canceled.")

	# マウス動作
	if event is InputEventMouseMotion:
		# ドラッグしている間
		if _is_dragging:
			_drag_position_to = event.position
			var drag_vector = _drag_position_from - _drag_position_to
			var clamped_length =  clampf(drag_vector.length(), 0, DRAG_LENGTH_MAX)
			var deg = rad_to_deg(drag_vector.angle()) + 90
			var scale = (clamped_length / DRAG_LENGTH_MAX) * 10 # scale 10 が最大
			_update_arrow(deg, scale)


func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if disabled or _is_dragging:
		return

	# 左クリックを押したとき
	# NOTE: Area2D の範囲内に限定するために _input_event() 内に実装している
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_is_dragging = true
		_drag_position_from = event.position
		_drag_position_to = Vector2.ZERO
		_show_drag_point(_drag_position_from)
		_show_arrow()
		pressed.emit()
		#print("[DragShooter] pressed.")


func _show_arrow() -> void:
	_arrow.visible = true

func _hide_arrow() -> void:
	_arrow.visible = false
	_arrow_square.scale.y = 0
	_drag_point.visible = false

func _update_arrow(deg: int, scale: float) -> void:
	_arrow.rotation_degrees = deg
	_arrow_square.scale.y = scale


func _show_drag_point(position: Vector2) -> void:
	_drag_point.visible = true
	_drag_point.global_position = position

func _hide_drag_point() -> void:
	_drag_point.visible = false
