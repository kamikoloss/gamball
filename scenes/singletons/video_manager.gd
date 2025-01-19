extends Node
#class_name VideoManager


enum WindowMode { WINDOW, FULLSCREEN }
enum WindowSize { W640, W1280, W1920, W2560 }


const WINDOW_MODE = {
	WindowMode.WINDOW: DisplayServer.WindowMode.WINDOW_MODE_WINDOWED,
	WindowMode.FULLSCREEN: DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN,
}
const WINDOW_SIZE = {
	WindowSize.W640: [640, 360],
	WindowSize.W1280: [1280, 720],
	WindowSize.W1920: [1920, 1080],
	WindowSize.W2560: [2560, 1440],
}

const WINDOW_MODE_LABELS = {
	WindowMode.WINDOW: "Window",
	WindowMode.FULLSCREEN: "Fullscreen",
}
const WINDOW_SIZE_LABELS = {
	WindowSize.W640: "640 x 360",
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

	var m = WINDOW_MODE[mode]
	DisplayServer.window_set_mode(m)

	if SaveManager.video_config:
		set_window_size(SaveManager.video_config.window_size)


func set_window_size(size: WindowSize) -> void:
	if OS.has_feature("web"):
		return

	var x = WINDOW_SIZE[size][0]
	var y = WINDOW_SIZE[size][1]
	get_window().size = Vector2i(x, y)
