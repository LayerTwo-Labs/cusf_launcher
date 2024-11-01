extends Control

var DEBUG_REQUESTS : bool = false

const URL_GRPCURL_LIN : String = "https://github.com/fullstorydev/grpcurl/releases/download/v1.9.1/grpcurl_1.9.1_linux_x86_64.tar.gz"
const URL_GRPCURL_WIN : String = "https://github.com/fullstorydev/grpcurl/releases/download/v1.9.1/grpcurl_1.9.1_windows_x86_64.zip"
const URL_GRPCURL_OSX : String = "https://github.com/fullstorydev/grpcurl/releases/download/v1.9.1/grpcurl_1.9.1_osx_x86_64.tar.gz"

const URL_300301_ENFORCER_LIN  : String = "https://releases.drivechain.info/bip300301-enforcer-latest-x86_64-unknown-linux-gnu.zip"
const URL_300301_ENFORCER_WIN : String = "https://releases.drivechain.info/bip300301-enforcer-latest-x86_64-pc-windows-gnu.zip"
const URL_300301_ENFORCER_OSX : String = "https://releases.drivechain.info/bip300301-enforcer-latest-x86_64-apple-darwin.zip"

# TODO this is the wrong version for the enforcer, but I'm not sure what is correct anymore.
const URL_BITCOIN_PATCHED_LIN : String = "https://releases.drivechain.info/L1-bitcoin-patched-latest-x86_64-unknown-linux-gnu.zip"
const URL_BITCOIN_PATCHED_WIN : String = "https://releases.drivechain.info/L1-bitcoin-patched-latest-x86_64-w64-mingw32.zip"
const URL_BITCOIN_PATCHED_OSX : String = "https://releases.drivechain.info/L1-bitcoin-patched-latest-x86_64-apple-darwin.zip"

const URL_THUNDER_LIN : String = "https://releases.drivechain.info/L2-S9-Thunder-latest-x86_64-unknown-linux-gnu.zip"
const URL_THUNDER_WIN : String = "https://releases.drivechain.info/L2-S9-Thunder-latest-x86_64-pc-windows-gnu.zip"
const URL_THUNDER_OSX : String = "https://releases.drivechain.info/L2-S9-Thunder-latest-x86_64-apple-darwin.zip"

# GRPCURL is released as a .zip for windows and .tar.gz for anything else:
const DOWNLOAD_PATH_GRPCURL_LIN_OSX = "user://grpcurl.tar.gz"
const DOWNLOAD_PATH_GRPCURL_WIN = "user://grpcurl.zip"

@onready var http_download_grpcurl: HTTPRequest = $HTTPDownloadGRPCURL
@onready var http_download_enforcer: HTTPRequest = $HTTPDownloadEnforcer
@onready var http_download_bitcoin: HTTPRequest = $HTTPDownloadBitcoin
@onready var http_download_thunder: HTTPRequest = $HTTPDownloadThunder

var located_grpcurl : bool = false
var located_enforcer : bool = false
var located_bitcoin : bool = false
var located_thunder : bool = false

signal resource_grpcurl_ready
signal resource_bitcoin_ready
signal resource_enforcer_ready
signal resource_thunder_ready

func have_grpcurl() -> bool:
	if located_grpcurl:
		return true
	
	if !FileAccess.file_exists("user://grpcurl"):
		return false
	
	resource_grpcurl_ready.emit()
	
	located_grpcurl = true
	return true


func have_enforcer() -> bool:
	if located_enforcer:
		return true
	
	if !FileAccess.file_exists("user://bip300301-enforcer-latest-x86_64-unknown-linux-gnu/bip300301_enforcer-0.1.0-x86_64-unknown-linux-gnu"):
		return false
	
	resource_enforcer_ready.emit()
	
	located_enforcer = true
	return true
	
	
func have_bitcoin() -> bool:
	if located_bitcoin:
		return true
	
	match OS.get_name():
		"Linux":
			if !FileAccess.file_exists("user://L1-bitcoin-patched-latest-x86_64-unknown-linux-gnu/qt/bitcoin-qt"):
				return false
		"Windows":
			if !FileAccess.file_exists("user://L1-bitcoin-patched-latest-x86_64-pc-windows-gnu/qt/bitcoin-qt"):
				return false
		"macOS":
			# TODO correct path
			if !FileAccess.file_exists("user://L1-bitcoin-patched-latest-x86_64-unknown-linux-gnu/qt/bitcoin-qt"):
				return false

	resource_bitcoin_ready.emit()
	
	located_bitcoin = true
	return true


func have_thunder() -> bool:
	if located_thunder:
		return true
	
	match OS.get_name():
		"Linux":
			if !FileAccess.file_exists("user://thunder-latest-x86_64-unknown-linux-gnu"):
				return false
		"Windows":
			if !FileAccess.file_exists("user://thunder-latest-x86_64-pc-windows-gnu"):
				return false
		"macOS":
			# TODO correct path
			if !FileAccess.file_exists("user://thunder-latest-x86_64-unknown-linux-gnu"):
				return false

	resource_thunder_ready.emit()
	
	located_thunder = true
	return true
	
	
func download_grpcurl() -> void:
	if have_grpcurl():
		return
		
	match OS.get_name():
		"Linux":
			$HTTPDownloadGRPCURL.download_file = DOWNLOAD_PATH_GRPCURL_LIN_OSX
			$HTTPDownloadGRPCURL.request(URL_GRPCURL_LIN)
		"Windows":
			$HTTPDownloadGRPCURL.download_file = DOWNLOAD_PATH_GRPCURL_WIN
			$HTTPDownloadGRPCURL.request(URL_GRPCURL_WIN)
		"macOS":
			$HTTPDownloadGRPCURL.download_file = DOWNLOAD_PATH_GRPCURL_LIN_OSX
			$HTTPDownloadGRPCURL.request(URL_GRPCURL_OSX)


