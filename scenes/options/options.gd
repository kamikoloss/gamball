class_name Options
extends Control


signal exit_button_pressed


@export var _reset_button: Button
@export var _exit_button: Button

@export_category("Audio")
@export var _audio_master_slider: HSlider
@export var _audio_master_ball: Ball
@export var _audio_bgm_slider: HSlider
@export var _audio_bgm_ball: Ball
@export var _audio_se_slider: HSlider
@export var _audio_se_ball: Ball


func _ready() -> void:
	# Signal
	_exit_button.pressed.connect(func(): exit_button_pressed.emit())
	_audio_master_slider.value_changed.connect(func(v): _on_audio_slider_changed(AudioManager.BusType.MASTER, v))
	_audio_bgm_slider.value_changed.connect(func(v): _on_audio_slider_changed(AudioManager.BusType.BGM, v))
	_audio_se_slider.value_changed.connect(func(v): _on_audio_slider_changed(AudioManager.BusType.SE, v))
	# スライダー初期化
	# NOTE: SaveManager の _ready() が実行済みである必要がある
	_refresh_config_audio_slider(AudioManager.BusType.MASTER, SaveManager.audio_config.volume_master)
	_refresh_config_audio_slider(AudioManager.BusType.BGM, SaveManager.audio_config.volume_bgm)
	_refresh_config_audio_slider(AudioManager.BusType.SE, SaveManager.audio_config.volume_se)


func _on_audio_slider_changed(bus_type: AudioManager.BusType, volume_level: int) -> void:
	#print("[Options] _on_audio_slider_changed(bus_type: %s, volume_level: %s)" % [bus_type, volume_level])
	AudioManager.set_volume(bus_type, volume_level)
	_refresh_config_audio_slider(bus_type, volume_level)


func _refresh_config_audio_slider(bus_type: AudioManager.BusType, volume_level: int) -> void:
	match bus_type:
		AudioManager.BusType.MASTER:
			_audio_master_slider.value = volume_level
			_audio_master_ball.level = volume_level
			_audio_master_ball.refresh_view()
		AudioManager.BusType.BGM:
			_audio_bgm_slider.value = volume_level
			_audio_bgm_ball.level = volume_level
			_audio_bgm_ball.refresh_view()
		AudioManager.BusType.SE:
			_audio_se_slider.value = volume_level
			_audio_se_ball.level = volume_level
			_audio_se_ball.refresh_view()
