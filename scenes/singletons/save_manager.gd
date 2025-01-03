#class_name SaveManager
extends Node


const CONFIG_FILE_PATH = "user://config"
const CONFIG_KEY_AUDIO = "Audio"


var audio_config: AudioConfig


func _ready() -> void:
	init_config()
	load_config()


func initialize() -> void:
	pass


func load_config() -> void:
	if not FileAccess.file_exists(CONFIG_FILE_PATH):
		return 
	var config_file = FileAccess.open(CONFIG_FILE_PATH, FileAccess.READ)
	var config_data = JSON.parse_string(config_file.get_line())
	for config_key in config_data.keys():
		match config_key:
			CONFIG_KEY_AUDIO:
				audio_config.deserialize(config_data[CONFIG_KEY_AUDIO])
	print("[SaveManager] load_config() config_data: %s" % [config_data])


func save_config() -> void:
	var config_file = FileAccess.open(CONFIG_FILE_PATH, FileAccess.WRITE)
	var config_data = JSON.stringify({
		CONFIG_KEY_AUDIO: audio_config.serialize(),
	})
	config_file.store_line(config_data)
	#print("[SaveManager] save_config() config_data: %s" % [config_data])


func init_config() -> void:
	if not audio_config:
		audio_config = AudioConfig.new()


class ConfigBase:
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

class AudioConfig extends ConfigBase:
	var volume_master: int = 8
	var volume_bgm: int = 8
	var volume_se: int = 8
	func get_peroperty_names() -> Array[String]:
		return [
			"volume_master",
			"volume_bgm",
			"volume_se",
		]
