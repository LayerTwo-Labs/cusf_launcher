extends Control

var resource_bitcoin_ready : bool = false
var resource_grpcurl_ready : bool = false
var resource_enforcer_ready : bool = false
var configuration_complete : bool = false

var started_pid = []


func _ready() -> void:
	call_deferred("update_resource_status")
	call_deferred("update_configuration_status")


func _exit_tree() -> void:
	kill_started_pid()


func kill_started_pid() -> void:
	for pid in started_pid:
		OS.kill(pid)


func _on_button_download_cusf_pressed() -> void:
	$ProgressDownload.visible = true
	
	# Download everything required to run CUSF mainchain
	$ResourceDownloader.download_grpcurl()
	$ResourceDownloader.download_enforcer()
	$ResourceDownloader.download_bitcoin()


func _on_button_configure_pressed() -> void:
	$Configuration.write_bitcoin_configuration()


func _on_button_start_cusf_pressed() -> void:
	var user_dir : String = OS.get_user_data_dir() 
	var ret : int = OS.create_process(str(user_dir, "/L1-bitcoin-patched-latest-x86_64-unknown-linux-gnu/qt/bitcoin-qt"), ["--connect=0", "--signet"])
	if ret == -1:
		printerr("Failed to start bitcoin")
	else:
		started_pid.push_back(ret)
		
	ret = OS.create_process(str(user_dir, "/bip300301-enforcer-latest-x86_64-unknown-linux-gnu/bip300301_enforcer-0.1.0-x86_64-unknown-linux-gnu"), ["--node-rpc-addr=127.0.01:38332", "--node-rpc-user=user", "--node-rpc-pass=password", "--node-zmq-addr-sequence=tcp://0.0.0.0:29000"])
	if ret == -1:
		printerr("Failed to start enforcer")
	else:
		started_pid.push_back(ret)
		

func _on_downloader_resource_bitcoin_ready() -> void:
	resource_bitcoin_ready = true
	update_resource_status()


func _on_downloader_resource_enforcer_ready() -> void:
	resource_enforcer_ready = true
	update_resource_status()
	

func _on_downloader_resource_grpcurl_ready() -> void:
	resource_grpcurl_ready = true
	update_resource_status()
	
	
func _on_configuration_complete() -> void:
	configuration_complete = true
	update_configuration_status()


func update_resource_status() -> void:
	check_ready_to_launch()
		
	var resource_label : String = "Resources:\n"
	if resource_bitcoin_ready:
		resource_label += "\nBitcoin: Ready"
	else:
		resource_label += "\nBitcoin: Missing"
		
	if resource_grpcurl_ready:
		resource_label += "\nGRPCURL: Ready"
	else:
		resource_label += "\nGRPCURL: Missing"
		
	if resource_enforcer_ready:
		resource_label += "\nEnforcer: Ready"
	else:
		resource_label += "\nEnforcer: Missing"
		
	$LabelResources.text = resource_label


func update_configuration_status() -> void:
	check_ready_to_launch()
		
	var config_label : String = "Configuration:\n"
	if configuration_complete:
		config_label += "\nBitcoin: configured"
	else:
		config_label += "\nBitcoin: Not configured"

	$LabelConfiguration.text = config_label
	
	
func check_ready_to_launch() -> void:
	if resource_bitcoin_ready && resource_enforcer_ready && resource_grpcurl_ready:
		if configuration_complete:
			$ButtonStartCUSF.disabled = false
			
		$ProgressDownload.visible = false
	else:
		$ButtonStartCUSF.disabled = true
