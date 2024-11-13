extends Control

var DEBUG_REQUESTS : bool = false

const URL_GRPCURL_LIN : String = "https://github.com/fullstorydev/grpcurl/releases/download/v1.9.1/grpcurl_1.9.1_linux_x86_64.tar.gz"
const URL_GRPCURL_WIN : String = "https://github.com/fullstorydev/grpcurl/releases/download/v1.9.1/grpcurl_1.9.1_windows_x86_64.zip"
const URL_GRPCURL_OSX : String = "https://github.com/fullstorydev/grpcurl/releases/download/v1.9.1/grpcurl_1.9.1_osx_x86_64.tar.gz"

const URL_300301_ENFORCER_LIN  : String = "https://releases.drivechain.info/bip300301-enforcer-latest-x86_64-unknown-linux-gnu.zip"
const URL_300301_ENFORCER_WIN : String = "https://releases.drivechain.info/bip300301-enforcer-latest-x86_64-pc-windows-gnu.zip"
const URL_300301_ENFORCER_OSX : String = "https://releases.drivechain.info/bip300301-enforcer-latest-x86_64-apple-darwin.zip"

const URL_BITCOIN_PATCHED_LIN : String = "https://releases.drivechain.info/L1-bitcoin-patched-latest-x86_64-unknown-linux-gnu.zip"
const URL_BITCOIN_PATCHED_WIN : String = "https://releases.drivechain.info/L1-bitcoin-patched-latest-x86_64-w64-msvc.zip"
const URL_BITCOIN_PATCHED_OSX : String = "https://releases.drivechain.info/L1-bitcoin-patched-latest-x86_64-apple-darwin.zip"

const URL_BITWINDOW_LIN : String = "https://releases.drivechain.info/BitWindow-latest-x86_64-unknown-linux-gnu.zip"
const URL_BITWINDOW_WIN : String = "https://releases.drivechain.info/BitWindow-latest-x86_64-pc-windows-msvc.zip"
const URL_BITWINDOW_OSX : String = "https://releases.drivechain.info/BitWindow-latest-x86_64-apple-darwin.zip"

const URL_THUNDER_LIN : String = "https://releases.drivechain.info/L2-S9-Thunder-latest-x86_64-unknown-linux-gnu.zip"
const URL_THUNDER_WIN : String = "https://releases.drivechain.info/L2-S9-Thunder-latest-x86_64-pc-windows-gnu.zip"
const URL_THUNDER_OSX : String = "https://releases.drivechain.info/L2-S9-Thunder-latest-x86_64-apple-darwin.zip"

# GRPCURL is released as a .zip for windows and .tar.gz for anything else:
const DOWNLOAD_PATH_GRPCURL_LIN_OSX = "user://downloads/grpcurl.tar.gz"
const DOWNLOAD_PATH_GRPCURL_WIN = "user://downloads/grpcurl.zip"

@onready var http_download_grpcurl: HTTPRequest = $HTTPDownloadGRPCURL
@onready var http_download_enforcer: HTTPRequest = $HTTPDownloadEnforcer
@onready var http_download_bitcoin: HTTPRequest = $HTTPDownloadBitcoin
@onready var http_download_thunder: HTTPRequest = $HTTPDownloadThunder
@onready var http_download_bit_window: HTTPRequest = $HTTPDownloadBitWindow

var located_grpcurl : bool = false
var located_enforcer : bool = false
var located_bitcoin : bool = false
var located_bitwindow : bool = false
var located_thunder : bool = false

signal resource_grpcurl_ready
signal resource_bitcoin_ready
signal resource_bitwindow_ready
signal resource_enforcer_ready
signal resource_thunder_ready

func have_grpcurl() -> bool:
	if located_grpcurl:
		return true
		
	match OS.get_name():
		"Linux":
			if !FileAccess.file_exists("user://downloads/grpcurl"):
				return false
		"Windows":
			if !FileAccess.file_exists("user://downloads/grpcurl.exe"):
				return false
		"macOS":
			# TODO correct path
			if !FileAccess.file_exists("user://downloads/grpcurl"):
				return false
				
	resource_grpcurl_ready.emit()
	
	located_grpcurl = true
	return true


func have_enforcer() -> bool:
	if located_enforcer:
		return true
	
	match OS.get_name():
		"Linux":
			if !FileAccess.file_exists("user://downloads/bip300301-enforcer-latest-x86_64-unknown-linux-gnu/bip300301_enforcer-0.1.0-x86_64-unknown-linux-gnu"):
				return false
		"Windows":
			# TODO the folder name has .exe which is probably an accident. 
			# Maybe an issue with the github actions?
			if !FileAccess.file_exists("user://downloads/bip300301-enforcer-latest-x86_64-pc-windows-gnu.exe/bip300301_enforcer-0.1.0-x86_64-pc-windows-gnu.exe"):
				return false
		"macOS":
			# TODO correct path
			if !FileAccess.file_exists("user://downloads/bip300301-enforcer-latest-x86_64-unknown-linux-gnu/bip300301_enforcer-0.1.0-x86_64-unknown-linux-gnu"):
				return false
	
	resource_enforcer_ready.emit()
	
	located_enforcer = true
	return true
	
	
