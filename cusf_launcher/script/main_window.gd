extends Control

var resource_bitcoin_ready : bool = false
var resource_grpcurl_ready : bool = false
var resource_enforcer_ready : bool = false
var resource_thunder_ready : bool = false
var configuration_complete : bool = false

var started_pid = []


func _ready() -> void:
	call_deferred("update_l1_resource_status")


func _exit_tree() -> void:
	kill_started_pid()


func kill_started_pid() -> void:
	for pid in started_pid:
		print("Killing pid ", pid)
		OS.kill(pid)
		

func _on_downloader_resource_bitcoin_ready() -> void:
	resource_bitcoin_ready = true
	update_l1_resource_status()


func _on_downloader_resource_enforcer_ready() -> void:
	resource_enforcer_ready = true
	update_l1_resource_status()
	

func _on_downloader_resource_grpcurl_ready() -> void:
	resource_grpcurl_ready = true
	update_l1_resource_status()
	

func _on_resource_downloader_resource_thunder_ready() -> void:
	resource_thunder_ready = true
	update_thunder_resource_status()

	
func _on_configuration_complete() -> void:
	configuration_complete = true


func update_l1_resource_status() -> void:
	# Hide setup status and buttons if everything L1 is ready
	# Show launch L1 button
	if resource_bitcoin_ready && resource_grpcurl_ready && resource_enforcer_ready:
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1SetupStatus.visible = false
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/L1ProgressBar.visible = false
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/ButtonSetupL1.visible = false
		
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/ButtonStartL1.visible = true
		
		return
	
	# Otherwise show progress of getting L1 ready
	var status_text : String = ""
	
	if resource_bitcoin_ready:
		status_text += "\nBitcoin: Ready!"
	else:
		status_text += "\nBitcoin: Downloading..."
		
	if resource_grpcurl_ready:
		status_text += "\nGRPCURL: Ready!"
	else:
		status_text += "\nGRPCURL: Downloading..."
		
	if resource_enforcer_ready:
		status_text += "\nEnforcer: Ready!"
	else:
		status_text += "\nEnforcer: Downloading..."
	
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL1/VBoxContainer/LabelL1SetupStatus.text = status_text


func update_thunder_resource_status() -> void:
	if resource_thunder_ready:
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/ButtonSetupThunder.visible = false
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/ThunderProgressBar.visible = false
		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/LabelThunderSetupStatus.visible = false

		$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/ButtonStartThunder.visible = true


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
	else:
		started_pid.push_back(ret)
		print("started thunder with pid: ", ret)
		
	$MarginContainer/VBoxContainer/HBoxContainerPageAndPageButtons/PanelContainerPages/OverviewPage/GridContainer/PanelContainerL2/VBoxContainer/ButtonStartThunder.visible = false
		
