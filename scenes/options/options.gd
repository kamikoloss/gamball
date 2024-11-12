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
	_audio_master_slider.value_changed.connect(func(v): _on_audio_slider_changed(AudioManager.BusType.Master, v))
	_audio_bgm_slider.value_changed.connect(func(v): _on_audio_slider_changed(AudioManager.BusType.Bgm, v))
	_audio_se_slider.value_changed.connect(func(v): _on_audio_slider_changed(AudioManager.BusType.Se, v))


func _on_audio_slider_changed(bus_type: AudioManager.BusType, volume_level: int) -> void:
	#print("[Options] _on_audio_slider_changed(bus_type: %s, volume_level: %s)" % [bus_type, volume_level])
	AudioManager.set_volume(bus_type, volume_level)
	_refresh_config_audio_slider(bus_type, volume_level)

func _refresh_config_audio_slider(bus_type: AudioManager.BusType, volume_level: int) -> void:
	match bus_type:
		AudioManager.BusType.Master:
			_audio_master_slider.value = volume_level
			_audio_master_slider_label.text = str(volume_level)
		AudioManager.BusType.Bgm:
			_audio_bgm_slider.value = volume_level
			_audio_bgm_slider_label.text = str(volume_level)
		AudioManager.BusType.Se:
			_audio_se_slider.value = volume_level
			_audio_se_slider_label.text = str(volume_level)
