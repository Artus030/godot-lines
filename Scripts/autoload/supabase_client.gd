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
	
	# Callback erstellen & aufräumen
	var js_cb = JavaScriptBridge.create_callback(func(args):
		JavaScriptBridge.get_interface("window").delete_property(cb_id)
		if callback.is_valid():
			callback.call(int(args[0]), JSON.parse_string(String(args[1])))
	)
	JavaScriptBridge.get_interface("window")[cb_id] = js_cb

	# Kompakter JS-Fetch
	var body_js = ", body: '%s'" % JSON.stringify(data) if not data.is_empty() and method != HTTPClient.METHOD_GET else ""
	var js_code = """
	fetch('%s', { method: '%s', headers: {'apikey': '%s', 'Authorization': 'Bearer %s', 'Content-Type': 'application/json'} %s })
		.then(r => r.text().then(t => window['%s'](r.status, t)))
		.catch(e => window['%s'](0, ""));
	""" % [SUPABASE_URL + endpoint, "GET" if method == HTTPClient.METHOD_GET else "POST", PUBLISHABLE_KEY, PUBLISHABLE_KEY, body_js, cb_id, cb_id]

	JavaScriptBridge.eval(js_code)


# Helper
func get_db(endpoint: String, callback: Callable) -> void: request(endpoint, HTTPClient.METHOD_GET, {}, callback)
func post_db(endpoint: String, data: Dictionary, callback: Callable) -> void: request(endpoint, HTTPClient.METHOD_POST, data, callback)
