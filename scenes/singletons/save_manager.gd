#class_name SaveManager
extends Node


const CONFIG_FILE_PATH := "user://config"
const CONFIG_KEY_GAME := "game"
const CONFIG_KEY_VIDEO := "video"
const CONFIG_KEY_AUDIO := "audio"


var game_config: GameConfig
var video_config: VideoConfig
var audio_config: AudioConfig


func _ready() -> void:
	print("[SaveManager] ready.")
	init_save_data()
	load_config()


func init_save_data() -> void:
	if not game_config:
		game_config = GameConfig.new()
	if not video_config:
		video_config = VideoConfig.new()
	if not audio_config:
		audio_config = AudioConfig.new()


func load_config() -> void:
	if not FileAccess.file_exists(CONFIG_FILE_PATH):
		return 
	var config_file = FileAccess.open(CONFIG_FILE_PATH, FileAccess.READ)
	var config_data = JSON.parse_string(config_file.get_line())
	for config_key in config_data.keys():
		match config_key:
			CONFIG_KEY_GAME:
				game_config.deserialize(config_data[CONFIG_KEY_GAME])
			CONFIG_KEY_VIDEO:
				video_config.deserialize(config_data[CONFIG_KEY_VIDEO])
			CONFIG_KEY_AUDIO:
				audio_config.deserialize(config_data[CONFIG_KEY_AUDIO])
	print("[SaveManager] load_config() config_data: %s" % [config_data])


func save_config() -> void:
	var config_file = FileAccess.open(CONFIG_FILE_PATH, FileAccess.WRITE)
	var config_data = JSON.stringify({
		CONFIG_KEY_GAME: game_config.serialize(),
		CONFIG_KEY_VIDEO: video_config.serialize(),
		CONFIG_KEY_AUDIO: audio_config.serialize(),
	})
	config_file.store_line(config_data)
	print("[SaveManager] save_config() config_data: %s" % [config_data])


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
