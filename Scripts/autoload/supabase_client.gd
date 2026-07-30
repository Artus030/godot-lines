extends Node

const SUPABASE_URL: String = "https://bstflxyqetppyzgqrznv.supabase.co"
const PUBLISHABLE_KEY: String = "sb_publishable_uZs78vohlk9O21UugDP9Qw_POmPTLHY"

var http_request: HTTPRequest
var current_callback: Callable

func _ready() -> void:
	if has_node("HTTPRequest"):
		http_request = $HTTPRequest
	else:
		http_request = HTTPRequest.new()
		http_request.name = "HTTPRequest"
		add_child(http_request)
	http_request.accept_gzip = false

	if not http_request.request_connected.is_connected(_on_request_completed) if http_request.has_signal("request_connected") else false:
		pass

	if not http_request.request_completed.is_connected(_on_request_completed):
		http_request.request_completed.connect(_on_request_completed)


func request(endpoint: String, method: HTTPClient.Method, data: Dictionary, callback: Callable) -> void:
	current_callback = callback

	# Da der Browser Accept-Encoding sowieso überschreibt, reichen die sauberen Standard-Header
	var headers = [
		"apikey: " + PUBLISHABLE_KEY,
		"Authorization: Bearer " + PUBLISHABLE_KEY,
		"Content-Type: application/json",
		"Accept: application/json"
	]
	
	var payload = JSON.stringify(data) if not data.is_empty() else ""
	
	if method == HTTPClient.METHOD_POST:
		headers.append("Prefer: return=minimal")

	var error = http_request.request(SUPABASE_URL + endpoint, headers, method, payload)
	if error != OK:
		print("Network error on request: ", error)
		if current_callback.is_valid():
			current_callback.call(0, null)


# Der permanente Listener verarbeitet das Ergebnis
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var parsed_json = _parse_body(body)
	
	if current_callback.is_valid():
		current_callback.call(response_code, parsed_json)


func get_db(endpoint: String, callback: Callable) -> void:
	request(endpoint, HTTPClient.METHOD_GET, {}, callback)

func post_db(endpoint: String, data: Dictionary, callback: Callable) -> void:
	request(endpoint, HTTPClient.METHOD_POST, data, callback)


func _parse_body(body: PackedByteArray) -> Variant:
	if body.is_empty():
		return null
	
	var raw_text = body.get_string_from_utf8()
	var json = JSON.new()
	var err = json.parse(raw_text)
	
	if err == OK:
		return json.get_data()
	else:
		print("JSON Parse-Error in Web! Text was: ", raw_text)
		return null
