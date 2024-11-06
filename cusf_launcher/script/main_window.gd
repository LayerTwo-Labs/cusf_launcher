extends Control

const RUN_STATUS_UPDATE_DELAY : int = 10

var resource_bitcoin_ready : bool = false
var resource_grpcurl_ready : bool = false
var resource_enforcer_ready : bool = false
var resource_thunder_ready : bool = false
var configuration_complete : bool = false

var pid_bitcoin : int = -1
var pid_enforcer : int = -1
var pid_thunder : int = -1

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
	
	var wallet_creator = preload("res://script/wallet_starter.gd").new()
	add_child(wallet_creator)


func _exit_tree() -> void:
	kill_started_pid()


func kill_started_pid() -> void:
	for pid in started_pid:
		print("Killing pid ", pid)
		OS.kill(pid)
		
	pid_bitcoin = -1
	pid_enforcer = -1
	pid_thunder = -1


func check_running_status() -> void:
	if pid_bitcoin != -1:
		$RPCClient.rpc_bitcoin_getblockcount()
		
	if pid_enforcer != -1:
		$RPCClient.grpc_enforcer_gettip()
	
	if pid_thunder != -1:
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
	# L1 resource status
	if resource_bitcoin_ready && resource_grpcurl_ready && resource_enforcer_ready && configuration_complete:
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/L1ProgressBar.visible = false
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/ButtonSetupL1.visible = false
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/ButtonStartL1.visible = true
	
	var l1_status_text : String = ""
	var l1_downloading : bool = $MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/L1ProgressBar.visible
	
	if resource_bitcoin_ready:
		l1_status_text += "\nBitcoin: Ready!"
	elif l1_downloading:
		l1_status_text += "\nBitcoin: Downloading..."
	else:
		l1_status_text += "\nBitcoin: Not Found"
		
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
	if resource_thunder_ready:
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/ThunderProgressBar.visible = false
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/ButtonSetupThunder.visible = false
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/ButtonStartThunder.visible = true

	var thunder_downloading : bool = $MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/ThunderProgressBar.visible

	var l2_thunder_text : String = ""
	if resource_thunder_ready:
		l2_thunder_text = "Thunder: Ready!"
	elif thunder_downloading:
		l2_thunder_text = "Thunder: Downloading..."
	else:
		l2_thunder_text = "Thunder: Not Found"
		
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/LabelThunderSetupStatus.text = l2_thunder_text
	

func _on_button_overview_toggled(toggled_on: bool) -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage.visible = toggled_on


func _on_button_wallets_toggled(toggled_on: bool) -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/WalletPage.visible = toggled_on


func _on_button_tools_toggled(toggled_on: bool) -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/ToolsPage.visible = toggled_on


func _on_button_settings_toggled(toggled_on: bool) -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/SettingPage.visible = toggled_on


func setup_l1() -> void:
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/ButtonSetupL1.visible = false
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/L1ProgressBar.visible = true
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1SetupStatus.visible = true
	$ResourceDownloader.download_grpcurl()
	$ResourceDownloader.download_enforcer()
	$ResourceDownloader.download_bitcoin()
	$Configuration.write_bitcoin_configuration()
	display_resource_status()


func _on_button_start_l1_pressed() -> void:
	start_l1()


func start_l1() -> void:
	var downloads_dir : String = str(OS.get_user_data_dir(), "/downloads")
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/ButtonStartL1.visible = false
	
	# Set UI status labels
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBTC.visible = true
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusBTC.text = "Starting Bitcoin Core..."
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1RunStatusEnforcer.text = "Starting Drivechain Enforcer..."
	
	# Start Bitcoin Core
	var btc_bin_path : String = ""
	match OS.get_name():
		"Linux":
			btc_bin_path = str(downloads_dir, "/L1-bitcoin-patched-latest-x86_64-unknown-linux-gnu/qt/bitcoin-qt")
		"Windows":
			btc_bin_path = str(downloads_dir, "/L1-bitcoin-patched-latest-x86_64-pc-windows-gnu/qt/bitcoin-qt.exe")
		"macOS":
			btc_bin_path = str(downloads_dir, "/L1-bitcoin-patched-latest-x86_64-apple-darwin