func have_bitcoin() -> bool:
	if located_bitcoin:
		return true
	
	match OS.get_name():
		"Linux":
			if !FileAccess.file_exists("user://downloads/L1-bitcoin-patched-latest-x86_64-unknown-linux-gnu/qt/bitcoin-qt"):
				return false
		"Windows":
			if !FileAccess.file_exists("user://downloads/L1-bitcoin-patched-latest-x86_64-w64-mingw32/qt/bitcoin-qt.exe"):
				return false
		"macOS":
			# TODO correct path
			if !FileAccess.file_exists("user://downloads/L1-bitcoin-patched-latest-x86_64-unknown-linux-gnu/qt/bitcoin-qt"):
				return false

	resource_bitcoin_ready.emit()
	
	located_bitcoin = true
	return true


func have_bitwindow() -> bool:
	if located_bitwindow:
		return true
	
	match OS.get_name():
		"Linux":
			if !FileAccess.file_exists("user://downloads/BitWindow-latest-x86_64-unknown-linux-gnu/bitwindow"):
				return false
		"Windows":
			if !FileAccess.file_exists("user://downloads/BitWindow-latest-x86_64-pc-windows-msvc/bitwindow.exe"):
				return false
		"macOS":
			# TODO correct path
			if !FileAccess.file_exists("user://downloads/BitWindow-latest-???/bitwindow"):
				return false

	resource_bitwindow_ready.emit()
	
	located_bitwindow = true
	return true


func have_thunder() -> bool:
	if located_thunder:
		return true
	
	match OS.get_name():
		"Linux":
			if !FileAccess.file_exists("user://downloads/thunder-latest-x86_64-unknown-linux-gnu"):
				return false
		"Windows":
			if !FileAccess.file_exists("user://downloads/thunder-latest-x86_64-pc-windows-gnu.exe"):
				return false
		"macOS":
			# TODO correct path
			if !FileAccess.file_exists("user://downloads/thunder-latest-x86_64-unknown-linux-gnu"):
				return false

	resource_thunder_ready.emit()
	
	located_thunder = true
	return true
	
	
func download_grpcurl() -> void:
	if have_grpcurl():
		return
		
	DirAccess.make_dir_absolute("user://downloads/")
		
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
		
	DirAccess.make_dir_absolute("user://downloads/")

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

	DirAccess.make_dir_absolute("user://downloads/")

	match OS.get_name():
		"Linux":
			$HTTPDownloadBitcoin.request(URL_BITCOIN_PATCHED_LIN)
		"Windows":
			$HTTPDownloadBitcoin.request(URL_BITCOIN_PATCHED_WIN)
		"macOS":
			$HTTPDownloadBitcoin.request(URL_BITCOIN_PATCHED_OSX)


func download_bitwindow() -> void:
	if have_bitwindow():
		return

	DirAccess.make_dir_absolute("user://downloads/")

	match OS.get_name():
		"Linux":
			$HTTPDownloadBitWindow.request(URL_BITWINDOW_LIN)
		"Windows":
			$HTTPDownloadBitWindow.request(URL_BITWINDOW_WIN)
		"macOS":
			$HTTPDownloadBitWindow.request(URL_BITWINDOW_OSX)


func download_thunder() -> void:
	if have_thunder():
		return

	DirAccess.make_dir_absolute("user://downloads/")

	match OS.get_name():
		"Linux":
			$HTTPDownloadThunder.request(URL_THUNDER_LIN)
		"Windows":
			$HTTPDownloadThunder.request(URL_THUNDER_WIN)
		"macOS":
			$HTTPDownloadThunder.request(URL_THUNDER_OSX)


func extract_grpcurl() -> void:
	var downloads_dir = str(OS.get_user_data_dir(), "/downloads")
	
	var ret : int = -1 
	match OS.get_name():
		"Linux":
			ret = OS.execute("tar", ["-xzf", str(downloads_dir, "/grpcurl.tar.gz"), "-C", downloads_dir])
		"Windows":
			ret = OS.execute("tar", ["-C", downloads_dir, "-xf", str(downloads_dir, "/grpcurl.zip")])
		"macOS":
			ret = OS.execute("tar", ["-xzf", str(downloads_dir, "/grpcurl.tar.gz"), "-C", downloads_dir])

	if ret != OK:
		printerr("Failed to extract grpcurl")
		return
		
	resource_grpcurl_ready.emit()


