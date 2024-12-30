@tool
extends EditorPlugin

func _enter_tree():
	var extension_path = "res://addons/cusf_launcher_crypto/CusfLauncherCrypto.gdextension"
	
	if not GDExtensionManager.is_extension_loaded(extension_path):
		var status = GDExtensionManager.load_extension(extension_path)
		match status:
			GDExtensionManager.LOAD_STATUS_OK:
				print("Crypto extension loaded successfully")
			GDExtensionManager.LOAD_STATUS_FAILED:
				push_error("Failed to load crypto extension")
			GDExtensionManager.LOAD_STATUS_ALREADY_LOADED:
				print("Crypto extension was already loaded")
			GDExtensionManager.LOAD_STATUS_NOT_LOADED:
				push_error("Crypto extension not found")
			GDExtensionManager.LOAD_STATUS_NEEDS_RESTART:
				push_error("Crypto extension needs restart to load")

func _exit_tree():
	pass
