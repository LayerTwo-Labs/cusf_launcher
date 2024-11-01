extends Control

const RUN_STATUS_UPDATE_DELAY : int = 10

var resource_bitcoin_ready : bool = false
var resource_grpcurl_ready : bool = false
var resource_enforcer_ready : bool = false
var resource_thunder_ready : bool = false
var configuration_complete : bool = false

var started_pid = []

var timer_run_status_update = null


func _ready() -> void:
	# Create timer to check on running state of L1 and L2 software
	timer_run_status_update = Timer.new()
	add_child(timer_run_status_update)
	timer_run_status_update.connect("timeout", check_running_status)
	
	timer_run_status_update.start(RUN_STATUS_UPDATE_DELAY)
	
	call_deferred("check_resources")
	call_deferred("display_resource_status")
	call_deferred("update_os_info")


func _exit_tree() -> void:
	kill_started_pid()


func kill_started_pid() -> void:
	for pid in started_pid:
		print("Killing pid ", pid)
		OS.kill(pid)


func check_running_status() -> void:
	# TODO re - enable
	return
	
	$RPCClient.rpc_bitcoin_getblockcount()
	$RPCClient.grpc_enforcer_getmainblockcount()
	$RPCClient.cli_thunder_getblockcount()


func _on_downloader_resource_bitcoin_ready() -> void:
	resource_bitcoin_ready = true
	display_resource_status()


func _on_downloader_resource_enforcer_ready() -> void:
	resource_enforcer_ready = true
	display_resource_status()
	

func _on_downloader_resource_grpcurl_ready() -> void:
	resource_grpcurl_ready = true
	display_resource_status()
	

func _on_resource_downloader_resource_thunder_ready() -> void:
	resource_thunder_ready = true
	display_resource_status()

	
func _on_configuration_complete() -> void:
	configuration_complete = true
	display_resource_status()


func check_resources() -> void:
	# Check for any existing L1 or L2 software that is already setup
	$ResourceDownloader.have_grpcurl()
	$ResourceDownloader.have_enforcer()
	$ResourceDownloader.have_bitcoin()
	$ResourceDownloader.have_thunder()
	
	$Configuration.have_bitcoin_configuration()


func display_resource_status() -> void:
	# Update the displayed status of L1 & L2 resources

	# Hide l1 setup buttons if everything L1 is ready
	if resource_bitcoin_ready && resource_grpcurl_ready && resource_enforcer_ready && configuration_complete:
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/L1ProgressBar.visible = false
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/ButtonSetupL1.visible = false
		
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/ButtonStartL1.visible = true
		
	var l1_status_text : String = ""
	
	if resource_bitcoin_ready:
		l1_status_text += "\nBitcoin: Ready!"
	else:
		l1_status_text += "\nBitcoin: Downloading..."
		
	if resource_grpcurl_ready:
		l1_status_text += "\nGRPCURL: Ready!"
	else:
		l1_status_text += "\nGRPCURL: Downloading..."
		
	if resource_enforcer_ready:
		l1_status_text += "\nEnforcer: Ready!"
	else:
		l1_status_text += "\nEnforcer: Downloading..."
		
	if configuration_complete:
		l1_status_text += "\nConfiguration: Complete!"
	else:
		l1_status_text += "\nConfiguration: Not configured!"
	
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1SetupStatus.text = l1_status_text

	# Hide thunder setup buttons and show launch button if ready
	if resource_thunder_ready:
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/ButtonSetupThunder.visible = false
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/ThunderProgressBar.visible = false
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/ButtonStartThunder.visible = true
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/LabelThunderSetupStatus.text = "Ready!"


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


func _on_button_setup_l1_pressed() -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/ButtonSetupL1.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/L1ProgressBar.visible = true
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1SetupStatus.visible = true
	
	# Download everything required to run L1
	$ResourceDownloader.download_grpcurl()
	$ResourceDownloader.download_enforcer()
	$ResourceDownloader.download_bitcoin()
	
	# Configure L1 software
	$Configuration.write_bitcoin_configuration()


