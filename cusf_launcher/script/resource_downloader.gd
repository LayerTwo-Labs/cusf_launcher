extends Control

var DEBUG_REQUESTS : bool = false

const URL_GRPCURL : String = "https://github.com/fullstorydev/grpcurl/releases/download/v1.9.1/grpcurl_1.9.1_linux_x86_64.tar.gz"
const URL_300301_ENFORCER : String = "https://releases.drivechain.info/bip300301-enforcer-latest-x86_64-unknown-linux-gnu.zip"
const URL_BITCOIN_PATCHED : String = "https://releases.drivechain.info/L1-bitcoin-patched-header-signature-rebase-latest-x86_64-unknown-linux-gnu.zip"

@onready var http_download_grpcurl: HTTPRequest = $HTTPDownloadGRPCURL
@onready var http_download_enforcer: HTTPRequest = $HTTPDownloadEnforcer
@onready var http_download_bitcoin: HTTPRequest = $HTTPDownloadBitcoin

var located_grpcurl : bool = false
var located_enforcer : bool = false
var located_bitcoin : bool = false

func have_grpcurl() -> bool:
	if located_grpcurl:
		return true
	
	if !FileAccess.file_exists("user://grpcurl"):
		return false
	
	located_grpcurl = true
	return true


func have_enforcer() -> bool:
	if located_enforcer:
		return true
	
	if !FileAccess.file_exists("user://bip300301-enforcer-latest-x86_64-unknown-linux-gnu/bip300301_enforcer-0.1.0-x86_64-unknown-linux-gnu"):
		return false
	
	located_enforcer = true
	return true
	
	
func have_bitcoin() -> bool:
	if located_bitcoin:
		return true
	
	if !FileAccess.file_exists("user://L1-bitcoin-patched-header-signature-rebase-latest-x86_64-unknown-linux-gnu/bitcoind"):
		return false
	
	located_bitcoin = true
	return true


func download_grpcurl() -> void:
	if have_grpcurl():
		return
		
	$HTTPDownloadGRPCURL.request(URL_GRPCURL)


func download_enforcer() -> void:
	if have_enforcer():
		return
		
	$HTTPDownloadEnforcer.request(URL_300301_ENFORCER)


func download_bitcoin() -> void:
	if have_bitcoin():
		return
		
	$HTTPDownloadBitcoin.request(URL_BITCOIN_PATCHED)


func extract_grpcurl() -> void:
	var user_dir : String = OS.get_user_data_dir() 
	var ret : int = OS.execute("tar", ["-xzf", str(user_dir, "/grpcurl.tar.gz"), "-C", user_dir])
	if ret != OK:
		printerr("Failed to extract grpcurl")


func extract_enforcer() -> void:
	var user_dir : String = OS.get_user_data_dir() 
	var ret : int = OS.execute("unzip", ["-o", "-d", user_dir, str(user_dir, "/300301enforcer.zip")])
	if ret != OK:
		printerr("Failed to extract enforcer")


func extract_bitcoin() -> void:
	var user_dir : String = OS.get_user_data_dir() 
	var ret : int = OS.execute("unzip", ["-o", "-d", user_dir, str(user_dir, "/bitcoinpatched.zip")])
	if ret != OK:
		printerr("Failed to extract bitcoin")
	
	# Make executable
	ret = OS.execute("chmod", [str(user_dir, "/L1-bitcoin-patched-header-signature-rebase-latest-x86_64-unknown-linux-gnu/bitcoind"), "+x"])
	if ret != OK:
		printerr("Failed to mark bitcoin executable")
	
	
func _on_http_download_grpcurl_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result != OK:
		printerr("Failed to download grpcurl")
		return 
	
	if DEBUG_REQUESTS:
		print("res ", result)
		print("code ", response_code)
		print("Downloaded grpcurl tarball")
	
	extract_grpcurl()


func _on_http_download_enforcer_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result != OK:
		printerr("Failed to download enforcer")
		return 
	
	if DEBUG_REQUESTS:
		print("res ", result)
		print("code ", response_code)
		print("Downloaded enforcer zip")
	
	extract_enforcer()


func _on_http_download_bitcoin_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result != OK:
		printerr("Failed to download bitcoin")
		return 
	
	if DEBUG_REQUESTS:
		print("res ", result)
		print("code ", response_code)
		print("Downloaded bitcoin zip")
	
	extract_bitcoin()
