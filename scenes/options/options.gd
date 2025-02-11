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
@export var _master_volume_slider: BarSlider
@export var _master_volume_label: Label
@export var _master_mute_button: Button
@export var _bgm_volume_slider: BarSlider
@export var _bgm_volume_label: Label
@export var _bgm_mute_button: Button
@export var _se_volume_slider: BarSlider
@export var _se_volume_label: Label
@export var _se_mute_button: Button


func _ready() -> void:
	print("[Options] ready.")

	# Signal
	_exit_button.pressed.connect(func(): exit_button_pressed.emit())
	# Sginal (Video)
	_window_mode_selector.changed.connect(func(v): _on_window_mode_selector_changed(v))
	_window_size_selector.changed.connect(func(v): _on_window_size_selector_changed(v))
	# Signal (Audio)
	_master_volume_slider.changed.connect(func(v): _on_volume_slider_changed(AudioManager.BusType.MASTER, v))
	_bgm_volume_slider.changed.connect(func(v): _on_volume_slider_changed(AudioManager.BusType.BGM, v))
	_se_volume_slider.changed.connect(func(v): _on_volume_slider_changed(AudioManager.BusType.SE, v))
	_master_mute_button.pressed.connect(func(): _on_volume_slider_changed(AudioManager.BusType.MASTER, 0))
	_bgm_mute_button.pressed.connect(func(): _on_volume_slider_changed(AudioManager.BusType.BGM, 0))
	_se_mute_button.pressed.connect(func(): _on_volume_slider_changed(AudioManager.BusType.SE, 0))

	#  UI 初期化
	# NOTE: SaveManager の _ready() が実行済みである必要がある
	_window_mode_selector.options = VideoManager.WINDOW_MODE_LABELS
	_window_mode_selector.value = SaveManager.video_config.window_mode
	_window_size_selector.options = VideoManager.WINDOW_SIZE_LABELS
	_window_size_selector.value = SaveManager.video_config.window_size
	_change_volume_slider(AudioManager.BusType.MASTER, SaveManager.audio_config.volume_master)
	_change_volume_slider(AudioManager.BusType.BGM, SaveManager.audio_config.volume_bgm)
	_change_volume_slider(AudioManager.BusType.SE, SaveManager.audio_config.volume_se)


func _on_window_mode_selector_changed(mode: VideoManager.WindowMode) -> void:
	SaveManager.video_config.window_mode = mode
	VideoManager.set_window_mode(mode)

	# WindowMode をフルスクリーンにしたとき WindowSize は変更不可にする
	_window_size_selector.disabled = mode == VideoManager.WindowMode.FULLSCREEN


func _on_window_size_selector_changed(size: VideoManager.WindowSize) -> void:
	SaveManager.video_config.window_size = size
	VideoManager.set_window_size(size)


func _on_volume_slider_changed(bus_type: AudioManager.BusType, volume_level: int) -> void:
	SaveManager.audio_config.set_volume(bus_type, volume_level)
	AudioManager.set_volume(bus_type, volume_level)
	_change_volume_slider(bus_type, volume_level)


func _change_volume_slider(bus_type: AudioManager.BusType, volume_level: int) -> void:
	match bus_type:
		AudioManager.BusType.MASTER:
			_master_volume_slider.value = volume_level
			_master_volume_label.text = str(volume_level)
		AudioManager.BusType.BGM:
			_bgm_volume_slider.value = volume_level
			_bgm_volume_label.text = str(volume_level)
		AudioManager.BusType.SE:
			_se_volume_slider.value = volume_level
			_se_volume_label.text = str(volume_level)
