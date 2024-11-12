class_name Bunny
extends Control

# TODO: 表情を指定して変更する
# TODO: 表情ポーズセットを指定して一括変更する


enum TweenType { Pose, Dialogue }


const POSE_CHANGE_DURATION = 0.0 # A/B のフェードの秒数
const POSE_MOVE_DURATION_UP = 0.1 # 跳ねるときの上昇時の秒数
const POSE_MOVE_DURATION_DOWN = 0.3 # 跳ねるときの下降時の秒数
const POSE_MOVE_POSITION_DIFF = Vector2(0, -20) # どれぐらい跳ねるか


@export var _human: Control
@export var _base_parts: TextureRect
@export var _touch_button: TextureButton

@export_category("Human")
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

@export_category("Bubble")
@export var _dialogue_label: Label
@export var _dialogue_big_label: Label

@export_category("Texutres")
@export var _base_texture: Texture
@export var _parts_1_textures: Array[Texture]
@export var _parts_2_textures: Array[Texture]
@export var _parts_3_textures: Array[Texture]
@export var _parts_4_textures: Array[Texture]


var _is_human_pose_a = true # 現在どちらのポーズ表示を使用しているか 交互に切り替える
var _human_move_position_from: Vector2 # 跳ねるときの初期位置
var _human_move_position_to: Vector2 # 跳ねるときの頂点位置

var _tweens: Dictionary = {} # { TweenType: Tween, ... } 


func _ready() -> void:
	_touch_button.pressed.connect(_on_touch_button_pressed)

	_human_move_position_from = _human.position
	_human_move_position_to = _human.position + POSE_MOVE_POSITION_DIFF

	if _base_texture:
		_base_parts.texture = _base_texture
		_base_parts.visible = true
	else:
		_base_parts.visible = false

	_pose_a.visible = true
	_pose_b.visible = true
	_pose_a.modulate = Color.WHITE
	_pose_b.modulate = Color.TRANSPARENT

	reset_pose()
	refresh_dialogue_label("")


# ポーズをデフォルトに変更する
func reset_pose() -> void:
	_refresh_textures([0, 0, 0, 0])
	_is_human_pose_a = not _is_human_pose_a
	_refresh_textures([0, 0, 0, 0])
	_is_human_pose_a = not _is_human_pose_a


# ポーズをランダムなものに変更する
# 前と同じポーズが選択されたときは変わっていないように見えることもある
# TODO: 必ず変える？
# TODO: 跳ねる処理を切り分ける？
func shuffle_pose() -> void:
	var tween = _get_tween(TweenType.Pose)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	# A/B のポーズをランダムに変更する
	_refresh_textures_random()

	# A/B の表示を切り替える
	if _is_human_pose_a:
		tween.tween_property(_pose_a, "modulate", Color.TRANSPARENT, POSE_CHANGE_DURATION) # A を透明にする
		tween.tween_property(_pose_b, "modulate", Color.WHITE, POSE_CHANGE_DURATION) # B を表示する
	else:
		tween.tween_property(_pose_b, "modulate", Color.TRANSPARENT, POSE_CHANGE_DURATION) # B を透明にする
		tween.tween_property(_pose_a, "modulate", Color.WHITE, POSE_CHANGE_DURATION) # A を表示する

	# 全体を跳ねさせる
	_human.position = _human_move_position_from
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(_human, "position", _human_move_position_to, POSE_MOVE_DURATION_UP)
	tween.chain() # ここまでパラレル
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(_human, "position", _human_move_position_from, POSE_MOVE_DURATION_DOWN)

	# 次回以降の A/B を切り替える
	tween.tween_callback(func(): _is_human_pose_a = not _is_human_pose_a)


func refresh_dialogue_label(dialogue: String) -> void:
	var tween = _get_tween(TweenType.Dialogue)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(_dialogue_label, "modulate", Color.TRANSPARENT, 0.2) # 表示を消す
	tween.tween_property(_dialogue_big_label, "modulate", Color.TRANSPARENT, 0.2) # 表示を消す
	tween.chain()
	tween.tween_callback(func(): _dialogue_label.text = dialogue) # セリフを変える
	tween.tween_property(_dialogue_label, "modulate", Color.WHITE, 0.2) # 対象の label だけ表示を戻す

func refresh_dialogue_big_label(dialogue: String) -> void:
	var tween = _get_tween(TweenType.Dialogue)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(_dialogue_label, "modulate", Color.TRANSPARENT, 0.2) # 表示を消す
	tween.tween_property(_dialogue_big_label, "modulate", Color.TRANSPARENT, 0.2) # 表示を消す
	tween.chain()
	tween.tween_callback(func(): _dialogue_big_label.text = dialogue) # セリフを変える
	tween.tween_property(_dialogue_big_label, "modulate", Color.WHITE, 0.2) # 対象の label だけ表示を戻す


func enable_touch() -> void:
	_touch_button.disabled = false

func disable_touch() -> void:
	_touch_button.disabled = true


func _on_touch_button_pressed() -> void:
	# セリフをランダムに変更する
	# TODO: JSON に逃がす
	var dialogue_list = [
		"GAMBALL は近未来のバーチャルハイリスクハイリターンギャンブルだよ！",
		"ビリヤードポケットに入った玉はパチンコ盤面上に出現するよ。",
		"水色の??玉が他の玉にぶつかる前にビリヤードポケットに落ちるとなくなるから気をつけてね！",
	]
	refresh_dialogue_label(dialogue_list.pick_random())

	# ポーズをランダムに変更する
	shuffle_pose()


func _refresh_textures(parts_index_list: Array[int]) -> void:
	#print("[Bunny] _set_textures(%s)" % [parts_index_list])
	var pose_parts_list = []
	if _is_human_pose_a:
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


func _refresh_textures_random() -> void:
	var index_1 = clampi(randi_range(0, _parts_1_textures.size() - 1), 0, 9999)
	var index_2 = clampi(randi_range(0, _parts_2_textures.size() - 1), 0, 9999)
	var index_3 = clampi(randi_range(0, _parts_3_textures.size() - 1), 0, 9999)
	var index_4 = clampi(randi_range(0, _parts_4_textures.size() - 1), 0, 9999)
	_refresh_textures([index_1, index_2, index_3, index_4])


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
