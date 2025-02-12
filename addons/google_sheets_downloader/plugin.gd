@tool
extends EditorPlugin


var _dock: GoogleSheetesDownloaderDock
var _http: HTTPRequest


func _enter_tree() -> void:
	_dock = preload("res://addons/google_sheets_downloader/dock.tscn").instantiate()
	_dock.download_button_pressed.connect(_download_google_sheets)
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, _dock)

	_http = _dock.http_request
	_http.request_completed.connect(_on_download_google_sheets_completed)


func _exit_tree() -> void:
	remove_control_from_docks(_dock)
	#_http.request_completed.disconnect(_on_download_google_sheets_completed)

	if _http:
		_http.free()
	if _dock:
		_dock.free()


func _download_google_sheets(id: String, gid: String, file_path: String) -> void:
	_print("downloading sheets...")
	var url = "https://docs.google.com/spreadsheets/d/%s/export?gid=%s&format=csv" % [id, gid]
	_http.download_file = file_path
	_http.request(url, PackedStringArray(), HTTPClient.METHOD_GET)


func _on_download_google_sheets_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	match response_code:
		200:
			_print("succeeded to download! (file_path: %s)" % [_http.download_file])
		# 最初のリクエストは 307 Temporary Redirect を返すので再リクエストする
		# ref. https://github.com/godotengine/godot/issues/90160#issuecomment-2041362582
		307:
			for header in headers:
				var header_parts = header.split(": ", false, 1)
				if header_parts[0] == "Location":
					var url = header_parts[1]
					_http.request(url, PackedStringArray(), HTTPClient.METHOD_GET)
		_:
			_print("failed to download. (response_code: %s)" % [response_code])


func _print(message: String) -> void:
	print("[GoogleSheetesDownloader] %s" % [message])
