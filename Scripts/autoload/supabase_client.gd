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
	
	if not http_request.request_completed.is_connected(_on_request_completed):
		http_request.request_completed.connect(_on_request_completed)


func request(endpoint: String, method: HTTPClient.Method, data: Dictionary, callback: Callable) -> void:
	current_callback = callback

	# IM BROWSER: Umgehe den StreamPeerGzip-Bug per JS-Fetch
	if OS.has_feature("web"):
		_request_web(endpoint, method, data, callback)
		return

	# AUF DESKTOP: Normaler HTTPRequest
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


# Der JS-Fetch läuft zu 100% stabil im Browser ohne Gzip-Crashes
# Kugelsicherer Browser-Fetch mit dynamischem Polling
func _request_web(endpoint: String, method: HTTPClient.Method, data: Dictionary, callback: Callable) -> void:
	var method_str = "GET" if method == HTTPClient.METHOD_GET else "POST"
	var url = SUPABASE_URL + endpoint
	
	# Vor dem Request das globale JS-Objekt zurücksetzen
	JavaScriptBridge.eval("window._supabase_response = null;")
	
	var js_code = """
	(async function() {
		try {
			let response = await fetch('%s', {
				method: '%s',
				headers: {
					'apikey': '%s',
					'Authorization': 'Bearer %s',
					'Content-Type': 'application/json'
				}%s
			});
			let text = await response.text();
			window._supabase_response = { code: response.status, body: text };
		} catch(e) {
			window._supabase_response = { code: 0, body: "" };
		}
	})();
	""" % [
		url, 
		method_str, 
		PUBLISHABLE_KEY, 
		PUBLISHABLE_KEY,
		", body: '" + JSON.stringify(data) + "'" if not data.is_empty() else ""
	]
	
	JavaScriptBridge.eval(js_code)
	
	# Dynamisch warten, bis JS den Fetch beendet hat (maximal 5 Sekunden Timeout)
	var time_spent := 0.0
	var res = null
	
	while time_spent < 5.0:
		await get_tree().create_timer(0.05).timeout
		time_spent += 0.05
		res = JavaScriptBridge.eval("window._supabase_response")
		if res != null:
			break # JS hat geantwortet!

	if res != null:
		var code = int(res["code"])
		var json = JSON.new()
		var parse_res = json.parse(String(res["body"]))
		var parsed_data = json.get_data() if parse_res == OK else null
		
		# PRINT ZUM DEBUGGEN: Zeigt genau, was Supabase antwortet!
		print("WEB FETCH RESPONSE - Code: ", code, " | Data: ", parsed_data)
		
		if callback.is_valid():
			callback.call(code, parsed_data)
	else:
		print("WEB FETCH TIMEOUT")
		if callback.is_valid():
			callback.call(0, null)


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
		return null
