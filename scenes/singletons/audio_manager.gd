#class_name AudioManager
extends Node


# NOTE: bus_idx として使うので bus_layout の順番を合致させる必要がある
enum BusType {
	MASTER = 0,
	BGM = 1,
	SE = 2,
}

enum BgmType {
	DEFAULT,
}
enum SeType {
	BILLIARDS_SHOT,
	PACHINKO_LAMP_OFF, PACHINKO_LAMP_ON,
	PACHINKO_RUSH_START, PACHINKO_RUSH_FINISH,
}


@export_category("AudioStreamPlayer")
@export var _bgm_player: AudioStreamPlayer
@export var _se_player_1: AudioStreamPlayer
@export var _se_player_2: AudioStreamPlayer
@export var _se_player_3: AudioStreamPlayer
@export var _se_player_4: AudioStreamPlayer

@export_category("SE AudioStream")
@export var _se_BILLIARDS_SHOT: AudioStream
@export var _se_PACHINKO_LAMP_OFF: AudioStream
@export var _se_PACHINKO_LAMP_ON: AudioStream
@export var _se_PACHINKO_RUSH_START: AudioStream
@export var _se_PACHINKO_RUSH_FINISH: AudioStream


func _ready() -> void:
	# BGM はループ再生する
	_bgm_player.finished.connect(func(): _bgm_player.play())


func initialize() -> void:
	_bgm_player.play()


# 0: -40db, 5: -20db, 10: 0db, 
func set_volume(bus_type: BusType, volume_level: int) -> void:
	print("[AudioManager] set_volume(bus_type: %s, volume_level: %s)" % [bus_type, volume_level])
	var volume_clamped = clampi(volume_level, 0, 10)
	var volume_db = -40 + volume_clamped * 4
	AudioServer.set_bus_volume_db(bus_type, volume_db)


func play_se(se_type: SeType) -> void:
	var se_player: AudioStreamPlayer
	var se_audio: AudioStream

	for se_group in _get_se_groups():
		if se_type in se_group["audio"].keys():
			se_player = se_group["player"]
			se_audio = se_group["audio"][se_type]
			continue

	if not se_player or not se_audio:
		return

	se_player.stream = se_audio
	se_player.play()


# Player と SE の対応を取得する
func _get_se_groups() -> Array:
	return [
		{
			"player": _se_player_1,
			"audio": {
				SeType.BILLIARDS_SHOT: _se_BILLIARDS_SHOT,
			},
		},
		{
			"player": _se_player_2,
			"audio": {
				SeType.PACHINKO_LAMP_OFF: _se_PACHINKO_LAMP_OFF,
				SeType.PACHINKO_LAMP_ON: _se_PACHINKO_LAMP_ON,
				SeType.PACHINKO_RUSH_START: _se_PACHINKO_RUSH_START,
				SeType.PACHINKO_RUSH_FINISH: _se_PACHINKO_RUSH_FINISH,
			},
		}
	]
