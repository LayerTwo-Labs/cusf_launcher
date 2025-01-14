extends Control

const RUN_STATUS_UPDATE_DELAY : int = 10

var l2_title : String = "LAYERTWOTITLE"
var l2_description : String = "LAYERTWODESC"

var l1_software_ready : bool = false
var l1_software_running: bool = false

signal l2_started(pid : int)
signal l2_start_l1_message_requested()
signal l2_setup_l1_message_requested()
signal l2_requested_removal()

var l2_pid : int = -1

var timer_run_status_update = null


# TODO if user resets everything while L2 is downloading, the download
# progres bar state will get messed up

func set_l2_info(title : String, description : String) -> void:
	l2_title = title
	l2_description = description
	
	$PanelContainer/VBoxContainer/LabelTitle.text = l2_title
	$PanelContainer/VBoxContainer/LabelDescription.text = l2_description
	
	$PanelContainer/VBoxContainer/ButtonStartL2.text = str("Start ", l2_title)
	$PanelContainer/VBoxContainer/ButtonSetupL2.text = str("Setup ", l2_title)
	$PanelContainer/VBoxContainer/HBoxContainerDownloadStatus/LabelDownloadTitle.text = str(l2_title, ":")


func update_setup_status() -> void:
	var l2_ready : bool = $ResourceDownloader.have_thunder()
	var l2_downloading : bool = $PanelContainer/VBoxContainer/DownloadProgress.visible
	
	if l2_ready:
		$PanelContainer/VBoxContainer/HBoxContainerL2Options/ButtonRemove.disabled = false
	
	# Hide setup buttons if everything is ready
	if l2_ready:
		$PanelContainer/VBoxContainer/DownloadProgress.visible = false
		$PanelContainer/VBoxContainer/ButtonSetupL2.visible = false
		$PanelContainer/VBoxContainer/ButtonStartL2.visible = true
	else:
		if !l2_downloading:
			$PanelContainer/VBoxContainer/ButtonSetupL2.visible = true
		$PanelContainer/VBoxContainer/ButtonStartL2.visible = false

	# Show status text
	var l2_status_text : String = ""
	if l2_ready:
		l2_status_text = "L2 Software: Ready!"
	elif l2_downloading:
		l2_status_text = "L2 Software: Downloading..."
	else:
		l2_status_text = "L2 Software: Not Found"
		
	$PanelContainer/VBoxContainer/LabelSetupStatus.text = l2_status_text 


func _on_button_setup_pressed() -> void:
	$PanelContainer/VBoxContainer/ButtonSetupL2.visible = false
	$PanelContainer/VBoxContainer/HBoxContainerDownloadStatus.visible = true
	$PanelContainer/VBoxContainer/LabelSetupStatus.visible = true
	
	# TODO work for L2's besides thunder
	$ResourceDownloader.download_thunder()


func start_l2() -> void:
	# Don't start any L2 if we didn't setup L1
	if !l1_software_ready:
		l2_setup_l1_message_requested.emit()
		return

	# Don't start any L2 if we didn't start L1
	if !l1_software_running:
		l2_start_l1_message_requested.emit()
		return
		
	var downloads_dir : String = str(OS.get_user_data_dir(), "/downloads/l2")

	# TODO work for L2's besides thunder
	var l2_bin_path : String = ""
	match OS.get_name():
		"Linux":
			l2_bin_path = str(downloads_dir, "/", $ResourceDownloader.BIN_NAME_THUNDER_LIN)
		"Windows":
			l2_bin_path = str(downloads_dir, "/", $ResourceDownloader.BIN_NAME_THUNDER_WIN)
		"macOS":
			l2_bin_path = str(downloads_dir, "/", $ResourceDownloader.BIN_NAME_THUNDER_OSX)
	

	var ret : int = OS.create_process(l2_bin_path, [])
	if ret == -1:
		printerr("Failed to start ", l2_title)
		return
	
	$PanelContainer/VBoxContainer/ButtonStartL2.visible = false
	print("started ", l2_title, " with pid: ", ret)
	
	# Signal this L2's PID to mainwindow
	l2_started.emit(ret)
	
	l2_pid = ret
	
	$PanelContainer/VBoxContainer/LabelRunStatus.visible = true
	$PanelContainer/VBoxContainer/LabelRunStatus.text = str("Starting ", l2_title, "...")
	
	if timer_run_status_update != null:
		timer_run_status_update.queue_free()
	
	# Create timer to check on running state of L1 and L2 software
	timer_run_status_update = Timer.new()
	add_child(timer_run_status_update)
	timer_run_status_update.connect("timeout", check_running_status)
	
	timer_run_status_update.start(RUN_STATUS_UPDATE_DELAY)

	# Show L2 option buttons (Restart, remove for now)
	$PanelContainer/VBoxContainer/HBoxContainerL2Options.visible = true
	
	$PanelContainer/VBoxContainer/HBoxContainerL2Options/ButtonRestart.disabled = false


func _on_button_start_pressed() -> void:
	start_l2()


func check_running_status() -> void:
	$RPCClient.cli_thunder_getblockcount()


# TODO _on_resource_downloader_resource_thunder_download_progress
# and _on_resource_downloader_resource_thunder_ready should be general for
# L2s not specific to thunder
func _on_resource_downloader_resource_thunder_download_progress(percent: int) -> void:
	$PanelContainer/VBoxContainer/HBoxContainerDownloadStatus/ProgressL2.value = percent


func _on_resource_downloader_resource_thunder_ready() -> void:
	update_setup_status()
	$PanelContainer/VBoxContainer/HBoxContainerDownloadStatus.visible = false
	$PanelContainer/VBoxContainer/HBoxContainerL2Options/ButtonRemove.disabled = false


func set_l1_ready() -> void:
	l1_software_ready = true


func set_l1_running() -> void:
	l1_software_running = true


func handle_reset() -> void:
	print("L2 handle reset")
	l1_software_running = false
	l1_software_ready = false
	$PanelContainer/VBoxContainer/LabelRunStatus.visible = false
	update_setup_status()
	
	$PanelContainer/VBoxContainer/HBoxContainerL2Options/ButtonRestart.disabled = true
	$PanelContainer/VBoxContainer/HBoxContainerL2Options/ButtonRemove.disabled = true


# TODO make new block count and rpc failed general instead of thunder specific
func _on_rpc_client_thunder_new_block_count(height: int) -> void:
	$PanelContainer/VBoxContainer/LabelRunStatus.text = str("Blocks: ", height)


func _on_rpc_client_thunder_cli_failed() -> void:
	$PanelContainer/VBoxContainer/LabelRunStatus.text = str("Error: Thunder not responding!")


func _on_button_restart_pressed() -> void:
	restart_l2()


func _on_button_remove_pressed() -> void:
	$PanelContainer/ConfirmationDialogRemoveL2.show()


func _on_confirmation_dialog_remove_l2_confirmed() -> void:
	# TODO emit signal to main window to remove this L2, or make L2 data
	# management part of this scene?
	l2_requested_removal.emit()


func restart_l2() -> void:
	OS.kill(l2_pid)
	await get_tree().create_timer(1.0).timeout
	start_l2()
