extends Node

const SUPABASE_URL: String = "https://bstflxyqetppyzgqrznv.supabase.co"
const PUBLISHABLE_KEY: String = "sb_publishable_uZs78vohlk9O21UugDP9Qw_POmPTLHY"

func request(endpoint: String, method: HTTPClient.Method, data: Dictionary, callback: Callable) -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	http_request.request_completed.connect(
		func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
			var parsed_json = _parse_body(body)
			callback.call(response_code, parsed_json)
			http_request.queue_free()
	)

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
		http_request.queue_free()
		callback.call(0, null)


func get_db(endpoint: String, callback: Callable) -> void:
	request(endpoint, HTTPClient.METHOD_GET, {}, callback)

func post_db(endpoint: String, data: Dictionary, callback: Callable) -> void:
	request(endpoint, HTTPClient.METHOD_POST, data, callback)


func _parse_body(body: PackedByteArray) -> Variant:
	if body.is_empty():
		return null

	var json_text: String = ""

	if body.size() > 2 and body[0] == 0x1f and body[1] == 0x8b:
		var decompressed = body.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
		if decompressed.size() > 0:
			json_text = decompressed.get_string_from_utf8()
		else:
			print("GZIP Decomp failed!")
			return null
	else:
		json_text = body.get_string_from_utf8()

	var json = JSON.new()
	var error = json.parse(json_text)
	if error == OK:
		return json.get_data()
	else:
		print("JSON Parse-Error: ", error, " Text was: ", json_text)
		return null
