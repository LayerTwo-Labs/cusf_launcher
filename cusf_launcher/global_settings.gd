extends Node

var settings_shutdown_on_exit : bool = true
var settings_show_random_quotes : bool = false

# If the user installs software this keeps track of what the last modified
# date of the software on releases.drivechain.info was when installed.
# We can compare this to the last modified version on the server later in
# order to check for new versions of what is installed.
# 
# TODO We have the same release names being used in other places in the 
# software and right now they all have to be maintained when names change.
# We are trying to fill in this data with info from releases.drivechain.info
# For now release name : last modified date
# But we could also track the file size
#
# TODO other currently non functional chains:
#"L2-S0-TestSail-latest-x86_64-apple-darwin.zip" : "",
#"L2-S0-TestSail-latest-x86_64-pc-windows-msvc.zip" : "",
#"L2-S0-TestSail-latest-x86_64-unknown-linux-gnu.zip" : "",
#"L2-S2-BitNames-latest-x86_64-apple-darwin.zip" : "",
#"L2-S2-BitNames-latest-x86_64-pc-windows-gnu.zip" : "",
#"L2-S2-BitNames-latest-x86_64-unknown-linux-gnu.zip" : "",
#"L2-S5-ZSail-latest-x86_64-apple-darwin.zip" : "",
#"L2-S5-ZSail-latest-x86_64-unknown-linux-gnu.zip" : "",
#"L2-S6-EthSail-latest-x86_64-apple-darwin.zip" : "",
#"L2-S6-EthSail-latest-x86_64-pc-windows-msvc.zip" : "",
#"L2-S6-EthSail-latest-x86_64-unknown-linux-gnu.zip" : "",
#
# Software name : last modified date


var settings_installed_software_info : Dictionary = {
		"BitWindow-latest-x86_64-apple-darwin.zip" : "",
		"BitWindow-latest-x86_64-unknown-linux-gnu.zip" : "",
		"L1-bitcoin-patched-latest-x86_64-apple-darwin.zip" : "",
		"L1-bitcoin-patched-latest-x86_64-unknown-linux-gnu.zip" : "",
		"L1-bitcoin-patched-latest-x86_64-w64-msvc.zip" : "",
		"L2-S9-Thunder-latest-x86_64-apple-darwin.zip" : "",
		"L2-S9-Thunder-latest-x86_64-pc-windows-gnu.zip" : "",
		"L2-S9-Thunder-latest-x86_64-unknown-linux-gnu.zip" : "",
		"bip300301-enforcer-latest-x86_64-apple-darwin.zip" : "",
		"bip300301-enforcer-latest-x86_64-pc-windows-gnu.zip" : "",
		"bip300301-enforcer-latest-x86_64-unknown-linux-gnu.zip" : "",
		"drivechain-launcher-latest-x86_64-apple-darwin.zip" : "",
		"drivechain-launcher-latest-x86_64-unknown-linux-gnu.zip" : "",
		"drivechain-launcher-latest-x86_64-w64.zip" : "",
	}


func have_release_info() -> bool:
	# Check if any of the software info keys have a value, meaning we have 
	# read release info from releases.drivechain.info at some point
	if settings_installed_software_info.has("BitWindow-latest-x86_64-apple-darwin.zip"):
		if settings_installed_software_info["BitWindow-latest-x86_64-apple-darwin.zip"] != "":
			return true
	
	return false


func reset_version_info() -> void:
	for key in settings_installed_software_info.keys():
		settings_installed_software_info[key] = ""


func reset_user_settings() -> void:
	settings_shutdown_on_exit = true
	settings_show_random_quotes = false
	
	for key in settings_installed_software_info.keys():
		settings_installed_software_info[key] = ""


func save_settings() -> void:
	var file = FileAccess.open("user://user_settings.dat", FileAccess.WRITE)

	file.store_var(settings_shutdown_on_exit)
	file.store_var(settings_show_random_quotes)
	file.store_var(settings_installed_software_info)


func load_settings() -> void:
	if !FileAccess.file_exists("user://user_settings.dat"):
		return
		
	var file = FileAccess.open("user://user_settings.dat", FileAccess.READ)
	
	settings_shutdown_on_exit = file.get_var()
	settings_show_random_quotes = file.get_var()
	settings_installed_software_info = file.get_var()
