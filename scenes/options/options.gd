class_name Options
extends Control


@export var _audio_master_slider: HSlider
@export var _audio_master_slider_label: Label
@export var _audio_bgm_slider: HSlider
@export var _audio_bgm_slider_label: Label
@export var _audio_se_slider: HSlider
@export var _audio_se_slider_label: Label


func _ready() -> void:
	# TODO: SaveManager で設定を読み込む

	# Signal
	_audio_master_slider.value_changed.connect(func(v): _on_audio_slider_changed(AudioManager.BusType.MASTER, v))
	_audio_bgm_slider.value_changed.connect(func(v): _on_audio_slider_changed(AudioManager.BusType.BGM, v))
	_audio_se_slider.value_changed.connect(func(v): _on_audio_slider_changed(AudioManager.BusType.SE, v))


func _on_audio_slider_changed(bus_type: AudioManager.BusType, volume_level: int) -> void:
	#print("[Options] _on_audio_slider_changed(bus_type: %s, volume_level: %s)" % [bus_type, volume_level])
	AudioManager.set_volume(bus_type, volume_level)
	_refresh_config_audio_slider(bus_type, volume_level)

func _refresh_config_audio_slider(bus_type: AudioManager.BusType, volume_level: int) -> void:
	match bus_type:
		AudioManager.BusType.MASTER:
			_audio_master_slider.value = volume_level
			_audio_master_slider_label.text = str(volume_level)
		AudioManager.BusType.BGM:
			_audio_bgm_slider.value = volume_level
			_audio_bgm_slider_label.text = str(volume_level)
		AudioManager.BusType.SE:
			_audio_se_slider.value = volume_level
			_audio_se_slider_label.text = str(volume_level)
