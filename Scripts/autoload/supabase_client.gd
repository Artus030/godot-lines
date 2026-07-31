extends Node

const SUPABASE_URL: String = "https://bstflxyqetppyzgqrznv.supabase.co"
const PUBLISHABLE_KEY: String = "sb_publishable_uZs78vohlk9O21UugDP9Qw_POmPTLHY"

func request(endpoint: String, method: HTTPClient.Method, data: Dictionary, callback: Callable) -> void:
	print("--- REQUEST AUFGERUFEN --- Web-Feature aktiv? ", OS.has_feature("web"))
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
	
	var payload_str = ""
	if not data.is_empty() and method != HTTPClient.METHOD_GET:
		payload_str = JSON.stringify(data)

	# 1. Das GDScript-Callback erstellen
	var js_cb = JavaScriptBridge.create_callback(func(args):
		JavaScriptBridge.get_interface("window").delete_property(cb_id)
		
		var status_code = int(args[0])
		var raw_body = String(args[1])
		
		print("WEB CALLBACK ERREICHT! Status: ", status_code)
		
		if callback.is_valid():
			var parsed_json = JSON.parse_string(raw_body)
			if parsed_json == null:
				parsed_json = []
			
			callback.call(status_code, parsed_json)
	)
	
	# 2. Variablen sicher im JS-Window speichern (verhindert Escaping-Fehler!)
	var win = JavaScriptBridge.get_interface("window")
	win[cb_id] = js_cb
	win["_temp_url"] = url
	win["_temp_method"] = method_str
	win["_temp_key"] = PUBLISHABLE_KEY
	win["_temp_payload"] = payload_str
	win["_temp_cb_name"] = cb_id

	# 3. JavaScript ausführen (greift direkt auf die JS-Variablen zu)
	var js_code = """
	(async function() {
		let url = window._temp_url;
		let method = window._temp_method;
		let apiKey = window._temp_key;
		let payload = window._temp_payload;
		let cbName = window._temp_cb_name;

		// Aufräumen
		delete window._temp_url;
		delete window._temp_method;
		delete window._temp_key;
		delete window._temp_payload;
		delete window._temp_cb_name;

		let options = {
			method: method,
			headers: {
				'apikey': apiKey,
				'Authorization': 'Bearer ' + apiKey,
				'Content-Type': 'application/json'
			}
		};

		if (payload && payload.length > 0 && method !== 'GET') {
			options.body = payload;
		}

		try {
			console.log("[Godot-Fetch] Sende Request an:", url);
			let response = await fetch(url, options);
			let text = await response.text();
			
			console.log("[Godot-Fetch] Antwort erhalten mit Status:", response.status);
			if (window[cbName]) {
				window[cbName](response.status, text);
			}
		} catch(err) {
			console.error('[Godot-Fetch] Netzwerk-Fehler:', err);
			if (window[cbName]) {
				window[cbName](0, "[]");
			}
		}
	})();
	"""

	JavaScriptBridge.eval(js_code)


# Helper
func get_db(endpoint: String, callback: Callable) -> void: request(endpoint, HTTPClient.METHOD_GET, {}, callback)
func post_db(endpoint: String, data: Dictionary, callback: Callable) -> void: request(endpoint, HTTPClient.METHOD_POST, data, callback)
