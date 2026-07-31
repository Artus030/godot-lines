extends Node

const SUPABASE_URL: String = "https://bstflxyqetppyzgqrznv.supabase.co"
const PUBLISHABLE_KEY: String = "sb_publishable_uZs78vohlk9O21UugDP9Qw_POmPTLHY"

func request(endpoint: String, method: HTTPClient.Method, data: Dictionary, callback: Callable) -> void:
	if OS.has_feature("web"):
		_request_web(endpoint, method, data, callback)
		return

	var req = HTTPRequest.new()
	add_child(req)
	
	req.request_completed.connect(func(_res, code, _headers, body):
		if callback.is_valid():
			callback.call(code, JSON.parse_string(body.get_string_from_utf8()))
		req.queue_free()
	)

	var headers = [
		"apikey: " + PUBLISHABLE_KEY,
		"Authorization: Bearer " + PUBLISHABLE_KEY,
		"Content-Type: application/json"
	]
	if method == HTTPClient.METHOD_POST:
		headers.append("Prefer: return=minimal")

	var payload = JSON.stringify(data) if not data.is_empty() else ""
	if req.request(SUPABASE_URL + endpoint, headers, method, payload) != OK:
		if callback.is_valid(): callback.call(0, null)
		req.queue_free()


func _request_web(endpoint: String, method: HTTPClient.Method, data: Dictionary, callback: Callable) -> void:
	var cb_id = "godot_cb_" + str(Time.get_ticks_usec())
	var method_str = "GET" if method == HTTPClient.METHOD_GET else "POST"
	
	# Callback für Godot
	var js_cb = JavaScriptBridge.create_callback(func(args):
		JavaScriptBridge.get_interface("window").delete_property(cb_id)
		if callback.is_valid():
			var status_code = int(args[0])
			var raw_body = String(args[1])
			
			# Debug-Print für die Browser-Konsole (F12)
			print("WEB RESPONSE -> Code: ", status_code, " | Body: ", raw_body)
			
			var parsed_json = JSON.parse_string(raw_body)
			callback.call(status_code, parsed_json)
	)
	
	JavaScriptBridge.get_interface("window")[cb_id] = js_cb

	# Body NUR bei POST/PUT anhängen
	var body_option = ""
	if not data.is_empty() and method != HTTPClient.METHOD_GET:
		body_option = "body: JSON.stringify(%s)," % JSON.stringify(data)

	var js_code = """
	(async function() {
		try {
			let response = await fetch('%s', {
				method: '%s',
				headers: {
					'apikey': '%s',
					'Authorization': 'Bearer %s',
					'Content-Type': 'application/json'
				},
				%s
			});
			let text = await response.text();
			window['%s'](response.status, text);
		} catch(e) {
			console.error("Fetch Error:", e);
			window['%s'](0, "");
		}
	})();
	""" % [
		SUPABASE_URL + endpoint,
		method_str,
		PUBLISHABLE_KEY,
		PUBLISHABLE_KEY,
		body_option,
		cb_id,
		cb_id
	]

	JavaScriptBridge.eval(js_code)


# Helper
func get_db(endpoint: String, callback: Callable) -> void: request(endpoint, HTTPClient.METHOD_GET, {}, callback)
func post_db(endpoint: String, data: Dictionary, callback: Callable) -> void: request(endpoint, HTTPClient.METHOD_POST, data, callback)
