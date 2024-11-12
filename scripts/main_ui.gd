class_name MainUi
extends Control


# TODO: config シーンに切る


enum TweenType { Curtain }


const CURTAIN_FADE_DURATION: float = 2.0


@export var _curtain: Control

@export var _config_audio_master_slider: HSlider
@export var _config_audio_master_slider_label: Label
@export var _config_audio_bgm_slider: HSlider
@export var _config_audio_bgm_slider_label: Label
@export var _config_audio_se_slider: HSlider
@export var _config_audio_se_slider_label: Label


var _tweens: Dictionary = {} # { TweenType: Tween, ... } 


func _ready() -> void:
	# 初期化
	# TODO: セーブデータを参照する
	#_on_config_audio_slider_changed(AudioManager.BusType.Master, 8)
	_on_config_audio_slider_changed(AudioManager.BusType.Master, 0)
	_on_config_audio_slider_changed(AudioManager.BusType.Bgm, 8)
	_on_config_audio_slider_changed(AudioManager.BusType.Se, 8)

	# Signal
	_config_audio_master_slider.value_changed.connect(func(v): _on_config_audio_slider_changed(AudioManager.BusType.Master, v))
	_config_audio_bgm_slider.value_changed.connect(func(v): _on_config_audio_slider_changed(AudioManager.BusType.Bgm, v))
	_config_audio_se_slider.value_changed.connect(func(v): _on_config_audio_slider_changed(AudioManager.BusType.Se, v))

	_hide_curtain()


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


func _hide_curtain() -> void:
	_curtain.visible = true
	_curtain.modulate = Color.WHITE

	var tween = _get_tween(TweenType.Curtain)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(_curtain, "modulate", Color.TRANSPARENT, CURTAIN_FADE_DURATION)


func _get_tween(type: TweenType) -> Tween:
	if _tweens.has(type):
		_tweens[type].kill()
	_tweens[type] = create_tween()
	return _tweens[type]
