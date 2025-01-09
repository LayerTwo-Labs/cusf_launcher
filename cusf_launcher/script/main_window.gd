extends Control

const RUN_STATUS_UPDATE_DELAY : int = 10

const RANDOM_QUOTE_UPDATE_DELAY : int = 10

# For now we track L1 resource status here, and L2 resource status 
# individually per L2 using L2Status scene
var resource_bitcoin_ready : bool = false
var resource_bitwindow_ready : bool = false
var resource_grpcurl_ready : bool = false
var resource_enforcer_ready : bool = false
var configuration_complete : bool = false

var pid_bitcoin : int = -1
var pid_bitwindow : int = -1
var pid_enforcer : int = -1
# TODO maybe move this to L2Status
var pid_thunder : int = -1

var timer_run_status_update = null

var timer_random_quote = null
var current_random_quote : String = ""

var random_quotes = [
	"I'm sure that in 20 years there will either be very large transaction volume or no volume. -Satoshi Nakamoto",
	"Poorly paid labor is inefficient labor, the world over. -Henry George",
	"Resistance to tyranny is obedience to God. -Thomas Jefferson",
]

func _ready() -> void:
	get_tree().set_auto_accept_quit(false)

	if ClassDB.class_exists("Ripemd160"):
		print("✓ CusfLauncherCrypto extension loaded successfully")
	else:
		push_error("❌ Failed to load CusfLauncherCrypto extension!")
	
	# Create timer to check on running state of L1 and L2 software
	timer_run_status_update = Timer.new()
	add_child(timer_run_status_update)
	timer_run_status_update.connect("timeout", check_running_status)
	
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/L2StatusThunder.set_l2_info("Thunder", "LN Support Chain")
	
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/TextureButtonRemoveL1.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/TextureButtonStopL1.visible = false
	
	# Hide launcher update panel
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerLauncherUpdate.visible = false
	
	# Hide L1 buttons 
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/TextureButtonSetupL1.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/TextureButtonStartL1.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/TextureButtonRemoveL1.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/TextureButtonStopL1.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/TextureButtonUpdateL1.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/MarginContainer/RichTextLabelUpdateL1.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/MarginContainer/RichTextLabelInstallL1.visible = false
	
	call_deferred("load_user_settings")
	call_deferred("initial_version_check")
	call_deferred("check_resources")
	call_deferred("display_resource_status")
	call_deferred("update_os_info")


func _exit_tree() -> void:
	if $"/root/GlobalSettings".settings_shutdown_on_exit:
		kill_started_pid()


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		$"/root/GlobalSettings".save_settings()
		if $"/root/GlobalSettings".settings_shutdown_on_exit:
			shutdown_everything()
		else:
			get_tree().quit()


func _on_button_force_shutdown_pressed() -> void:
	get_tree().quit()


func load_user_settings() -> void:
	$"/root/GlobalSettings".load_settings()


func shutdown_everything() -> void:
	$LauncherShutdownStatus.visible = true

	kill_started_pid()
	await get_tree().create_timer(10).timeout
	get_tree().quit()


func kill_l1_pid() -> void:
	timer_run_status_update.stop()
	
	# Send bitcoind a stop request and wait
	$RPCClient.rpc_bitcoin_stop()
	
	# TODO since this can take a random amount of time, wait for a completion
	# signal instead of 5 seconds
	await get_tree().create_timer(5).timeout
	
	if pid_bitcoin != -1:
		print("Killing bitcoin pid ", pid_bitcoin)
		OS.kill(pid_bitcoin)
		
	if pid_bitwindow != -1:
		print("Killing bitwindow pid ", pid_bitwindow)
		OS.kill(pid_bitwindow)
	
	if pid_enforcer != -1:
		print("Killing enforcer pid ", pid_enforcer)
		OS.kill(pid_enforcer)
		
	pid_bitcoin = -1
	pid_bitwindow = -1
	pid_enforcer = -1


# TODO move to l2 status scene
func kill_l2_pid() -> void:
	if pid_thunder != -1:
		print("Killing thunder pid ", pid_thunder)
		OS.kill(pid_thunder)

	pid_thunder = -1


