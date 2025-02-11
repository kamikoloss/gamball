#class_name NetworkManager
extends Node


@export var http: HTTPRequest


func _ready() -> void:
	_download_google_sheets()


func _get_google_sheets_url() -> String:
	var id := "16a2xelqXRadMEHmGxsouNhut7MArpOgXknMEdnjLcuU"
	var gid := "1795548261"
	var url := "https://docs.google.com/spreadsheets/d/%s/export?gid=%s&format=csv" % [id, gid]
	return url

func _download_google_sheets() -> void:
	http.request_completed.connect(_on_download_google_sheets_completed)
	http.download_file = "resources/translations/tr.csv"
	http.request(_get_google_sheets_url(), PackedStringArray(), HTTPClient.METHOD_GET)

func _on_download_google_sheets_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	http.request_completed.disconnect(_on_download_google_sheets_completed)
	# 最初のリクエストは 307 Temporary Redirect を返すので再リクエストする
	# ref. https://github.com/godotengine/godot/issues/90160#issuecomment-2041362582
	if response_code == 307:
		for header in headers:
			var header_parts = header.split(": ", false, 1)
			if header_parts[0] == "Location":
				http.request_completed.connect(_on_download_google_sheets_completed)
				http.download_file = "resources/translations/tr.csv"
				http.request(header_parts[1], PackedStringArray(), HTTPClient.METHOD_GET)
