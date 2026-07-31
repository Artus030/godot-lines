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
	var url = SUPABASE_URL + endpoint
	var payload_json = JSON.stringify(data) if (not data.is_empty() and method != HTTPClient.METHOD_GET) else ""
	
	# Callback erstellen
	var js_cb: JavaScriptObject
	js_cb = JavaScriptBridge.create_callback(func(args):
		var status_code = int(args[0])
		var raw_body = String(args[1])
		
		print("WEB RESPONSE -> Code: ", status_code, " | Body: ", raw_body)
		
		# JS-Referenz aufräumen
		JavaScriptBridge.get_interface("window").delete_property(cb_id)
		
		if callback.is_valid():
			var parsed_json = JSON.parse_string(raw_body)
			callback.call(status_code, parsed_json)
	)
	
	# Global am window-Objekt verankern, damit JS darauf zugreifen kann
	var win = JavaScriptBridge.get_interface("window")
	win[cb_id] = js_cb

	# Reines, sauberes JavaScript ohne heikle String-Formatierungen
	var js_code = """
	(function(url, method, apiKey, payload, cbName) {
		let options = {
			method: method,
			headers: {
				'apikey': apiKey,
				'Authorization': 'Bearer ' + apiKey,
				'Content-Type': 'application/json'
			}
		};
		if (payload && method !== 'GET') {
			options.body = payload;
		}

		fetch(url, options)
			.then(response => response.text().then(text => window[cbName](response.status, text)))
			.catch(err => {
				console.error("Fetch Exception:", err);
				window[cbName](0, "");
			});
	})('%s', '%s', '%s', '%s', '%s');
	""" % [url, method_str, PUBLISHABLE_KEY, payload_json.replace("'", "\\'"), cb_id]

	JavaScriptBridge.eval(js_code)


# Helper
func get_db(endpoint: String, callback: Callable) -> void: request(endpoint, HTTPClient.METHOD_GET, {}, callback)
func post_db(endpoint: String, data: Dictionary, callback: Callable) -> void: request(endpoint, HTTPClient.METHOD_POST, data, callback)