func kill_started_pid() -> void:
	kill_l1_pid()
	kill_l2_pid()


func check_running_status() -> void:
	if pid_bitcoin != -1:
		$RPCClient.rpc_bitcoin_getblockcount()
		
	if pid_enforcer != -1:
		$RPCClient.grpc_enforcer_gettip()
	
	if pid_bitwindow != -1:
		pass
		# TODO check on bitwindow somehow


func _on_downloader_resource_bitcoin_ready() -> void:
	resource_bitcoin_ready = true
	display_resource_status()


func _on_downloader_resource_bitwindow_ready() -> void:
	resource_bitwindow_ready = true
	display_resource_status()


func _on_downloader_resource_enforcer_ready() -> void:
	resource_enforcer_ready = true
	display_resource_status()
	

func _on_downloader_resource_grpcurl_ready() -> void:
	resource_grpcurl_ready = true
	display_resource_status()


func _on_configuration_complete() -> void:
	configuration_complete = true
	display_resource_status()


func initial_version_check() -> void:
	# If we haven't parsed software version info from the release server yet,
	# do that now. If we don't have any version info yet, then signals for
	# updated software will not be triggered, we are just populating the dict
	if !$"/root/GlobalSettings".have_release_info():
		$ResourceDownloader.check_for_updates()	


func check_resources() -> void:
	# Check for any existing L1 software that is already setup
	$ResourceDownloader.have_grpcurl()
	$ResourceDownloader.have_enforcer()
	$ResourceDownloader.have_bitcoin()
	$ResourceDownloader.have_bitwindow()
	
	# Do we have a bitcoin conf file?
	$Configuration.have_bitcoin_configuration()
	
	# Check for any existing L2 software that is already setup
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/L2StatusThunder.update_setup_status()


func hide_l1_download_progress() -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelDownloadProgress.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerBitcoinDownload.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerBitWindowDownload.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerEnforcerDownload.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerGRPCCurlDownload.visible = false


func show_l1_download_progress() -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelDownloadProgress.visible = true
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerBitcoinDownload.visible = true
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerBitWindowDownload.visible = true
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerEnforcerDownload.visible = true
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerGRPCCurlDownload.visible = true


func display_resource_status() -> void:
	# L1 resource status
	
	# Update the displayed status of L1 & L2 resources
	
	var l1_downloading : bool = $MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelDownloadProgress.visible

	# Check if L1 configuration is complete
	if configuration_complete \
		&& resource_bitcoin_ready \
		&& resource_bitwindow_ready \
		&& resource_grpcurl_ready \
		&& resource_enforcer_ready:
		hide_l1_download_progress()
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/TextureButtonStartL1.visible = true
		# Tell all L2's that L1 is setup
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/L2StatusThunder.set_l1_ready()
		# Enable L1 remove button
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/TextureButtonRemoveL1.visible = true
		# Hide L1 setup button
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/TextureButtonSetupL1.visible = false
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/MarginContainer/RichTextLabelInstallL1.visible = false
	else:
		# Show L1 setup button if we aren't currently setting up
		if !l1_downloading:
			$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/TextureButtonSetupL1.visible = true
			$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/MarginContainer/RichTextLabelInstallL1.visible = true
			$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/MarginContainer/RichTextLabelUpdateL1.visible = false
			
	var l1_status_text : String = ""
	
	if resource_bitcoin_ready:
		l1_status_text += "\nBitcoin: Ready!"
	elif l1_downloading:
		l1_status_text += "\nBitcoin: Downloading..."
	else:
		l1_status_text += "\nBitcoin: Not Found"
		
	if resource_bitwindow_ready:
		l1_status_text += "\nBitWindow: Ready!"
	elif l1_downloading:
		l1_status_text += "\nBitWindow: Downloading..."
	else:
		l1_status_text += "\nBitWindow: Not Found"
		
	if resource_grpcurl_ready:
		l1_status_text += "\nGRPCURL: Ready!"
	elif l1_downloading:
		l1_status_text += "\nGRPCURL: Downloading..."
	else:
		l1_status_text += "\nGRPCURL: Not Found"
		
	if resource_enforcer_ready:
		l1_status_text += "\nEnforcer: Ready!"
	elif l1_downloading:
		l1_status_text += "\nEnforcer: Downloading..."
	else:
		l1_status_text += "\nEnforcer: Not Found"
		
	if configuration_complete:
		l1_status_text += "\nConfiguration: Complete!"
	elif l1_downloading:
		l1_status_text += "\nConfiguration: Configuring L1..."
	else:
		l1_status_text += "\nConfiguration: Not Configured"
		
	l1_status_text += "\n\n"
	
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1SetupStatus.text = l1_status_text

	# L2 resource status
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/L2StatusThunder.update_setup_status()


