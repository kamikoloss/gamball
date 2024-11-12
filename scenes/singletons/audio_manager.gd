#class_name AudioManager
extends Node


enum BusType {
	Master = 0,
	Bgm = 1,
	Se = 2,
}
enum BgmType {
	Default,
}
enum SeType {
	BilliardsShoot,
	PachinkoLampOff, PachinkoLampOn,
	PachinkoRushStart, PachinkoRushFinish,
}


@export_category("AudioStreamPlayer")
@export var _bgm_player: AudioStreamPlayer
@export var _se_player_1: AudioStreamPlayer
@export var _se_player_2: AudioStreamPlayer
@export var _se_player_3: AudioStreamPlayer
@export var _se_player_4: AudioStreamPlayer

@export_category("SE AudioStream")
@export var _se_BilliardsShoot: AudioStream
@export var _se_PachinkoLampOff: AudioStream
@export var _se_PachinkoLampOn: AudioStream
@export var _se_PachinkoRushStart: AudioStream
@export var _se_PachinkoRushFinish: AudioStream


func _ready() -> void:
	# BGM はループ再生する
	_bgm_player.finished.connect(func(): _bgm_player.play())


# 0: -40db, 5: -20db, 10: 0db, 
func set_volume(bus_type: BusType, volume_level: int) -> void:
	print("[AudioManager] set_volume(bus_type: %s, volume_level: %s)" % [bus_type, volume_level])
	var volume_clamped = clampi(volume_level, 0, 10)
	var volume_db = -40 + volume_clamped * 4
	AudioServer.set_bus_volume_db(bus_type, volume_db)


func play_se(bus_type: SeType) -> void:
	var se_player: AudioStreamPlayer
	var se_audio: AudioStream

	match bus_type:
		SeType.BilliardsShoot:
			se_player = _se_player_1
			se_audio = _se_BilliardsShoot
		SeType.PachinkoLampOff:
			se_player = _se_player_2
			se_audio = _se_PachinkoLampOff
		SeType.PachinkoLampOn:
			se_player = _se_player_2
			se_audio = _se_PachinkoLampOn
		SeType.PachinkoRushStart:
			se_player = _se_player_2
			se_audio = _se_PachinkoRushStart
		SeType.PachinkoRushFinish:
			se_player = _se_player_2
			se_audio = _se_PachinkoRushFinish

	if not se_player or not se_audio:
		return

	se_player.stream = se_audio
	se_player.play()
