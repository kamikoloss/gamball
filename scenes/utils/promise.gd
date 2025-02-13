# 複数の Signal を一斉に実行するクラス
class_name Promise
extends Object


# すべての Signal が発火したときに発火する
signal completed_all
# いずれかの Signal が発火したときに発火する
signal completed_any


# { <Signal>: { "emitted": bool <発火したかどうか>, "data": [ <返り値1>, ... ] } }
var _signals := {}


func _init(signals: Array[Signal]) -> void:
	for s in signals:
		_signals[s] = { "emitted": false, "data": [] }
		s.connect(_on_signal_emitted.bind(s))


func _on_signal_emitted(s: Signal) -> void:
	_signals[s]["emitted"] = true
	#_signals[s]["data"] = [arg1, arg2, arg3, arg4]
	if _signals.values().any(func(v): v["emitted"]):
		completed_any.emit()
		print("[Promise] completed_any")
		#completed_any.emit(_signals[s]["data"])
	if _signals.values().all(func(v): v["emitted"]):
		completed_all.emit()
		print("[Promise] completed_all")
		#completed_all.emit(_signals.values().map(func(v): v["data"]))
