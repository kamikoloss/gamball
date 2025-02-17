#class_name SaveManager
extends Node


const CONFIG_FILE_PATH := "user://config"
const CONFIG_KEY_GAME := "game"
const CONFIG_KEY_VIDEO := "video"
const CONFIG_KEY_AUDIO := "audio"

const GAME_FILE_PATH := "user://game"
const GAME_KEY_STATS := "stats"
const GAME_KEY_RUN := "run"


var game_config: GameConfig
var video_config: VideoConfig
var audio_config: AudioConfig

var game_run: GameRun


func _ready() -> void:
	print("[SaveManager] ready.")
	_init_save_data()
	_load_config()
	_load_game()


func save_config() -> void:
	var file = FileAccess.open(CONFIG_FILE_PATH, FileAccess.WRITE)
	var data = JSON.stringify({
		CONFIG_KEY_GAME: game_config.serialize(),
		CONFIG_KEY_VIDEO: video_config.serialize(),
		CONFIG_KEY_AUDIO: audio_config.serialize(),
	})
	file.store_line(data)
	print("[SaveManager] save_config() data: %s" % [data])


func save_game() -> void:
	var file = FileAccess.open(GAME_FILE_PATH, FileAccess.WRITE)
	var data = JSON.stringify({
		GAME_KEY_RUN: game_run.serialize(),
	})
	file.store_line(data)
	print("[SaveManager] save_game() data: %s" % [data])


func _init_save_data() -> void:
	game_config = GameConfig.new()
	video_config = VideoConfig.new()
	audio_config = AudioConfig.new()
	game_run = GameRun.new()
	print("[SaveManager] _init_save_data()")


func _load_config() -> void:
	if not FileAccess.file_exists(CONFIG_FILE_PATH):
		return 
	var file = FileAccess.open(CONFIG_FILE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_line())
	for key in data.keys():
		match key:
			CONFIG_KEY_GAME:
				game_config.deserialize(data[CONFIG_KEY_GAME])
			CONFIG_KEY_VIDEO:
				video_config.deserialize(data[CONFIG_KEY_VIDEO])
			CONFIG_KEY_AUDIO:
				audio_config.deserialize(data[CONFIG_KEY_AUDIO])
	print("[SaveManager] _load_config() data: %s" % [data])


func _load_game() -> void:
	if not FileAccess.file_exists(GAME_FILE_PATH):
		return 
	var file = FileAccess.open(GAME_FILE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_line())
	for key in data.keys():
		match key:
			GAME_KEY_RUN:
				game_run.deserialize(data[GAME_KEY_RUN])
	print("[SaveManager] _load_game() data: %s" % [data])


class SaveDataBase:
	func serialize() -> Dictionary:
		var dict = {}
		for property_name in get_peroperty_names():
			dict[property_name] = get(property_name)
		return dict
	func deserialize(dict: Dictionary) -> void:
		for property_name in get_peroperty_names():
			set(property_name, dict[property_name])
	func get_peroperty_names() -> Array[String]:
		return []


class GameConfig extends SaveDataBase:
	var language := "ja"
	func get_peroperty_names() -> Array[String]:
		return ["language"]


class VideoConfig extends SaveDataBase:
	var window_mode := VideoManager.WindowMode.WINDOW
	var window_size := VideoManager.WindowSize.W1280
	func get_peroperty_names() -> Array[String]:
		return ["window_mode", "window_size"]


class AudioConfig extends SaveDataBase:
	var volume_master := 8
	var volume_bgm := 8
	var volume_se := 8
	func get_peroperty_names() -> Array[String]:
		return ["volume_master", "volume_bgm", "volume_se"]

	func set_volume(bus_type: AudioManager.BusType, volume: int) -> void:
		match bus_type:
			AudioManager.BusType.MASTER:
				volume_master = volume
			AudioManager.BusType.BGM:
				volume_bgm = volume
			AudioManager.BusType.SE:
				volume_se = volume


# 現在のランの進行状態を管理するデータ
# TODO: Ball に Serialize/Deserialize を実装する
class GameRun extends SaveDataBase:
	var version := String(ProjectSettings.get_setting("application/config/version"))
	var started := int(Time.get_unix_time_from_system())
	var saved := int(Time.get_unix_time_from_system())
	var turn := 0
	var balls := 0
	var deck: Array[Ball] = []
	var extra: Array[Ball] = []
	var billiards: Array[Ball] = []
	func serialize() -> Dictionary:
		var dict = {}
		for property_name in get_property_names():
			var data = get(property_name)
			var array = []
			if property_name in ["deck", "extra", "billiards"]:
				for i in data.size():
					var ball: Ball = data[i]
					array.append([ball.number, ball.rarity, ball.pool, ball.effects, [int(ball.global_position.x), int(ball.global_position.y)]])
			dict[property_name] = array
		return dict
	func deserialize(dict: Dictionary) -> void:
		for property_name in get_property_names():
			if not dict.has(property_name):
				continue
			var data = dict[property_name]
			if property_name in ["deck", "extra", "billiards"]:
				for i in data.size():
					var ball = Ball.new(data[i][0], data[i][1])
					ball.pool = data[i][2]
					ball.effects = data[i][3]
					data[i] = ball
			set(property_name, data)
	func get_property_names() -> Array[String]:
		return [
			"version", "started", "saved",
			"turn", "balls",
			"deck", "extra", "billiards"
		]
