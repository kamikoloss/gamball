class_name Options
extends Control


signal exit_button_pressed


@export var _reset_button: Button
@export var _exit_button: Button

@export_category("Game")
@export var _language_selector: Selector

@export_category("Video")
@export var _window_mode_selector: Selector
@export var _window_size_selector: Selector

@export_category("Audio")
@export var _audio_master_slider: BarSlider
@export var _audio_master_label: Label
@export var _audio_master_mute_button: Button
@export var _audio_bgm_slider: BarSlider
@export var _audio_bgm_label: Label
@export var _audio_bgm_mute_button: Button
@export var _audio_se_slider: BarSlider
@export var _audio_se_label: Label
@export var _audio_se_mute_button: Button


func _ready() -> void:
	# Signal
	_exit_button.pressed.connect(func(): exit_button_pressed.emit())
	_audio_master_slider.changed.connect(func(v): _on_audio_slider_changed(AudioManager.BusType.MASTER, v))
	_audio_bgm_slider.changed.connect(func(v): _on_audio_slider_changed(AudioManager.BusType.BGM, v))
	_audio_se_slider.changed.connect(func(v): _on_audio_slider_changed(AudioManager.BusType.SE, v))
	_audio_master_mute_button.pressed.connect(func(): _on_audio_slider_changed(AudioManager.BusType.MASTER, 0))
	_audio_bgm_mute_button.pressed.connect(func(): _on_audio_slider_changed(AudioManager.BusType.BGM, 0))
	_audio_se_mute_button.pressed.connect(func(): _on_audio_slider_changed(AudioManager.BusType.SE, 0))

	#  UI 初期化
	# NOTE: SaveManager の _ready() が実行済みである必要がある
	_window_mode_selector.options = SaveManager.video_config.WINDOW_MODE_LABELS
	_window_mode_selector.value = SaveManager.video_config.window_mode
	_window_size_selector.options = SaveManager.video_config.WINDOW_SIZE_LABELS
	_window_size_selector.value = SaveManager.video_config.window_size
	_refresh_config_audio_slider(AudioManager.BusType.MASTER, SaveManager.audio_config.volume_master)
	_refresh_config_audio_slider(AudioManager.BusType.BGM, SaveManager.audio_config.volume_bgm)
	_refresh_config_audio_slider(AudioManager.BusType.SE, SaveManager.audio_config.volume_se)


func _on_audio_slider_changed(bus_type: AudioManager.BusType, volume_level: int) -> void:
	#print("[Options] _on_audio_slider_changed(bus_type: %s, volume_level: %s)" % [bus_type, volume_level])
	SaveManager.audio_config.set_volume(bus_type, volume_level)
	AudioManager.set_volume(bus_type, volume_level)
	_refresh_config_audio_slider(bus_type, volume_level)


func _refresh_config_audio_slider(bus_type: AudioManager.BusType, volume_level: int) -> void:
	match bus_type:
		AudioManager.BusType.MASTER:
			_audio_master_slider.value = volume_level
			_audio_master_label.text = str(volume_level)
		AudioManager.BusType.BGM:
			_audio_bgm_slider.value = volume_level
			_audio_bgm_label.text = str(volume_level)
		AudioManager.BusType.SE:
			_audio_se_slider.value = volume_level
			_audio_se_label.text = str(volume_level)
