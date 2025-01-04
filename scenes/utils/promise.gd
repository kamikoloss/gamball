extends Object
class_name Promise
# 複数の Signal を一斉に実行するクラス


signal completed_all(args)
signal completed_any(args)


var _signals: Dictionary = {} # signal: { has_emitted: bool, data: any }
var _completed: bool = false


func _init(signals: Array[Signal]) -> void:
	for s in signals:
		_signals[s] = s
		s.connect(_on_signal)


func _on_signal(s: Signal) -> void:
	_signals[s].has_emitted = true
	_check_completion()


func _check_completion():
	if _completed:
		return
	_check_all_completion()
	_check_any_completion()


func _check_all_completion() -> void:
	var return_data: Array = []
	for s in _signals:
		if not _signals[s].has_emitted:
			return
		else:
			return_data.append(_signals[s].data)


func _check_any_completion() -> void:
	for s in _signals:
		if _signals[s].has_emitted:
			completed_all.emit(_signals[s].data)
			return
