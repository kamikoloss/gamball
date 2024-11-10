class_name MainUi
extends Control


@export var _game_main_button: Button
@export var _game_config_button: Button
@export var _game_info_button: Button

@export var _config_audio_master_slider: HSlider
@export var _config_audio_master_slider_label: Label
@export var _config_audio_bgm_slider: HSlider
@export var _config_audio_bgm_slider_label: Label
@export var _config_audio_se_slider: HSlider
@export var _config_audio_se_slider_label: Label


func _ready() -> void:
	# 初期化
	# TODO: セーブデータを参照する
	_on_config_audio_slider_changed(AudioManager.BusType.Master, 8)
	_on_config_audio_slider_changed(AudioManager.BusType.Bgm, 8)
	_on_config_audio_slider_changed(AudioManager.BusType.Se, 8)

	_game_main_button.pressed.connect(func(): CameraManager.show_main())
	_game_config_button.pressed.connect(func(): CameraManager.show_config())
	_game_info_button.pressed.connect(func(): CameraManager.show_info())

	_config_audio_master_slider.value_changed.connect(func(v): _on_config_audio_slider_changed(AudioManager.BusType.Master, v))
	_config_audio_bgm_slider.value_changed.connect(func(v): _on_config_audio_slider_changed(AudioManager.BusType.Bgm, v))
	_config_audio_se_slider.value_changed.connect(func(v): _on_config_audio_slider_changed(AudioManager.BusType.Se, v))


func _on_config_audio_slider_changed(type: AudioManager.BusType, volume_level: int) -> void:
	print("[MainUi] _on_config_audio_slider_changed(type: %s, volume_level: %s)" % [type, volume_level])
	AudioManager.set_volume(type, volume_level)
	_refresh_config_audio_slider(type, volume_level)


func _refresh_config_audio_slider(type: AudioManager.BusType, volume_level: int) -> void:
	match type:
		AudioManager.BusType.Master:
			_config_audio_master_slider.value = volume_level
			_config_audio_master_slider_label.text = str(volume_level)
		AudioManager.BusType.Bgm:
			_config_audio_bgm_slider.value = volume_level
			_config_audio_bgm_slider_label.text = str(volume_level)
		AudioManager.BusType.Se:
			_config_audio_se_slider.value = volume_level
			_config_audio_se_slider_label.text = str(volume_level)
