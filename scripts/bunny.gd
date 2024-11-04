class_name Bunny
extends Control

# TODO: 表情を指定して変更する
# TODO: 表情ポーズセットを指定して一括変更する


enum TweenType { Pose }


const POSE_CHANGE_DURATION = 0.0 # A/B のフェードの秒数
const POSE_MOVE_DURATION_UP = 0.1 # 跳ねるときの上昇時の秒数
const POSE_MOVE_DURATION_DOWN = 0.3 # 跳ねるときの下降時の秒数
const POSE_MOVE_POSITION_DIFF = Vector2(0, -20) # どれぐらい跳ねるか


@export_category("Pose A")
@export var _pose_a: Control
@export var _pose_a_parts_1: TextureRect
@export var _pose_a_parts_2: TextureRect
@export var _pose_a_parts_3: TextureRect
@export var _pose_a_parts_4: TextureRect
@export_category("Pose B")
@export var _pose_b: Control
@export var _pose_b_parts_1: TextureRect
@export var _pose_b_parts_2: TextureRect
@export var _pose_b_parts_3: TextureRect
@export var _pose_b_parts_4: TextureRect
@export_category("Texutres")
@export var _parts_1_textures: Array[Texture]
@export var _parts_2_textures: Array[Texture]
@export var _parts_3_textures: Array[Texture]
@export var _parts_4_textures: Array[Texture]


# { TweenType: Tween, ... } 
var _tweens: Dictionary = {}
# 現在どちらのポーズ表示を使用しているか 交互に切り替える
var _is_pose_a = true

var _pose_move_position_from: Vector2
var _pose_move_position_to: Vector2


func _ready() -> void:
	_pose_move_position_from = position
	_pose_move_position_to = position + POSE_MOVE_POSITION_DIFF
	show_default_pose()


# デフォルトのポーズを表示する
func show_default_pose() -> void:
	_pose_a.visible = true
	_pose_b.visible = true
	_pose_a.modulate = Color.WHITE
	_pose_b.modulate = Color.TRANSPARENT
	_set_textures([0, 0, 0, 0])


# ポーズをランダムに変更する
# 前と同じポーズが選択されたときは変わっていないように見えることもある
# TODO: 必ず変える？
func show_random_pose() -> void:
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

	# 全体を跳ねさせる
	position = _pose_move_position_from
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", _pose_move_position_to, POSE_MOVE_DURATION_UP)
	tween.chain() # ここまでパラレル
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position", _pose_move_position_from, POSE_MOVE_DURATION_DOWN)

	# 次回以降の A/B を切り替える
	tween.tween_callback(func(): _is_pose_a = not _is_pose_a)


func _set_random_textures() -> void:
	var index_1 = randi_range(0, _parts_1_textures.size() - 1)
	var index_2 = randi_range(0, _parts_2_textures.size() - 1)
	var index_3 = randi_range(0, _parts_3_textures.size() - 1)
	var index_4 = randi_range(0, _parts_4_textures.size() - 1)
	_set_textures([index_1, index_2, index_3, index_4])


func _set_textures(parts_index_list: Array[int]) -> void:
	print("[Bunny] _set_textures(%s)" % [parts_index_list])
	var pose_parts_list = []
	if _is_pose_a:
		pose_parts_list = [_pose_a_parts_1, _pose_a_parts_2, _pose_a_parts_3, _pose_a_parts_4]
	else:
		pose_parts_list = [_pose_b_parts_1, _pose_b_parts_2, _pose_b_parts_3, _pose_b_parts_4]

	var parts_textures_list = [_parts_1_textures, _parts_2_textures, _parts_3_textures, _parts_4_textures]

	var key = 0
	for index in parts_index_list:

		var pose_parts: TextureRect = pose_parts_list[key]
		var parts_textures: Array[Texture] = parts_textures_list[key]
		# Texture が存在しない場合
		if parts_textures.size() <= index or index < 0:
			pose_parts.visible = false
		# Texture が存在する場合
		else:
			pose_parts.visible = true
			pose_parts.texture = parts_textures[index]
		key += 1

func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