func download_enforcer() -> void:
	if have_enforcer():
		return
	
	match OS.get_name():
		"Linux":
			$HTTPDownloadEnforcer.request(URL_300301_ENFORCER_LIN)
		"Windows":
			$HTTPDownloadEnforcer.request(URL_300301_ENFORCER_WIN)
		"macOS":
			$HTTPDownloadEnforcer.request(URL_300301_ENFORCER_OSX)


func download_bitcoin() -> void:
	if have_bitcoin():
		return
		
	match OS.get_name():
		"Linux":
			$HTTPDownloadBitcoin.request(URL_BITCOIN_PATCHED_LIN)
		"Windows":
			$HTTPDownloadBitcoin.request(URL_BITCOIN_PATCHED_WIN)
		"macOS":
			$HTTPDownloadBitcoin.request(URL_BITCOIN_PATCHED_OSX)


func download_thunder() -> void:
	if have_thunder():
		return
		
	match OS.get_name():
		"Linux":
			$HTTPDownloadThunder.request(URL_THUNDER_LIN)
		"Windows":
			$HTTPDownloadThunder.request(URL_THUNDER_WIN)
		"macOS":
			$HTTPDownloadThunder.request(URL_THUNDER_OSX)


func extract_grpcurl() -> void:
	var user_dir : String = OS.get_user_data_dir() 
	
	var ret : int = -1 
	match OS.get_name():
		"Linux":
			ret = OS.execute("tar", ["-xzf", str(user_dir, "/grpcurl.tar.gz"), "-C", user_dir])
		"Windows":
			ret = OS.execute("tar", ["-C", user_dir, "-xf", str(user_dir, "/grpcurl.zip")])
		"macOS":
			ret = OS.execute("tar", ["-xzf", str(user_dir, "/grpcurl.tar.gz"), "-C", user_dir])

	if ret != OK:
		printerr("Failed to extract grpcurl")
		return
		
	resource_grpcurl_ready.emit()


func extract_enforcer() -> void:
	var user_dir : String = OS.get_user_data_dir() 
	
	var ret : int = -1
	match OS.get_name():
		"Linux":
			ret = OS.execute("unzip", ["-o", "-d", user_dir, str(user_dir, "/300301enforcer.zip")])
		"Windows":
			ret = OS.execute("tar", ["-C", user_dir, "-xf", str(user_dir, "/300301enforcer.zip")])
		"macOS":
			ret = OS.execute("unzip", ["-o", "-d", user_dir, str(user_dir, "/300301enforcer.zip")])

	if ret != OK:
		printerr("Failed to extract enforcer")
		return

	# Make executable for linux # TODO osx?
	if OS.get_name() == "Linux":
		ret = OS.execute("chmod", ["+x", str(user_dir, "/bip300301-enforcer-latest-x86_64-unknown-linux-gnu/bip300301_enforcer-0.1.0-x86_64-unknown-linux-gnu")])
		if ret != OK:
			printerr("Failed to mark enforcer executable")
			return

	resource_enforcer_ready.emit()


func extract_bitcoin() -> void:
	var user_dir : String = OS.get_user_data_dir() 
	
	var ret : int = -1
	match OS.get_name():
		"Linux":
			ret = OS.execute("unzip", ["-o", "-d", user_dir, str(user_dir, "/bitcoinpatched.zip")])
		"Windows":
			ret = OS.execute("tar", ["-C", user_dir, "-xf", str(user_dir, "/bitcoinpatched.zip")])
		"macOS":
			ret = OS.execute("unzip", ["-o", "-d", user_dir, str(user_dir, "/bitcoinpatched.zip")])

	if ret != OK:
		printerr("Failed to extract bitcoin")
		return
		
	# Make executable for linux # TODO osx?
	if OS.get_name() == "Linux":
		ret = OS.execute("chmod", ["+x", str(user_dir, "/L1-bitcoin-patched-latest-x86_64-unknown-linux-gnu/qt/bitcoin-qt")])
		if ret != OK:
			printerr("Failed to mark bitcoin executable")
			return
	
	resource_bitcoin_ready.emit()


func extract_thunder() -> void:
	var user_dir : String = OS.get_user_data_dir() 
	
	var ret : int = -1
	match OS.get_name():
		"Linux":
			ret = OS.execute("unzip", ["-o", "-d", user_dir, str(user_dir, "/thunder.zip")])
		"Windows":
			ret = OS.execute("tar", ["-C", user_dir, "-xf", str(user_dir, "/thunder.zip")])
		"macOS":
			ret = OS.execute("unzip", ["-o", "-d", user_dir, str(user_dir, "/thunder.zip")])

	if ret != OK:
		printerr("Failed to extract thunder")
		return

	# Make executable for linux # TODO osx?
	if OS.get_name() == "Linux":
		ret = OS.execute("chmod", ["+x", str(user_dir, "/thunder-cli-latest-x86_64-unknown-linux-gnu")])
		if ret != OK:
			printerr("Failed to mark thunder-cli executable")
			return
			
		ret = OS.execute("chmod", ["+x", str(user_dir, "/thunder-latest-x86_64-unknown-linux-gnu")])
		if ret != OK:
			printerr("Failed to mark thunder executable")
			return
	
	resource_thunder_ready.emit()


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


func _on_http_download_thunder_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result != OK:
		printerr("Failed to download thunder")
		return 
	
	if DEBUG_REQUESTS:
		print("res ", result)
		print("code ", response_code)
		print("Downloaded thunder zip")
	
	extract_thunder()
