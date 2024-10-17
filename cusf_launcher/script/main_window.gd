extends Control

func _on_button_download_cusf_pressed() -> void:
	# Download everything required to run CUSF mainchain
	$ResourceDownloader.download_grpcurl()
	$ResourceDownloader.download_enforcer()
	$ResourceDownloader.download_bitcoin()
	
	
func _on_button_start_cusf_pressed() -> void:
	var user_dir : String = OS.get_user_data_dir() 
	var ret_bitcoin : int = OS.execute(str(user_dir, "/L1-bitcoin-patched-header-signature-rebase-latest-x86_64-unknown-linux-gnu/qt/bitcoin-qt"), ["--connect=0"])
	if ret_bitcoin != OK:
		printerr("Failed to start bitcoin")
		
	print("User dir:", user_dir)
		
	var ret_enforcer : int = OS.execute(str(user_dir, "bip300301-enforcer-latest-x86_64-unknown-linux-gnu/bip300301_enforcer-0.1.0-x86_64-unknown-linux-gnu"), [""])
	if ret_enforcer != OK:
		printerr("Failed to start enforcer")
		
