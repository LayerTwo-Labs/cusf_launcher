extends Control

const RUN_STATUS_UPDATE_DELAY : int = 10

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

var started_pid = []

var timer_run_status_update = null


func _ready() -> void:
	# Create timer to check on running state of L1 and L2 software
	timer_run_status_update = Timer.new()
	add_child(timer_run_status_update)
	timer_run_status_update.connect("timeout", check_running_status)
	
	timer_run_status_update.start(RUN_STATUS_UPDATE_DELAY)
	
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/L2StatusThunder.set_l2_info("Thunder", "LN Support Chain")
	
	call_deferred("check_resources")
	call_deferred("display_resource_status")
	call_deferred("update_os_info")


func _exit_tree() -> void:
	kill_started_pid()


func kill_started_pid() -> void:
	for pid in started_pid:
		print("Killing pid ", pid)
		OS.kill(pid)
		
	pid_bitcoin = -1
	pid_bitwindow = -1
	pid_enforcer = -1
	pid_thunder = -1


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

	# Hide l1 setup buttons if everything L1 is ready
	if configuration_complete \
		&& resource_bitcoin_ready \
		&& resource_bitwindow_ready \
		&& resource_grpcurl_ready \
		&& resource_enforcer_ready:
		hide_l1_download_progress()
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/ButtonSetupL1.visible = false
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/ButtonStartL1.visible = true
		# Tell all L2's that L1 is setup
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/L2StatusThunder.set_l1_ready()
		
	var l1_status_text : String = ""
	
	var l1_downloading : bool = $MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelDownloadProgress.visible
	
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
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/ButtonSetupL1.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1SetupStatus.visible = true
	
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


func _on_button_setup_l1_pressed() -> void:
	setup_l1()


# Start bitcoind and wait, 
# then start enforcer and wait,
# then start BitWindow
func start_l1() -> void:
	var downloads_dir : String = str(OS.get_user_data_dir(), "/downloads")

	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/ButtonStartL1.visible = false

	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBTC.visible = true
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBTC.text = "Starting Bitcoin Core.."
	
	var btc_bin_path : String = ""
	match OS.get_name():
		"Linux":
			btc_bin_path = str(downloads_dir, "/L1-bitcoin-patched-latest-x86_64-unknown-linux-gnu/bitcoind")
		"Windows":
			btc_bin_path = str(downloads_dir, "/L1-bitcoin-patched-latest-x86_64-w64-msvc/Release/bitcoind.exe")
		"macOS":
			# TODO
			btc_bin_path = str(downloads_dir, "/L1-bitcoin-patched-latest-x86_64-unknown-linux-gnu/bitcoind")

	# Start bitcoin
	var ret : int = OS.create_process(btc_bin_path, [])
	if ret == -1:
		printerr("Failed to start bitcoin")
		return
	else:
		started_pid.push_back(ret)
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
			enforcer_bin_path = str(downloads_dir, "/bip300301-enforcer-latest-x86_64-unknown-linux-gnu/bip300301_enforcer-0.1.0-x86_64-unknown-linux-gnu")
		"Windows":
			enforcer_bin_path = str(downloads_dir, "/bip300301-enforcer-latest-x86_64-pc-windows-gnu.exe/bip300301_enforcer-0.1.0-x86_64-pc-windows-gnu.exe")
		"macOS":
			# TODO
			enforcer_bin_path = str(downloads_dir, "/bip300301-enforcer-latest-x86_64-unknown-linux-gnu/bip300301_enforcer-0.1.0-x86_64-unknown-linux-gnu")

	# Start bip300-301 enforcer
	ret = OS.create_process(enforcer_bin_path, ["--node-rpc-addr=localhost:38332", "--node-rpc-user=user", "--node-rpc-pass=password", "--node-zmq-addr-sequence=tcp://0.0.0.0:29000", "--enable-wallet"])
	if ret == -1:
		printerr("Failed to start enforcer")
		return
	else:
		started_pid.push_back(ret)
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
			# TODO
			bitwindow_bin_path = str(downloads_dir, "/bitwindow/bitwindow")

	# Start BitWindow
	ret = OS.create_process(bitwindow_bin_path, [])
	if ret == -1:
		printerr("Failed to start bitwindow")
		return
	else:
		started_pid.push_back(ret)
		pid_bitwindow = ret
		print("started bitwindow with pid: ", ret)
		
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBitWindow.text = "BitWindow Started"

	# Tell L2's that L1 is running
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/L2StatusThunder.set_l1_running()


func _on_button_start_l1_pressed() -> void:
	start_l1()


func _on_rpc_client_btc_new_block_count(height: int) -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBTC.text = str("BTC Running! Blocks: ", height)


func _on_rpc_client_btc_rpc_failed() -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBTC.text = "Failed to contact BTC!"


func _on_rpc_client_cusf_drivechain_responded() -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusEnforcer.text = "Drivechain Enforcer Running!"


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
	var delete_text = str("The following will be moved to trash or deleted:\n\n",
		$Configuration.get_bitcoin_datadir(), "\n\n",
		$Configuration.get_enforcer_datadir(), "\n\n",
		$Configuration.get_bitwindow_datadir(), "\n\n",
		$Configuration.get_bitwindowd_datadir(), "\n\n",
		$Configuration.get_thunder_datadir(), "\n\n",
		str(OS.get_user_data_dir(), "/downloads"), "\n")
	
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/SettingPage/VBoxContainer/DeleteEverythingConfirmationDialog.dialog_text = delete_text 
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/SettingPage/VBoxContainer/DeleteEverythingConfirmationDialog.show()


func _on_delete_everything_confirmation_dialog_confirmed() -> void:
	kill_started_pid()
	
	# Trash L1 data dir 
	OS.move_to_trash($Configuration.get_bitcoin_datadir())
	
	# Trash enforcer data dir 
	OS.move_to_trash($Configuration.get_enforcer_datadir())
	
	# Trash bitwindow data dir
	OS.move_to_trash($Configuration.get_bitwindow_datadir())
	
	# Trash bitwindowd data dir
	OS.move_to_trash($Configuration.get_bitwindowd_datadir())
	
	# Trash cusf_launcher files
	OS.move_to_trash(str(OS.get_user_data_dir(), "/downloads"))
	
	# Trash thunder files
	OS.move_to_trash($Configuration.get_thunder_datadir())
	
	# Reset L1 resource status
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/ButtonStartL1.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/ButtonSetupL1.visible = true
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBTC.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusEnforcer.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBitWindow.visible = false

	# Reset L2 resource status
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/L2StatusThunder.handle_reset()

	# Go back to overview page
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPageButtons/VBoxContainer/ButtonOverview.button_pressed = true
	
	resource_bitcoin_ready = false
	resource_bitwindow_ready = false
	resource_grpcurl_ready = false
	resource_enforcer_ready = false
	configuration_complete = false
	
	call_deferred("check_resources")
	call_deferred("display_resource_status")


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
	started_pid.push_back(pid)
	pid_thunder = pid