func _on_button_overview_toggled(toggled_on: bool) -> void:
	if toggled_on:
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage.visible = true
	else:
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage.visible = false


func _on_button_wallets_toggled(toggled_on: bool) -> void:
	if toggled_on:
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/WalletPage.visible = true
	else:
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/WalletPage.visible = false


func _on_button_tools_toggled(toggled_on: bool) -> void:
	if toggled_on:
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/ToolsPage.visible = true
	else:
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/ToolsPage.visible = false


func _on_button_settings_toggled(toggled_on: bool) -> void:
	if toggled_on:
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/SettingPage.visible = true
	else:
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/SettingPage.visible = false


func setup_l1() -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1SetupStatus.visible = true
	
	# Reset version info, we are downloading the latest now
	$"/root/GlobalSettings".reset_version_info()
	$ResourceDownloader.check_for_updates()
	
	# Show individual L1 resource progress bars
	show_l1_download_progress()
		
	# Download everything required to run L1
	$ResourceDownloader.download_grpcurl()
	$ResourceDownloader.download_enforcer()
	$ResourceDownloader.download_bitcoin()
	$ResourceDownloader.download_bitwindow()
	
	# Configure L1 software
	$Configuration.write_bitcoin_configuration()
	
	display_resource_status()


# Start bitcoind and wait, 
# then start enforcer and wait,
# then start BitWindow
func start_l1() -> void:
	timer_run_status_update.start(RUN_STATUS_UPDATE_DELAY)
	
	var downloads_dir : String = str(OS.get_user_data_dir(), "/downloads/l1")

	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBTC.visible = true
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBTC.text = "Starting Bitcoin Core.."
	
	var btc_bin_path : String = ""
	match OS.get_name():
		"Linux":
			btc_bin_path = str(downloads_dir, "/L1-bitcoin-patched-latest-x86_64-unknown-linux-gnu/bitcoind")
		"Windows":
			btc_bin_path = str(downloads_dir, "/L1-bitcoin-patched-latest-x86_64-w64-msvc/Release/bitcoind.exe")
		"macOS":
			btc_bin_path = str(downloads_dir, "/L1-bitcoin-patched-latest-x86_64-apple-darwin//bitcoind")

	# Start bitcoin
	var ret : int = OS.create_process(btc_bin_path, [])
	if ret == -1:
		printerr("Failed to start bitcoin")
		return
	else:
		pid_bitcoin = ret
		print("started bitcoin with pid: ", ret)
	
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBTC.text = "Starting Bitcoin Core..."

	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusEnforcer.visible = true
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusEnforcer.text = "Waiting for Bitcoin before starting Drivechain Enforcer..."
	
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBitWindow.visible = true
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBitWindow.text = "Waiting for Bitcoin and Enforcer before starting BitWindow..."

	# Wait for bitcoin to start before starting enforcer
	await get_tree().create_timer(5).timeout
	
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusEnforcer.text = "Starting Drivechain Enforcer..."

	var enforcer_bin_path : String = ""
	match OS.get_name():
		"Linux":
			enforcer_bin_path = str(downloads_dir, "/bip300301-enforcer-latest-x86_64-unknown-linux-gnu/bip300301_enforcer-0.1.4-x86_64-unknown-linux-gnu")
		"Windows":
			enforcer_bin_path = str(downloads_dir, "/bip300301-enforcer-latest-x86_64-pc-windows-gnu.exe/bip300301_enforcer-0.1.4-x86_64-pc-windows-gnu.exe")
		"macOS":
			enforcer_bin_path = str(downloads_dir, "/bip300301-enforcer-latest-x86_64-apple-darwin/bip300301_enforcer-0.1.4-x86_64-apple-darwin")

	# Start bip300-301 enforcer
	ret = OS.create_process(enforcer_bin_path, ["--node-rpc-addr=localhost:38332", "--node-rpc-user=user", "--node-rpc-pass=password", "--node-zmq-addr-sequence=tcp://localhost:29000", "--enable-wallet"])
	if ret == -1:
		printerr("Failed to start enforcer")
		return
	else:
		pid_enforcer = ret
		print("started enforcer with pid: ", ret)
	
	# Wait for enforcer to start before starting BitWindow
	await get_tree().create_timer(5).timeout

	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBitWindow.text = "Starting BitWindow..."

	var bitwindow_bin_path : String = ""
	match OS.get_name():
		"Linux":
			bitwindow_bin_path = str(downloads_dir, "/bitwindow/bitwindow")
		"Windows":
			bitwindow_bin_path = str(downloads_dir, "/bitwindow.exe")
		"macOS":
			bitwindow_bin_path = str(downloads_dir, "/bitwindow/bitwindow.app/Contents/MacOS/bitwindow")

	# Start BitWindow
	ret = OS.create_process(bitwindow_bin_path, [])
	if ret == -1:
		printerr("Failed to start bitwindow")
		return
	else:
		pid_bitwindow = ret
		print("started bitwindow with pid: ", ret)
		
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBitWindow.text = "BitWindow Started"

	# Tell L2's that L1 is running
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/L2StatusThunder.set_l1_running()

	# Enable L1 stop button
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/TextureButtonStopL1.visible = true


