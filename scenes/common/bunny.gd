class_name Bunny
extends Control
# TODO: 表情を指定して変更する
# TODO: 表情ポーズセットを指定して一括変更する


signal pressed


enum TweenType { POSE, JUMP }
enum SizeType { SMALL, LARGE }


# A/B のフェードの秒数
const POSE_CHANGE_DURATION := 0.2

# 跳ねるときの 上昇/下降 時の秒数
const JUMP_DURATION_UP := 0.1
const JUMP_DURATION_DOWN := 0.3
# 跳ねるときの最高座標の相対位置
const JUMP_POSITION_DIFF := Vector2(0, -20)


@export var _touch_button: TextureButton

@export_category("Human")
@export var _human: Control
@export var _pose_base: TextureRect
@export var _pose_a: Control
@export var _pose_a_parts_1: TextureRect
@export var _pose_a_parts_2: TextureRect
@export var _pose_a_parts_3: TextureRect
@export var _pose_a_parts_4: TextureRect
@export var _pose_b: Control
@export var _pose_b_parts_1: TextureRect
@export var _pose_b_parts_2: TextureRect
@export var _pose_b_parts_3: TextureRect
@export var _pose_b_parts_4: TextureRect

@export_category("Texutres")
@export var _base_texture: Texture
@export var _parts_1_textures: Array[Texture]
@export var _parts_2_textures: Array[Texture]
@export var _parts_3_textures: Array[Texture]
@export var _parts_4_textures: Array[Texture]


var size_type := SizeType.SMALL:
	set(v):
		size_type = v
		match size_type:
			SizeType.SMALL:
				_human.scale = Vector2(0.6, 0.6)
				z_index = -10
			SizeType.LARGE:
				_human.scale = Vector2(1.0, 1.0)
				z_index = 0
var disabled = false:
	set(v):
		disabled = v
		_touch_button.disabled = disabled


# 現在 A/B のどちらを表示しているか (A が表か)
var _is_pose_a := true

# 跳ねるときの 初期位置/頂点位置
var _human_move_position_from: Vector2
var _human_move_position_to: Vector2

var _tweens := {}


func _ready() -> void:
	_touch_button.pressed.connect(func(): pressed.emit())

	size_type = SizeType.SMALL
	_human_move_position_from = _human.position
	_human_move_position_to = _human.position + JUMP_POSITION_DIFF

	# TODO: 複数の _base_texture への対応
	if _base_texture:
		_pose_base.texture = _base_texture
		_pose_base.visible = true
	else:
		_pose_base.visible = false
	_pose_a.visible = true
	_pose_b.visible = true
	_pose_a.modulate = Color.WHITE
	_pose_b.modulate = Color.TRANSPARENT
	_reset_pose()


# ポーズをランダムなものに変更する
# 前と同じポーズが選択されたときは変わっていないように見えることもある
# TODO: 必ず変える？
func shuffle_pose() -> void:
	# 裏のポーズをランダムに変更する
	_is_pose_a = not _is_pose_a
	_update_textures_random()
	_is_pose_a = not _is_pose_a

	# 表を透明にする + 裏を不透明にする
	var tween = _get_tween(TweenType.POSE)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	if _is_pose_a:
		tween.tween_property(_pose_a, "modulate", Color.TRANSPARENT, POSE_CHANGE_DURATION)
		tween.tween_property(_pose_b, "modulate", Color.WHITE, POSE_CHANGE_DURATION)
	else:
		tween.tween_property(_pose_b, "modulate", Color.TRANSPARENT, POSE_CHANGE_DURATION)
		tween.tween_property(_pose_a, "modulate", Color.WHITE, POSE_CHANGE_DURATION)
	# 次回以降の 表/裏 を切り替える
	tween.tween_callback(func(): _is_pose_a = not _is_pose_a)


# 全体を跳ねさせる
func jump() -> void:
	var tween = _get_tween(TweenType.JUMP)
	_human.position = _human_move_position_from
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(_human, "position", _human_move_position_to, JUMP_DURATION_UP)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(_human, "position", _human_move_position_from, JUMP_DURATION_DOWN)


func _update_textures(parts_index_list: Array[int]) -> void:
	#print("[Bunny] _change_textures(parts_index_list: %s)" % [parts_index_list])
	var pose_parts_list = []
	if _is_pose_a:
		pose_parts_list = [_pose_a_parts_1, _pose_a_parts_2, _pose_a_parts_3, _pose_a_parts_4]
	else:
		pose_parts_list = [_pose_b_parts_1, _pose_b_parts_2, _pose_b_parts_3, _pose_b_parts_4]

	var parts_textures_list = [_parts_1_textures, _parts_2_textures, _parts_3_textures, _parts_4_textures]

	var i = 0
	for index in parts_index_list:
		var pose_parts: TextureRect = pose_parts_list[i]
		var parts_textures: Array[Texture] = parts_textures_list[i]
		# Texture が存在しない場合
		if (parts_textures.size() - 1) < index:
			pose_parts.visible = false
		# Texture が存在する場合
		else:
			pose_parts.visible = true
			pose_parts.texture = parts_textures[index]
		i += 1


func _update_textures_random() -> void:
	var index_1 = clampi(randi_range(0, _parts_1_textures.size() - 1), 0, 99)
	var index_2 = clampi(randi_range(0, _parts_2_textures.size() - 1), 0, 99)
	var index_3 = clampi(randi_range(0, _parts_3_textures.size() - 1), 0, 99)
	var index_4 = clampi(randi_range(0, _parts_4_textures.size() - 1), 0, 99)
	_update_textures([index_1, index_2, index_3, index_4])


func _reset_pose() -> void:
	_is_pose_a = not _is_pose_a
	_update_textures([0, 0, 0, 0])
	_is_pose_a = not _is_pose_a
	_update_textures([0, 0, 0, 0])


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
