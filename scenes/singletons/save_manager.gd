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
var game_stats: GameStats
var game_run: GameRun


func _ready() -> void:
	print("[SaveManager] ready.")
	_init_save_data()
	_load_config()
	_load_game()


func save_config() -> void:
	var file := FileAccess.open(CONFIG_FILE_PATH, FileAccess.WRITE)
	var data := JSON.stringify({
		CONFIG_KEY_GAME: game_config.serialize(),
		CONFIG_KEY_VIDEO: video_config.serialize(),
		CONFIG_KEY_AUDIO: audio_config.serialize(),
	})
	file.store_line(data)
	print("[SaveManager] save_config() data: %s" % [data])


func save_game() -> void:
	game_run.saved = int(Time.get_unix_time_from_system())
	# TODO: uptime
	var file := FileAccess.open(GAME_FILE_PATH, FileAccess.WRITE)
	var data := JSON.stringify({
		GAME_KEY_STATS: game_stats.serialize(),
		GAME_KEY_RUN: game_run.serialize(),
	})
	file.store_line(data)
	print("[SaveManager] save_game() data: %s" % [data])


func _init_save_data() -> void:
	game_config = GameConfig.new()
	video_config = VideoConfig.new()
	audio_config = AudioConfig.new()
	game_stats = GameStats.new()
	game_run = GameRun.new()
	print("[SaveManager] _init_save_data()")


func _load_config() -> void:
	if not FileAccess.file_exists(CONFIG_FILE_PATH):
		return 
	var file := FileAccess.open(CONFIG_FILE_PATH, FileAccess.READ)
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
	var file := FileAccess.open(GAME_FILE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_line())
	for key in data.keys():
		match key:
			GAME_KEY_STATS:
				game_stats.deserialize(data[GAME_KEY_STATS])
			GAME_KEY_RUN:
				game_run.deserialize(data[GAME_KEY_RUN])
	print("[SaveManager] _load_game() data: %s" % [data])


class SaveDataBase:
	func serialize() -> Dictionary:
		var dict := {}
		for key in get_serializable_keys():
			var data = get(key)
			dict[key] = data
		return dict
	func deserialize(dict: Dictionary) -> void:
		for key in get_serializable_keys():
			if dict.has(key):
				var data = dict[key]
				set(key, data)
	func get_serializable_keys() -> Array[String]:
		return []


class GameConfig extends SaveDataBase:
	var language := "ja"
	func get_serializable_keys() -> Array[String]:
		return ["language"]


class VideoConfig extends SaveDataBase:
	var window_mode := VideoManager.WindowMode.WINDOW
	var window_size := VideoManager.WindowSize.W1280
	var crt_effect := VideoManager.CrtEffect.ON
	func get_serializable_keys() -> Array[String]:
		return ["window_mode", "window_size", "crt_effect"]


class AudioConfig extends SaveDataBase:
	var volume_master := 8
	var volume_bgm := 8
	var volume_se := 8
	func get_serializable_keys() -> Array[String]:
		return ["volume_master", "volume_bgm", "volume_se"]

	func set_volume(bus_type: AudioManager.BusType, volume: int) -> void:
		match bus_type:
			AudioManager.BusType.MASTER:
				volume_master = volume
			AudioManager.BusType.BGM:
				volume_bgm = volume
			AudioManager.BusType.SE:
				volume_se = volume


class GameStats extends SaveDataBase:
	pass


class GameRun extends SaveDataBase:
	var version := String(ProjectSettings.get_setting("application/config/version"))
	var started := int(Time.get_unix_time_from_system())
	var saved := int(Time.get_unix_time_from_system())
	var uptime := 0
	var turn := -1
	var balls := 0
	var deck: Array[Ball] = []
	var extra: Array[Ball] = []
	var billiards: Array[Ball] = []
	func serialize() -> Dictionary:
		var dict = {}
		for key in get_serializable_keys():
			var data = get(key)
			if key in ["deck", "extra", "billiards"]:
				var balls: Array[Dictionary]
				for d in data:
					balls.append(serialize_ball(d))
				dict[key] = balls
			else:
				dict[key] = data
		return dict
	func deserialize(dict: Dictionary) -> void:
		for key in get_serializable_keys():
			var data = dict[key]
			if key in ["deck", "extra", "billiards"]:
				var balls: Array[Ball]
				for d in data:
					balls.append(deserialize_ball(d))
				set(key, balls)
			else:
				set(key, data)
	func get_serializable_keys() -> Array[String]:
		return [
			"version", "started", "saved", "uptime",
			"turn", "balls",
			"deck", "extra", "billiards"
		]

	func serialize_ball(ball: Ball) -> Dictionary:
		return {
			"n": ball.number,
			"r": ball.rarity,
			"a": ball.is_active,
			"p": ball.pool,
			"e": ball.effects,
			"v": [int(ball.global_position.x), int(ball.global_position.y)]
		}
	func deserialize_ball(dict: Dictionary) -> Ball:
		var ball = Ball.new(dict["n"], dict["r"])
		ball.is_active = dict["a"]
		ball.pool = dict["p"]
		ball.effects = dict["e"]
		ball.global_position = Vector2(dict["v"][0], dict["v"][1])
		return ball
