class_name Bunny
extends Control

# TODO: 表情を指定して変更する
# TODO: 表情ポーズセットを指定して一括変更する


enum TweenType { Pose }


const POSE_CHANGE_DURATION = 0
const POSE_MOVE_DURATION = 0.2
const POSE_MOVE_POSITION_DIFF = Vector2(0, -20) # どれぐらい跳ねるか


@export var _pose_a: Control
@export var _face_a: TextureRect
@export var _hand_left_a: TextureRect
@export var _hand_right_a: TextureRect
@export var _pose_b: Control
@export var _face_b: TextureRect
@export var _hand_left_b: TextureRect
@export var _hand_right_b: TextureRect

@export var _face_texures: Array[Texture]
@export var _hand_left_textures: Array[Texture]
@export var _hand_right_textures: Array[Texture]


# { TweenType: Tween, ... } 
var _tweens: Dictionary = {}
# 現在どちらのポーズ表示を使用しているか 交互に切り替える
var _is_pose_a = true

var _pose_move_position_from: Vector2
var _pose_move_position_to: Vector2


func _ready() -> void:
	_pose_move_position_from = position
	_pose_move_position_to = position + POSE_MOVE_POSITION_DIFF

	_pose_a.visible = true
	_pose_b.visible = true
	_pose_a.modulate = Color.WHITE
	_pose_b.modulate = Color.TRANSPARENT
	show_default_pose()


# デフォルトのポーズを表示する
func show_default_pose() -> void:
	if _is_pose_a:
		_face_a.texture = _face_texures[0]
		_hand_left_a.texture = _hand_left_textures[0]
		_hand_right_a.texture = _hand_right_textures[0]
	else:
		_face_b.texture = _face_texures[0]
		_hand_left_b.texture = _hand_left_textures[0]
		_hand_right_b.texture = _hand_right_textures[0]


# ポーズをランダムに変更する
# 前と同じポーズが選択されたときは変わっていないように見えることもある
# TODO: 必ず変える？
func shuffle_pose() -> void:
	var tween = _get_tween(TweenType.Pose)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	# A/B のポーズをランダムに変更する
	_set_random_textures()

	# A/B の表示を切り替える
	if _is_pose_a:
		tween.tween_property(_pose_a, "modulate", Color.TRANSPARENT, POSE_CHANGE_DURATION) # A を透明にする
		tween.tween_property(_pose_b, "modulate", Color.WHITE, POSE_CHANGE_DURATION) # B を表示する
	else:
		tween.tween_property(_pose_b, "modulate", Color.TRANSPARENT, POSE_CHANGE_DURATION) # B を透明にする
		tween.tween_property(_pose_a, "modulate", Color.WHITE, POSE_CHANGE_DURATION) # A を表示する

	# 跳ねさせる
	position = _pose_move_position_from
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", _pose_move_position_to, POSE_MOVE_DURATION / 2) 
	tween.chain()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", _pose_move_position_from, POSE_MOVE_DURATION / 2) 

	# 次回以降の動作対象を切り替える
	tween.tween_callback(func(): _is_pose_a = not _is_pose_a)


# TODO: set だけメソッド切り出してランダムはラップする
func _set_random_textures() -> void:
	if not _is_pose_a:
		_face_a.texture = _face_texures.pick_random()
		_hand_left_a.texture = _hand_left_textures.pick_random()
		_hand_right_a.texture = _hand_right_textures.pick_random()
	else:
		_face_b.texture = _face_texures.pick_random()
		_hand_left_b.texture = _hand_left_textures.pick_random()
		_hand_right_b.texture = _hand_right_textures.pick_random()


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