func _on_rpc_client_btc_new_block_count(height: int) -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBTC.text = str("BTC Running! Blocks: ", height)


func _on_rpc_client_btc_rpc_failed() -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBTC.text = "Failed to contact BTC!"


func _on_rpc_client_cusf_drivechain_responded(height: int) -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusEnforcer.text = str("Drivechain Enforcer Running! Blocks: ", height)


func _on_rpc_client_cusf_drivechain_rpc_failed() -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusEnforcer.text = "Failed to contact Drivechain Enforcer!"


func _on_rpc_client_thunder_cli_failed() -> void:
	# TODO move to l2status scene
	#$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/LabelThunderRunStatus.text = "Failed to contact Thunder!"
	printerr("Failed to connect to thunder")


# Settings page OS info
func update_os_info() -> void:
	var os_version = str("Operating System: ", OS.get_name(),
	 ":", OS.get_distribution_name(), ":", OS.get_version()) 
	
	var data_dir = str("User Data Directory: ", OS.get_user_data_dir())
	
	var os_info = str(os_version, "\n", data_dir, "\n\n")
 
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/SettingPage/VBoxContainer/LabelOSInfo.text = os_info


func _on_button_delete_everything_pressed() -> void:
	var delete_text : String  = str("All L1 & L2 software will stop.\n\n",
		"The following will be moved to trash or deleted:\n",
		$Configuration.get_bitcoin_datadir(), "\n",
		$Configuration.get_enforcer_datadir(), "\n",
		$Configuration.get_bitwindow_datadir(), "\n",
		$Configuration.get_bitwindowd_datadir(), "\n",
		$Configuration.get_thunder_datadir(), "\n",
		str(OS.get_user_data_dir(), "/downloads"), "\n\n",
		"If you have trash disabled everything will be deleted.\n\n",
		"Your settings will be reset.")
	
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/SettingPage/VBoxContainer/DeleteEverythingConfirmationDialog.dialog_text = delete_text 
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/SettingPage/VBoxContainer/DeleteEverythingConfirmationDialog.show()
	
	# Go back to overview page
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPageButtons/VBoxContainer/ButtonOverview.button_pressed = true