func extract_enforcer() -> void:
	var downloads_dir = str(OS.get_user_data_dir(), "/downloads")

	var ret : int = -1
	match OS.get_name():
		"Linux":
			ret = OS.execute("unzip", ["-o", "-d", downloads_dir, str(downloads_dir, "/300301enforcer.zip")])
		"Windows":
			ret = OS.execute("tar", ["-C", downloads_dir, "-xf", str(downloads_dir, "/300301enforcer.zip")])
		"macOS":
			ret = OS.execute("unzip", ["-o", "-d", downloads_dir, str(downloads_dir, "/300301enforcer.zip")])

	if ret != OK:
		printerr("Failed to extract enforcer")
		return

	# Make executable for linux # TODO osx?
	if OS.get_name() == "Linux":
		ret = OS.execute("chmod", ["+x", str(downloads_dir, "/bip300301-enforcer-latest-x86_64-unknown-linux-gnu/bip300301_enforcer-0.1.0-x86_64-unknown-linux-gnu")])
		if ret != OK:
			printerr("Failed to mark enforcer executable")
			return

	resource_enforcer_ready.emit()


func extract_bitcoin() -> void:
	var downloads_dir = str(OS.get_user_data_dir(), "/downloads")

	var ret : int = -1
	match OS.get_name():
		"Linux":
			ret = OS.execute("unzip", ["-o", "-d", downloads_dir, str(downloads_dir, "/bitcoinpatched.zip")])
		"Windows":
			ret = OS.execute("tar", ["-C", downloads_dir, "-xf", str(downloads_dir, "/bitcoinpatched.zip")])
		"macOS":
			ret = OS.execute("unzip", ["-o", "-d", downloads_dir, str(downloads_dir, "/bitcoinpatched.zip")])

	if ret != OK:
		printerr("Failed to extract bitcoin")
		return
		
	# Make executable for linux # TODO osx?
	if OS.get_name() == "Linux":
		ret = OS.execute("chmod", ["+x", str(downloads_dir, "/L1-bitcoin-patched-latest-x86_64-unknown-linux-gnu/qt/bitcoin-qt")])
		if ret != OK:
			printerr("Failed to mark bitcoin executable")
			return
	
	resource_bitcoin_ready.emit()


func extract_bitwindow() -> void:
	var downloads_dir = str(OS.get_user_data_dir(), "/downloads")

	var ret : int = -1
	match OS.get_name():
		"Linux":
			ret = OS.execute("unzip", ["-o", "-d", downloads_dir, str(downloads_dir, "/bitwindow.zip")])
		"Windows":
			ret = OS.execute("tar", ["-C", downloads_dir, "-xf", str(downloads_dir, "/bitwindow.zip")])
		"macOS":
			ret = OS.execute("unzip", ["-o", "-d", downloads_dir, str(downloads_dir, "/bitwindow.zip")])

	if ret != OK:
		printerr("Failed to extract bitwindow")
		return
		
	# Make executable for linux # TODO osx?
	if OS.get_name() == "Linux":
		ret = OS.execute("chmod", ["+x", str(downloads_dir, "/BitWindow-latest-x86_64-unknown-linux-gnu/bitwindow")])
		if ret != OK:
			printerr("Failed to mark bitwindow executable")
			return
	
	resource_bitwindow_ready.emit()


func extract_thunder() -> void:
	var downloads_dir = str(OS.get_user_data_dir(), "/downloads")
	
	var ret : int = -1
	match OS.get_name():
		"Linux":
			ret = OS.execute("unzip", ["-o", "-d", downloads_dir, str(downloads_dir, "/thunder.zip")])
		"Windows":
			ret = OS.execute("tar", ["-C", downloads_dir, "-xf", str(downloads_dir, "/thunder.zip")])
		"macOS":
			ret = OS.execute("unzip", ["-o", "-d", downloads_dir, str(downloads_dir, "/thunder.zip")])

	if ret != OK:
		printerr("Failed to extract thunder")
		return

	# Make executable for linux # TODO osx?
	if OS.get_name() == "Linux":
		ret = OS.execute("chmod", ["+x", str(downloads_dir, "/thunder-cli-latest-x86_64-unknown-linux-gnu")])
		if ret != OK:
			printerr("Failed to mark thunder-cli executable")
			return
			
		ret = OS.execute("chmod", ["+x", str(downloads_dir, "/thunder-latest-x86_64-unknown-linux-gnu")])
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
	
	# TODO extract in thread so window doesn't freeze
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


func _on_http_download_bit_window_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result != OK:
		printerr("Failed to download bitwindow")
		return 
	
	if DEBUG_REQUESTS:
		print("res ", result)
		print("code ", response_code)
		print("Downloaded bitwindow zip")
	
	# TODO extract in thread so window doesn't freeze
	extract_bitwindow()
