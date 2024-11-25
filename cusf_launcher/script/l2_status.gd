extends Control

var l2_title : String = "LAYERTWOTITLE"
var l2_description : String = "LAYERTWODESC"

var l1_software_ready : bool = false
var l1_software_running: bool = false

signal l2_started(pid : int)
signal l2_start_l1_message_requested()
signal l2_setup_l1_message_requested()


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
	
	# Hide setup buttons if everything is ready
	if l2_ready:
		$PanelContainer/VBoxContainer/DownloadProgress.visible = false
		$PanelContainer/VBoxContainer/ButtonSetupL2.visible = false
		$PanelContainer/VBoxContainer/ButtonStartL2.visible = true
	else:
		$PanelContainer/VBoxContainer/ButtonSetupL2.visible = true
		$PanelContainer/VBoxContainer/ButtonStartL2.visible = false
		
	var l2_downloading : bool = $PanelContainer/VBoxContainer/DownloadProgress.visible

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


func _on_button_start_pressed() -> void:
	# Don't start any L2 if we didn't setup L1
	if !l1_software_ready:
		l2_setup_l1_message_requested.emit()
		return

	# Don't start any L2 if we didn't start L1
	if !l1_software_running:
		l2_start_l1_message_requested.emit()
		return
		
	var downloads_dir : String = str(OS.get_user_data_dir(), "/downloads")

	# TODO work for L2's besides thunder
	var l2_bin_path : String = ""
	match OS.get_name():
		"Linux":
			l2_bin_path = str(downloads_dir, "/thunder-latest-x86_64-unknown-linux-gnu")
		"Windows":
			l2_bin_path = str(downloads_dir, "/thunder-latest-x86_64-pc-windows-gnu.exe")
		"macOS":
			l2_bin_path = str(downloads_dir, "/thunder-latest-x86_64-unknown-linux-gnu")
	

	var ret : int = OS.create_process(l2_bin_path, [])
	if ret == -1:
		printerr("Failed to start ", l2_title)
		return
	
	$PanelContainer/VBoxContainer/ButtonStartL2.visible = false
	print("started ", l2_title, " with pid: ", ret)
	
	# Signal this L2's PID to mainwindow
	l2_started.emit(ret)
	
	$PanelContainer/VBoxContainer/LabelRunStatus.visible = true
	$PanelContainer/VBoxContainer/LabelRunStatus.text = str("Starting ", l2_title, "...")


# TODO _on_resource_downloader_resource_thunder_download_progress
# and _on_resource_downloader_resource_thunder_ready should be general for
# L2s not specific to thunder
func _on_resource_downloader_resource_thunder_download_progress(percent: int) -> void:
	$PanelContainer/VBoxContainer/HBoxContainerDownloadStatus/ProgressL2.value = percent


func _on_resource_downloader_resource_thunder_ready() -> void:
	update_setup_status()
	$PanelContainer/VBoxContainer/HBoxContainerDownloadStatus.visible = false
	

func set_l1_ready() -> void:
	l1_software_ready = true


func set_l1_running() -> void:
	l1_software_running = true