func _on_delete_everything_confirmation_dialog_confirmed() -> void:
	remove_l1()
	remove_l2_thunder()
	$"/root/GlobalSettings".reset_user_settings()
	$ResourceDownloader.check_for_updates()
	_on_resource_downloader_update_available_none()


func remove_l1(keep_data_dirs : bool = false) -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/TextureButtonRemoveL1.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/TextureButtonStopL1.visible = false
	
	kill_l1_pid()
	
	if !keep_data_dirs:
		# Trash L1 data dir 
		OS.move_to_trash($Configuration.get_bitcoin_datadir())
		
		# Trash enforcer data dir 
		OS.move_to_trash($Configuration.get_enforcer_datadir())
		
		# Trash bitwindow data dir
		OS.move_to_trash($Configuration.get_bitwindow_datadir())
		
		# Trash bitwindowd data dir
		OS.move_to_trash($Configuration.get_bitwindowd_datadir())
		
	# Trash cusf_launcher l1 downloads
	OS.move_to_trash(str(OS.get_user_data_dir(), "/downloads/l1/"))
	
	# Reset L1 resource status
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/TextureButtonStartL1.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBTC.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusEnforcer.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBitWindow.visible = false

	resource_bitcoin_ready = false
	resource_bitwindow_ready = false
	resource_grpcurl_ready = false
	resource_enforcer_ready = false
	configuration_complete = false
	
	call_deferred("check_resources")
	call_deferred("display_resource_status")


func remove_l2_thunder() -> void:
	kill_l2_pid()
	
	# Trash thunder files
	OS.move_to_trash($Configuration.get_thunder_datadir())
	
	# Trash L2 download files 
	# TODO whenever there is more than 1 sidechain this will need to be 
	# updated to delete only the requested chain
	OS.move_to_trash(str(OS.get_user_data_dir(), "/downloads/l2/"))

	# Reset thunder L2 resource status
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/L2StatusThunder.handle_reset()


func _on_confirmation_dialog_l2_start_l1_confirmed() -> void:
	if resource_bitcoin_ready && resource_grpcurl_ready && resource_enforcer_ready && configuration_complete:
		start_l1()


func _on_confirmation_dialog_l2_setup_l1_confirmed() -> void:
	setup_l1()


# TODO the progress bars are not perfectly aligned... 

func _on_resource_downloader_bitcoin_progress(percent: int) -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerBitcoinDownload/ProgressL1BTC.value = percent


func _on_resource_downloader_bitwindow_progress(percent: int) -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerBitWindowDownload/ProgressL1BitWindow.value = percent


func _on_resource_downloader_enforcer_progress(percent: int) -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerEnforcerDownload/ProgressL1Enforcer.value = percent


func _on_resource_downloader_grpcurl_progress(percent: int) -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerGRPCCurlDownload/ProgressL1GRPCurl.value = percent


func _on_l2_status_thunder_setup_l1_message_requested() -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/ConfirmationDialogL2SetupL1.show()


func _on_l2_status_thunder_start_l1_message_requested() -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/ConfirmationDialogL2StartL1.show()


func _on_l2_status_thunder_started(pid: int) -> void:
	pid_thunder = pid


func _on_confirmation_dialog_remove_l1_confirmed() -> void:
	remove_l1()


func _on_l2_status_thunder_requested_removal() -> void:
	remove_l2_thunder()


func _on_check_box_shutdown_on_exit_toggled(toggled_on: bool) -> void:
	$"/root/GlobalSettings".settings_shutdown_on_exit = toggled_on


func _on_check_box_random_quotes_toggled(toggled_on: bool) -> void:
	$"/root/GlobalSettings".settings_show_random_quotes = toggled_on
	
	if toggled_on:
		$MarginContainer/VBoxContainer/PanelContainerQuotes.visible = true
		show_next_random_quote()
		
		timer_random_quote = Timer.new()
		add_child(timer_random_quote)
		timer_random_quote.connect("timeout", show_next_random_quote)
		
		timer_random_quote.start(RANDOM_QUOTE_UPDATE_DELAY)
		
	else:
		$MarginContainer/VBoxContainer/PanelContainerQuotes.visible = false

		if timer_random_quote:
			timer_random_quote.stop()
			timer_random_quote.queue_free()


