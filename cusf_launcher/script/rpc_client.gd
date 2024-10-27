extends Control

# TODO duplicated in configuration.gd
const DEFAULT_BITCOIN_RPC_PORT : int = 38332
#const DEFAULT_BITCOIN_RPC_PORT : int = 18443

const DEBUG_REQUESTS : bool = true

const GRPC_CUSF_DRIVECHAIN_GET_HEIGHT : String = "validator.Validator/GetMainBlockHeight"

# Signals that should be emitted regularly if connections are working
signal btc_new_block_count(height : int)
signal cusf_drivechain_new_block_count(height : int)
signal thunder_new_block_count(height : int)

# Signals that indicate connection failure to one of the backend softwares 
signal btc_rpc_failed()
signal cusf_drivechain_rpc_failed()
signal thunder_cli_failed()

# TODO not sure if we are using cookies or not,
# so just setting this here instead of loading it from the cookie for now.
var core_auth_cookie : String = "user:password"

@onready var http_rpc_btc_get_block_count: HTTPRequest = $BitcoinCoreRPC/HTTPRPCBTCGetBlockCount


func rpc_bitcoin_getblockcount() -> void:
	make_rpc_request(DEFAULT_BITCOIN_RPC_PORT, "getblockcount", [], http_rpc_btc_get_block_count)


func grpc_enforcer_getmainblockcount() -> void:
	make_grpc_request(GRPC_CUSF_DRIVECHAIN_GET_HEIGHT) 


func cli_thunder_getblockcount() -> void:
	var user_dir = OS.get_user_data_dir()
	var output = []
	var ret : int = OS.execute(str(user_dir, "/thunder-cli-latest-x86_64-unknown-linux-gnu"),
		["get-blockcount"],
	 	output,
	 	true)
	
	if DEBUG_REQUESTS:
		print("ret ", ret)
		print("output ", output)
		
	if ret != 0:
		thunder_cli_failed.emit()
	else:
		thunder_new_block_count.emit(0) # TODO


func make_grpc_request(request : String) -> void:
	var user_dir = OS.get_user_data_dir()
	var output = []
	var ret : int = OS.execute(str(user_dir, "/grpcurl"),
		["--plaintext",
	 	"--import-path",
	 	user_dir,
	 	"--proto",
	 	str(user_dir, "/validator.proto"),
	 	"[::1]:50051",
	 	request],
	 	output,
	 	true)
	
	if DEBUG_REQUESTS:
		print("ret ", ret)
		print("output ", output)
		
	# TODO check ret code
	cusf_drivechain_rpc_failed.emit()


func make_rpc_request(port : int, method: String, params: Variant, http_request: HTTPRequest) -> void:	
	var auth = get_bitcoin_core_cookie()

	if DEBUG_REQUESTS:
		print("Auth Cookie: ", auth)
		
	var auth_bytes = auth.to_utf8_buffer()
	var auth_encoded = Marshalls.raw_to_base64(auth_bytes)
	var headers: PackedStringArray = []
	headers.push_back("Authorization: Basic " + auth_encoded)
	headers.push_back("content-type: application/json")
	
	var jsonrpc := JSONRPC.new()
	var req = jsonrpc.make_request(method, params, 1)
	
	http_request.request(str("http://", auth, "@127.0.0.1:", str(port)), headers, HTTPClient.METHOD_POST, JSON.stringify(req))


func get_bitcoin_core_cookie() -> String:
	if !core_auth_cookie.is_empty():
		return core_auth_cookie
	
	# TODO are we using cookies?
	var cookie_path : String = str("", "/regtest/.cookie")
	if !FileAccess.file_exists(cookie_path):
		return ""
		
	var file = FileAccess.open(cookie_path, FileAccess.READ)
		
	core_auth_cookie = file.get_as_text()
	
	return core_auth_cookie


func parse_rpc_result(response_code, body) -> Dictionary:
	var res = {}
	var json = JSON.new()
	if response_code != 200:
		if body != null:
			var err = json.parse(body.get_string_from_utf8())
			if err == OK:
				printerr(json.get_data())
	else:
		var err = json.parse(body.get_string_from_utf8())
		if err == OK:
			res = json.get_data() as Dictionary
	
	return res
	

func _on_http_rpc_btc_get_block_count_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var res = parse_rpc_result(response_code, body)
	var height : int = 0
	if res.has("result"):
		if DEBUG_REQUESTS:
			print_debug("Result: ", res.result)
		height = res.result
		btc_new_block_count.emit(height)
	else:
		if DEBUG_REQUESTS:
			print_debug("result error")
		btc_rpc_failed.emit()
