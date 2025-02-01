extends Node
#class_name VideoManager


enum WindowMode { WINDOW, FULLSCREEN }
enum WindowSize { W1280, W1920, W2560 }


const WINDOW_MODE = {
	WindowMode.WINDOW: DisplayServer.WindowMode.WINDOW_MODE_WINDOWED,
	WindowMode.FULLSCREEN: DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN,
}
const WINDOW_SIZE = {
	WindowSize.W1280: [1280, 720],
	WindowSize.W1920: [1920, 1080],
	WindowSize.W2560: [2560, 1440],
}

const WINDOW_MODE_LABELS = {
	WindowMode.WINDOW: "Window",
	WindowMode.FULLSCREEN: "Fullscreen",
}
const WINDOW_SIZE_LABELS = {
	WindowSize.W1280: "1280 x 720",
	WindowSize.W1920: "1920 x 1080",
	WindowSize.W2560: "2560 x 1440",
}


func initialize() -> void:
	print("[VideoManager] initialized.")

	if SaveManager.video_config:
		set_window_mode(SaveManager.video_config.window_mode)
		set_window_size(SaveManager.video_config.window_size)


func set_window_mode(mode: WindowMode) -> void:
	if OS.has_feature("web"):
		return

	DisplayServer.window_set_mode(WINDOW_MODE[mode])

	if SaveManager.video_config:
		set_window_size(SaveManager.video_config.window_size)


func set_window_size(size: WindowSize) -> void:
	if OS.has_feature("web"):
		return

	var old_size = DisplayServer.window_get_size()
	var old_pos = DisplayServer.window_get_position()

	var new_size = Vector2i(WINDOW_SIZE[size][0], WINDOW_SIZE[size][1])
	DisplayServer.window_set_size(new_size)

	# ウィンドウの中心をずらさないように調整する
	var new_pos = old_pos - (new_size - old_size) / 2
	DisplayServer.window_set_position(new_pos)