func show_next_random_quote() -> void:
	var random_quote : String = random_quotes.pick_random()
	while random_quote == current_random_quote:
		random_quote = random_quotes.pick_random()
		
	current_random_quote = random_quote

	$MarginContainer/VBoxContainer/PanelContainerQuotes/HBoxContainerBottomQuotes/RichTextLabelQuote.text = random_quote


func _on_button_next_quote_pressed() -> void:
	show_next_random_quote()


func _on_button_remove_l1_pressed() -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/ConfirmationDialogRemoveL1.show()


func _on_button_stop_l1_pressed() -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/TextureButtonStopL1.visible = false
	$L1ShutdownStatus.visible = true
	kill_l1_pid()
	
	# TODO wait for pids to actually stop instead of a timer
	await get_tree().create_timer(5.0).timeout
	$L1ShutdownStatus.visible = false
	
	# Hide L1 run status labels and show start button
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/TextureButtonStartL1.visible = true
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBTC.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusEnforcer.visible = false	
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBitWindow.visible = false


func _on_button_update_pressed() -> void:
	$ResourceDownloader.check_for_updates()


func _on_resource_downloader_update_available_l1() -> void:
	show_settings_update_status("  Updates available on overview page!")
	
	# Show L1 update button and label if we have any L1 software installed
	if resource_bitcoin_ready || resource_bitwindow_ready || \
		resource_grpcurl_ready || resource_enforcer_ready:
			$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/TextureButtonUpdateL1.visible = true
			$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/MarginContainer/RichTextLabelUpdateL1.visible = true


func _on_resource_downloader_update_available_l2_thunder() -> void:
	show_settings_update_status("  Updates available on overview page!")


func _on_resource_downloader_update_available_launcher() -> void:
	show_settings_update_status("  Updates available on overview page!")

	# Show launcher update panel
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerLauncherUpdate.visible = true


func _on_resource_downloader_update_available_none() -> void:
	show_settings_update_status("  Up to date!")
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerLauncherUpdate.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/MarginContainer/RichTextLabelUpdateL1.visible = false



func show_settings_update_status(status : String) -> void:
	# Don't show label unless user is on the settings page
	if !$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/SettingPage.visible:
		return
	
	var updated_label = $MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/SettingPage/VBoxContainer/HBoxContainer/LabelUpdateStatus
	
	# If label is still visible from previous tween, let that finish
	if updated_label.visible:
		return
		
	updated_label.text = status
	updated_label.modulate.a = 0
	updated_label.visible = true
	
	var tween = get_tree().create_tween()
	tween.tween_property(updated_label, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(updated_label, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN).set_delay(5.0)
	tween.tween_property(updated_label, "visible", false, 0.0)


func _on_texture_button_update_l1_pressed() -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/ConfirmationDialogUpdateL1.show()


func _on_confirmation_dialog_update_l1_confirmed() -> void:
	# Shutdown everything
	kill_started_pid()
	
	# Remove L1 downloads but keep data directories
	remove_l1(true)
	
	# Re-install L1
	setup_l1()


func _on_texture_button_setup_l1_pressed() -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/TextureButtonSetupL1.visible = false
	setup_l1()


func _on_label_launcher_update_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))
	# Trigger sync of launcher version info if user opens download page
	# TODO write a launcher version number to user_settings file and then
	# use that to check if a newer version of the launcher was started
	$"/root/GlobalSettings".settings_installed_software_info["drivechain-launcher-latest-x86_64-apple-darwin.zip"] = ""
	$"/root/GlobalSettings".settings_installed_software_info["drivechain-launcher-latest-x86_64-unknown-linux-gnu.zip"] = ""
	$"/root/GlobalSettings".settings_installed_software_info["drivechain-launcher-latest-x86_64-w64.zip"] = ""
	$ResourceDownloader.check_for_updates()


func _on_texture_button_start_l1_pressed() -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/HBoxContainerL1Options/TextureButtonStartL1.visible = false
	start_l1()