func _on_button_start_l1_pressed() -> void:
	var user_dir : String = OS.get_user_data_dir() 
	
	# Start bitcoin
	var ret : int = OS.create_process(str(user_dir, "/L1-bitcoin-patched-latest-x86_64-unknown-linux-gnu/qt/bitcoin-qt"), ["--connect=0", "--signet"])
	if ret == -1:
		printerr("Failed to start bitcoin")
		return
	else:
		started_pid.push_back(ret)
		print("started bitcoin with pid: ", ret)
	
	# Start bip300-301 enforcer
	ret = OS.create_process(str(user_dir, "/bip300301-enforcer-latest-x86_64-unknown-linux-gnu/bip300301_enforcer-0.1.0-x86_64-unknown-linux-gnu"), ["--node-rpc-addr=127.0.01:38332", "--node-rpc-user=user", "--node-rpc-pass=password", "--node-zmq-addr-sequence=tcp://0.0.0.0:29000"])
	if ret == -1:
		printerr("Failed to start enforcer")
		return
	else:
		started_pid.push_back(ret)
		print("started enforcer with pid: ", ret)
		
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/ButtonStartL1.visible = false
	
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBTC.visible = true
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusEnforcer.visible = true
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBTC.text = "Starting Bitcoin Core..."
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusEnforcer.text = "Starting Drivechain Enforcer..."


func _on_button_setup_thunder_pressed() -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/ButtonSetupThunder.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/ThunderProgressBar.visible = true
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/LabelThunderSetupStatus.visible = true
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/LabelThunderSetupStatus.text = "Downloading Thunder..."
	
	$ResourceDownloader.download_thunder()


func _on_button_start_thunder_pressed() -> void:
	var user_dir : String = OS.get_user_data_dir() 

	var ret : int = OS.create_process(str(user_dir, "/thunder-latest-x86_64-unknown-linux-gnu"), [""])
	if ret == -1:
		printerr("Failed to start enforcer")
		return
	
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/ButtonStartThunder.visible = false
	
	started_pid.push_back(ret)
	print("started thunder with pid: ", ret)
	
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/LabelThunderRunStatus.visible = true
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/LabelThunderRunStatus.text = "Starting Thunder..."


func _on_rpc_client_btc_new_block_count(height: int) -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBTC.text = "BTC Running!"


func _on_rpc_client_btc_rpc_failed() -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBTC.text = "Failed to contact BTC!"


func _on_rpc_client_cusf_drivechain_new_block_count(height: int) -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusEnforcer.text = "Drivechain Enforcer Running!"


func _on_rpc_client_cusf_drivechain_rpc_failed() -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusEnforcer.text = "Failed to contact Drivechain Enforcer!"


func _on_rpc_client_thunder_cli_failed() -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/LabelThunderRunStatus.text = "Failed to contact Thunder!"


func _on_rpc_client_thunder_new_block_count(height: int) -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/LabelThunderRunStatus.text = "Thunder running!"


func _on_button_delete_everything_pressed() -> void:
	kill_started_pid()
	
	# Trash L1 and L2 data dirs 
	OS.move_to_trash($Configuration.get_bitcoin_datadir())
	
	# Trash cusf_launcher files
	OS.move_to_trash(OS.get_user_data_dir())
	
	call_deferred("check_resources")
	call_deferred("display_resource_status")


# Settings page OS info
func update_os_info() -> void:
	var os_version = str("Operating System: ", OS.get_name(),
	 ":", OS.get_distribution_name(), ":", OS.get_version()) 
	
	var data_dir = str("User Data Directory: ", OS.get_user_data_dir())
	
	var os_info = str(os_version, "\n", data_dir, "\n\n")
 
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/SettingPage/VBoxContainer/LabelOSInfo.text = os_info
